"""
Usage   : sage run_magma_batch.sage <cipher.mode_name> <rounds> <index>
Example : sage run_magma_batch.sage BLS381 2 18
"""

import os
import re
import ast
import sys
import subprocess

load("./ReinforcedConcrete.sage")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MAGMA_BINARY  = "/usr/bin/magma/magma"
MAGMA_DIR     = "./magma_scripts"
OUTPUT_DIR    = "./magma_results"
RESULT_FILE   = "./collision_result.txt"


# ---------------------------------------------------------------------------
# Step 1 — Load the pre-computed polynomial system
# ---------------------------------------------------------------------------

def load_system(cipher, rounds):
    filename = f"./poly/{cipher.mode_name}_{rounds}r.sobj"
    print(f"[*] Loading polynomial system from {filename} ...")
    return load(filename)


# ---------------------------------------------------------------------------
# Step 2 — Generate one Magma script
# ---------------------------------------------------------------------------

def gen_magma_file(filepath, eqs, p, vars, indiff, dw):
    """
    Write a Magma script that computes the Groebner basis and Variety for the
    instantiated polynomial system.

    Parameters
    ----------
    filepath : str   — full path to write the .magma file
    eqs      : list  — polynomial expressions (as strings) with rhs substituted
    p        : int   — field characteristic
    vars     : list  — variable names, e.g. ['m1', 'm2', 'dm1']
    indiff   : list  — input difference (for the header comment)
    dw       : list  — rhs constraint values (for the header comment)
    """

    with open(filepath, 'w') as f:
        f.write(f"// input difference of Bar : {indiff}\n")
        f.write(f"// rhs constraint          : {dw}\n\n")

        f.write(f"p := {p};\n")
        f.write("F<a> := FiniteField(p);\n")
        f.write(f"R<{','.join(vars)}> := PolynomialRing(F, {len(vars)}, \"grevlex\");\n\n")

        f.write("I := ideal<R |\n")
        for i, eq in enumerate(eqs):
            comma = "," if i < len(eqs) - 1 else ""
            f.write(f"    {eq}{comma}\n")
        f.write(">;\n\n")

        f.write("SetNthreads(8);\n\n")

        # Groebner basis (grevlex)
        f.write('printf "--- GB ---\\n";\n')
        f.write('SetVerbose("Faugere", 0);\n')
        f.write("time GB := GroebnerBasis(I : Al := \"Direct\", Faugere := true);\n\n")

        # FGLM -> lex
        f.write('printf "--- FGLM ---\\n";\n')
        f.write('SetVerbose("FGLM", 0);\n')
        f.write("I_lex := ChangeOrder(I, \"lex\");\n")
        f.write("time GB_lex := GroebnerBasis(I_lex : Al := \"FGLM\");\n\n")

        # Variety
        f.write('printf "--- VARIETY ---\\n";\n')
        f.write("time V := Variety(I_lex);\n")
        f.write("V;\n")
        f.write("#V;\n\n")

        f.write("exit;\n")


# ---------------------------------------------------------------------------
# Step 3 — Run Magma and return raw stdout
# ---------------------------------------------------------------------------

def run_magma(filepath):
    """
    Execute a Magma script and return (stdout, returncode).
    """
    result = subprocess.run(
        [MAGMA_BINARY, filepath],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return result.stdout, result.returncode


# ---------------------------------------------------------------------------
# Step 4 — Parse Variety from Magma output
# ---------------------------------------------------------------------------

def parse_variety(output):
    """
    Extract the list of points from the Variety output block.

    Magma prints the Variety as:
        [ <c1, c2, c3>, <c1, c2, c3>, ... ]
    or
        []    (empty)

    Returns a list of tuples of integers, e.g. [(a, b, c), ...].
    Returns an empty list if no solutions are found.
    """
    # Locate the VARIETY section
    variety_start = output.find("--- VARIETY ---")
    if variety_start == -1:
        return []

    variety_block = output[variety_start:]

    variety_block = variety_block.replace('\\\n', '')

    # Find the line that holds the actual point set (starts with '[')
    array_match = re.search(r'\[\s*(<.*?>.*?)?\s*\]', variety_block, re.DOTALL)
    if not array_match:
        return []

    raw = array_match.group(0)
    if raw.strip() in ("[]", "[ ]"):
        return []

    # Extract each <c1, c2, ...> tuple
    tuples = re.findall(r'<\s*(.*?)\s*>', raw, re.DOTALL)
    solutions = []
    for t in tuples:
        coords_str = re.sub(r'\s+', '', t).split(',')
        try:
            coords = [int(c) for c in coords_str]
            solutions.append(tuple(coords))
        except ValueError:
            continue

    return solutions


# ---------------------------------------------------------------------------
# Step 5 — Verify a candidate solution against the RC permutation
# ---------------------------------------------------------------------------

def verify_solution(cipher, rounds, candidate, indiff_field):
    """
    Check whether (m1, m2, dm1) actually produces a collision after `rounds`
    rounds before the Bars layer.

    Parameters
    ----------
    cipher        : ReinforcedConcreteRC
    rounds        : int   — number of Bricks rounds before Bars
    candidate     : tuple — (m1, m2, dm1) as integers
    indiff_field  : tuple — (dx1, dx2, dx3) as field elements (the Bars input diff)

    Returns
    -------
    bool  — True if the differential trail holds through Bars input
    """
    F = cipher.F
    m1_val, m2_val, dm1_val = [F(c) for c in candidate]
    dm2_val = F(-2) * dm1_val

    x0 = (m1_val,            m2_val,            F(0))
    x1 = (m1_val + dm1_val, m2_val + dm2_val,  F(0))


    y0 = cipher.RC_round_last_bricks(x0, rounds, 0)
    y1 = cipher.RC_round_last_bricks(x1, rounds, 0)

   
    ok = (y0[-1] == y1[-1])

    return ok


# ---------------------------------------------------------------------------
# Main loop: iterate -> generate -> solve -> verify -> stop or continue
# ---------------------------------------------------------------------------

def run(cipher, rounds, target_index, magma_dir=MAGMA_DIR, output_dir=OUTPUT_DIR):
    """
    Iterate over every valid input difference file.  For each differential
    trail:
        - Build and run one Magma script.
        - Parse its Variety output.
        - Verify each candidate solution.
        - On success: save results, delete the Magma file, and return.
        - On failure: delete the Magma file and move to the next trail.
    """
    os.makedirs(magma_dir,  exist_ok=True)
    os.makedirs(output_dir, exist_ok=True)

    eqs     = load_system(cipher, rounds)
    p       = cipher.p
    F       = cipher.F
    M_inv   = cipher.M.inverse()
    vars    = ['m1', 'm2', 'dm1']

    total_tried   = 0
    total_skipped = 0

    index = target_index
    
    node_result_file = f"./collision_result/collision_result_{cipher.mode_name}_s{index}.txt"

    #for index in range(1, cipher.n):
    diff_file = (
        f"./Data/{cipher.mode_name}/"
        f"{cipher.mode_name}_valid_indiff/"
        f"{cipher.mode_name}_valid_indiff_s{index}.txt"
    )
    if not os.path.exists(diff_file):
        print(f"[~] S-box {index}: diff file not found, skipping.")
        total_skipped += 1
        return False

    with open(diff_file, 'r') as fh:
        lines = [l.strip() for l in fh if l.strip()]

    for line_no, line in enumerate(lines, 1):
        # Parse input difference (field-element tuple)
        if not (line.startswith("(") and line.endswith(")")):
            continue

        coords_str = line[1:-1].split(",")
        try:
            indiff_ints = [int(s.strip()) for s in coords_str]
        except ValueError:
            print(f"[!] S-box {index} line {line_no}: cannot parse '{line}', skipping.")
            continue

        indiff_field = tuple(F(v) for v in indiff_ints)

        # Compute rhs  (dw = M^{-1} * indiff;  dw[0] must be 0)
        vec    = vector(F, indiff_field)
        dw_vec = M_inv * vec

        if dw_vec[0] != F(0):

            continue

        dw = list(dw_vec)

        # ----------------------------------------------------------
        # Build instantiated equations:  f_j(m1,m2,dm1) - dw[j] = 0
        # ----------------------------------------------------------
        inst_eqs = [f"({eqs[j]}) - ({dw[j]})" for j in range(len(eqs))]

        indiff_tag = "_".join(str(v) for v in indiff_ints)
        script_name = f"RC_{cipher.mode_name}_{rounds}r_s{index}_{line_no}.magma"
        script_path = os.path.join(magma_dir, script_name)

        # ----------------------------------------------------------
        # Generate Magma script
        # ----------------------------------------------------------
        gen_magma_file(script_path, inst_eqs, p, vars, indiff_ints, dw)
        total_tried += 1

        print(f"[>] S-box {index:2d}, trail {line_no:4d} — running {script_name} ...",
              end=' ', flush=True)

        # ----------------------------------------------------------
        # Run Magma
        # ----------------------------------------------------------
        stdout, rc = run_magma(script_path)

        if rc != 0:
            print(f"MAGMA ERROR (code {rc}). Deleting script.")
            os.remove(script_path)
            continue

        # ----------------------------------------------------------
        # Parse Variety
        # ----------------------------------------------------------
        solutions = parse_variety(stdout)

        if not solutions:
            print("no solutions. Deleting script.")
            os.remove(script_path)
            continue

        print(f"{len(solutions)} candidate(s). Verifying ...")

        # ----------------------------------------------------------
        # Verify each candidate
        # ----------------------------------------------------------
        collision_found = False
        for cand in solutions:
            if len(cand) != 3:
                continue
            ok = verify_solution(cipher, rounds, cand, indiff_field)
            if ok:
                collision_found = True
                m1_v, m2_v, dm1_v = [F(c) for c in cand]
                dm2_v = F(-2) * dm1_v

                print(f"\n{'='*60}")
                print(f"[✓] COLLISION FOUND!")
                print(f"    S-box index : {index}")
                print(f"    Trail no.   : {line_no}")
                print(f"    m1          = {hex(int(m1_v))}")
                print(f"    m2          = {hex(int(m2_v))}")
                print(f"    m1'         = {hex(int(m1_v + dm1_v))}")
                print(f"    m2'         = {hex(int(m2_v + dm2_v))}")
                print(f"    indiff      = {[hex(int(v)) for v in indiff_field]}")
                print(f"{'='*60}\n")

                # Save result
                with open(node_result_file, 'w') as rf:
                    rf.write(f"S-box index : {index}\n")
                    rf.write(f"Trail no.   : {line_no}\n")
                    rf.write(f"m1          = {hex(int(m1_v))}\n")
                    rf.write(f"m2          = {hex(int(m2_v))}\n")
                    rf.write(f"m1_prime    = {hex(int(m1_v + dm1_v))}\n")
                    rf.write(f"m2_prime    = {hex(int(m2_v + dm2_v))}\n")
                    rf.write(f"indiff      = {[hex(int(v)) for v in indiff_field]}\n")
                    rf.write(f"Magma script: {script_name}\n")

                # Save Magma output log
                log_path = os.path.join(output_dir, script_name + ".log")
                with open(log_path, 'w') as lf:
                    lf.write(stdout)

                # Remove the script (keep only the log)
                os.remove(script_path)
                break   # inner loop over candidates

        if collision_found:
            print(f"[*] Tried {total_tried} trail(s) in total.")
            print(f"[*] Result written to {RESULT_FILE}")
            return True

        # No valid candidate -> clean up and try next
        print(f"    All {len(solutions)} candidate(s) failed verification. Deleting script.")
        os.remove(script_path)

    # Exhausted all trails
    print(f"\n[!] No collision found after {total_tried} trail(s) "
          f"({total_skipped} S-box file(s) missing).")
    return False


# ---------------------------------------------------------------------------
#  Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":

    if len(sys.argv) != 4:
        print("Usage  : sage run_magma.sage <cipher.mode_name> <rounds> <index>")
        print("Example: sage run_magma.sage BLS381 2 18")
        sys.exit(1)

    cipher_name = sys.argv[1]
    rounds      = int(sys.argv[2])
    target_index= int(sys.argv[3])

    if cipher_name == "BLS381":
        cipher = ReinforcedConcreteRC("BLS381")
    elif cipher_name == "BN254":
        cipher = ReinforcedConcreteRC("BN254")
    elif cipher_name == "ST":
        cipher = ReinforcedConcreteRC("ST")
    else:
        print(f"[!] Unknown cipher: {cipher_name}")
        sys.exit(1)

    print(f"\n--- Find Collisions for : {cipher.mode_name} | {rounds} rounds | S-box {target_index} ---")

    success = run(cipher, rounds, target_index)

    if not success:
        print(f"\n[!] {cipher.mode_name} | {rounds} rounds | Sbox {target_index} \nSearch exhausted without finding a collision.")
