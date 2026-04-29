import os
import ast
import numpy as np
from math import log2

# ---------------------------------------------------------------------------
# 0. Load the Base Reinforced Concrete Implementation
# ---------------------------------------------------------------------------
load("./ReinforcedConcrete.sage")

# ---------------------------------------------------------------------------
# 1. Self-Test: Verify against reference test vectors
# ---------------------------------------------------------------------------
print("Reinforced Concrete — self-test")
print("=" * 60)

RC_BLS = ReinforcedConcreteRC("BLS381")
RC_BN  = ReinforcedConcreteRC("BN254")
RC_ST  = ReinforcedConcreteRC("ST")

for rc, name in [(RC_BLS, "BLS381"), (RC_BN, "BN254"), (RC_ST, "ST")]:
    print(f"\n{rc}\n")

TV_BLS = (
    (RC_BLS.F(0x5d435960920645681669a20225237695d5a9ef111e966343d00f31439bbb7d4d),
     RC_BLS.F(0x1dce58412609d898c60507de74bcb973bd79c66b7288fbdcdaf7bbda3a4b19be),
     RC_BLS.F(0)),
    (RC_BLS.F(0x330b3192e7a61ec5fbae391242405559bf1fd2c42e6904537fdd4a38ca1dbc61),
     RC_BLS.F(0x5577718f75fec6140aa42761ed8285839a2188eceaddc3d4a091d2901ce1020b),
     RC_BLS.F(0x459d1ed8fd17ec44fec36e12a4f38c307decebdfb66229eb751edfa5447bba2c)),
)

TV_BN = (
    (RC_BN.F(0x1539915c8fd4cbff68aaef0157449d7856a90e1187ed84c3a2fb8a67c297d72a),
     RC_BN.F(0x2f24a2f97765ed10016f9dfbf0266c19337fa89a7baac333a9c0f8b3f611092b),
     RC_BN.F(0)),
    (RC_BN.F(0x2a55e0d50ec8e28b9285383aef52bc1ce58b03fbbdd21e58dec72f31183022bc),
     RC_BN.F(0x22c9876e57db0341f3373609c7878f7f6f15392d6574449690d673c9c8ba7cc3),
     RC_BN.F(0x225b6806a75823712b75cfc113e953827544861e8ea61cb51833c5af056b593d)),
)

TV_ST = (
    (RC_ST.F(0x039f2f32148f5e799758658b71e0364f76708425cc79b074dcffe54c56883589),
     RC_ST.F(0x02274cb227717736ca97a75b71584d5c653337a9d813157da9e2641d07fa5aba),
     RC_ST.F(0)),
    (RC_ST.F(0x027a5bfc5a4a1976567e00162c0c7395332c486e4261dd5733e14730b6451575),
     RC_ST.F(0x03bb7a5a063b0e19423707a7bb9ede45800577d745720cd44112aa5f01cf3eb4),
     RC_ST.F(0x00cff17e62ad5123fe25e1ac57856fa60979fc4329311ee52a7b45670a41aa3a)),
)

for rc, tv, label in [(RC_BLS, TV_BLS, "BLS381"), (RC_BN, TV_BN, "BN254"), (RC_ST, TV_ST, "ST")]:
    out = rc.RC(tv[0])
    assert out == tv[1], f"{label} test vector FAILED"
    print(f"[PASS] {label} test vector")

# print("\n--- 3.5-round collision (BLS381) ---")
# cipher = RC_BLS
# cipher_name = cipher.mode_name

# m1  = cipher.F(26273584572734200078773915260813039309556329235007396291399658585772479046857)
# m2  = cipher.F(35589746296652525294320699036203510657619514848294153779122999168862971828682)
# dm1 = cipher.F(21688762786790372808945557159517574119440390595049580606742870021531311807576)

# x0 = (m1,        m2,          cipher.F(0))
# x1 = (m1 + dm1, m2 - 2*dm1, cipher.F(0))

# y0 = cipher.RC_round_last_bricks(x0, 2, 0)
# y1 = cipher.RC_round_last_bricks(x1, 2, 0)

# print(f"  y0 = {cipher.to_hex(y0)}")
# print(f"  y1 = {cipher.to_hex(y1)}")

# assert y0[-1] == y1[-1], "Collision check FAILED"
# print("[PASS] Third coordinate matches — collision verified\n")

# ---------------------------------------------------------------------------
# 2. Utility Functions
# ---------------------------------------------------------------------------
def _parse_file(path):
    """Parse a text file of tuples, one per line."""
    entries = []
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    entries.append(tuple(ast.literal_eval(line)))
                except (ValueError, SyntaxError) as e:
                    print(f"Parse warning in {path}: {e}")
    return entries

def _check_single_active(decomp, index, n):
    """Return n if decomp is single-active at position index, else 0."""
    count = sum(
        1 for i in range(n)
        if (i == index and decomp[i] > 0) or (i != index and decomp[i] == 0)
    )
    return count

# ---------------------------------------------------------------------------
# 3. Difference Generation & Validation
# ---------------------------------------------------------------------------
def generate_outdiff_pair(cipher,index):
    """
    Enumerate valid output differences (d1, d2, d3) for Bars[index] under the collision constraint d1 = -3*d2, d3 = d2, 
    where each component is a single-active difference for sub-S-box S[index].
    Results are written to ./Data/{cipher.mode_name}_outdiff/ (field elements) and ./Data/{cipher.mode_name}_outdiff_clean/ (digit representation).
    """
    outdiff_pair = []
    cur_s = cipher.s[index]
    cur_b = cipher.b[index]
    cipher_name = cipher.mode_name

    def is_single_active(val):
        return (cur_b <= val < cur_s * cur_b) or \
               (cipher.p - cur_s * cur_b < val <= cipher.p - cur_b)

    for sign in [1, -1]:
        for base in range(1, cur_s):
            d2_out = cipher.F(sign * base * cur_b)
            d3_out = d2_out
            d1_out = cipher.F(-3 * d2_out)
            if is_single_active(int(d1_out)):
                entry = (d1_out, d2_out, d3_out)
                if entry not in outdiff_pair:
                    outdiff_pair.append(entry)

    outdiff_pair = list(set(outdiff_pair))
    print(f"S-box {index}: 2^{log2(len(outdiff_pair)):.4f} valid output differences")

    dir_outdiff = f"./Data/{cipher_name}/{cipher_name}_outdiff"
    dir_outdiff_clean = f"./Data/{cipher_name}/{cipher_name}_outdiff_clean"

    os.makedirs(dir_outdiff, exist_ok=True)
    os.makedirs(dir_outdiff_clean, exist_ok=True)

    file_outdiff = f"{dir_outdiff}/{cipher_name}_outdiff_pair_s{index}.txt"
    with open(file_outdiff, 'w') as f:
        for entry in outdiff_pair:
            f.write(str(entry) + "\n")

    file_outdiff_clean = f"{dir_outdiff_clean}/{cipher_name}_outdiff_pair_s{index}_clean.txt"
    with open(file_outdiff_clean, 'w') as f:
        for out_diff in outdiff_pair:
            out_diff_clean = [0, 0, 0]
            for i, diff in enumerate(out_diff):
                diff_val = int(diff)
                if not (cur_b <= diff_val < cur_b * cur_s):
                    diff_val = int(cipher.F(-diff))
                    sign = -1
                else:
                    sign = 1
                decomp = cipher.decomp(diff_val)
                assert all(decomp[j] == 0 for j in range(cipher.n) if j != index)
                assert decomp[index] < cur_s
                out_diff_clean[i] = sign * decomp[index]
            f.write(str(out_diff_clean) + "\n")

    return outdiff_pair

def check_outdiff_pair(cipher):
    """
    Enumerate valid input differences (d1, d2, d3) for Bars[index] under the constraint d2 = 3*d1 - d3, 
    where each component is single-active for sub-S-box S[index].
    Results written to BLS_indiff/ and BLS_indiff_clean/.
    Results are written to ./Data/{cipher.mode_name}_indiff/ (field elements) and ./Data/{cipher.mode_name}_indiff_clean/ (digit representation).
    """
    cipher_name = cipher.mode_name

    dir_outdiff = f"./Data/{cipher_name}/{cipher_name}_outdiff"
    for index in range(1, cipher.n):
        path = f"{dir_outdiff}/{cipher_name}_outdiff_pair_s{index}.txt"
        for d1_out, d2_out, d3_out in _parse_file(path):
            assert d2_out == d3_out
            for diff in [d1_out, d2_out]:
                d_pos  = _check_single_active(cipher.decomp(int(diff)), index, cipher.n)
                d_neg  = _check_single_active(cipher.decomp(int(cipher.F(-diff))), index, cipher.n)
                assert d_pos == cipher.n or d_neg == cipher.n
        print(f"{path} is valid")

def check_outdiff_pair_clean(cipher):

    cipher_name = cipher.mode_name
    dir_outdiff = f"./Data/{cipher_name}/{cipher_name}_outdiff"
    dir_outdiff_clean = f"./Data/{cipher_name}/{cipher_name}_outdiff_clean"
    
    for index in range(1, cipher.n):
        clean_path = f"{dir_outdiff_clean}/{cipher_name}_outdiff_pair_s{index}_clean.txt"
        raw_path   = f"{dir_outdiff}/{cipher_name}_outdiff_pair_s{index}.txt"
        clean_pairs = _parse_file(clean_path)
        raw_pairs   = _parse_file(raw_path)
        for count, (d1c, d2c, d3c) in enumerate(clean_pairs):
            b = cipher.b[index]
            d1 = cipher.F(cipher.F(d1c) * b)
            d2 = cipher.F(cipher.F(d2c) * b)
            d3 = cipher.F(cipher.F(d3c) * b)
            assert d2 == d3
            assert (d1, d2, d3) == raw_pairs[count]
        print(f"{clean_path} is valid")

def generate_indiff_pair(cipher,index):
    cipher_name = cipher.mode_name

    indiff_pair = []
    cur_s = cipher.s[index]
    cur_b = cipher.b[index]

    def is_single_active(val):
        v = int(val)
        return (cur_b <= v < cur_s * cur_b) or \
               (cipher.p - cur_s * cur_b < v <= cipher.p - cur_b)

    for s1 in [1, -1]:
        for base_d1 in range(1, cur_s):
            d1 = cipher.F(s1 * base_d1 * cur_b)
            for s3 in [1, -1]:
                for base_d3 in range(1, cur_s):
                    d3 = cipher.F(s3 * base_d3 * cur_b)
                    d2 = cipher.F(3 * d1 - d3)
                    if is_single_active(d2):
                        indiff_pair.append((d1, d2, d3))

    indiff_pair = list(set(indiff_pair))
    print(f"S-box {index}: 2^{log2(len(indiff_pair)):.4f} valid input differences")

    dir_indiff = f"./Data/{cipher_name}/{cipher_name}_indiff"
    dir_indiff_clean = f"./Data/{cipher_name}/{cipher_name}_indiff_clean"

    os.makedirs(dir_indiff, exist_ok=True)
    os.makedirs(dir_indiff_clean, exist_ok=True)

    file_indiff = f"{dir_indiff}/{cipher_name}_indiff_pair_s{index}.txt"
    with open(file_indiff, 'w') as f:
        for entry in indiff_pair:
            f.write(str(entry) + "\n")

    file_indiff_clean = f"{dir_indiff_clean}/{cipher_name}_indiff_pair_s{index}_clean.txt"
    with open(file_indiff_clean, 'w') as f:
        for in_diff in indiff_pair:
            in_diff_clean = [0, 0, 0]
            for i, diff in enumerate(in_diff):
                diff_val = int(diff)
                if not (cur_b <= diff_val < cur_b * cur_s):
                    diff_val = int(cipher.F(-diff))
                    sign = -1
                else:
                    sign = 1
                decomp = cipher.decomp(diff_val)
                assert all(decomp[j] == 0 for j in range(cipher.n) if j != index)
                assert decomp[index] < cur_s
                in_diff_clean[i] = sign * decomp[index]
            f.write(str(in_diff_clean) + "\n")

    return indiff_pair

def check_input_diff(cipher):
    cipher_name = cipher.mode_name

    dir_indiff = f"./Data/{cipher_name}/{cipher_name}_indiff"
    for index in range(1, cipher.n):
        path = f"{dir_indiff}/{cipher_name}_indiff_pair_s{index}.txt"
        for d1_in, d2_in, d3_in in _parse_file(path):
            assert d2_in == cipher.F(3 * d1_in - d3_in)
            for diff in [d1_in, d2_in, d3_in]:
                d_pos = _check_single_active(cipher.decomp(int(diff)), index, cipher.n)
                d_neg = _check_single_active(cipher.decomp(int(cipher.F(-diff))), index, cipher.n)
                assert d_pos == cipher.n or d_neg == cipher.n
        print(f"{path} is valid")

def check_indiff_pair_clean(cipher):
    cipher_name = cipher.mode_name

    dir_indiff = f"./Data/{cipher_name}/{cipher_name}_indiff"
    dir_indiff_clean = f"./Data/{cipher_name}/{cipher_name}_indiff_clean"
    
    for index in range(1, cipher.n):
        clean_path = f"{dir_indiff_clean}/{cipher_name}_indiff_pair_s{index}_clean.txt"
        raw_path   = f"{dir_indiff}/{cipher_name}_indiff_pair_s{index}.txt"
        clean_pairs = _parse_file(clean_path)
        raw_pairs   = _parse_file(raw_path)
        b = cipher.b[index]
        for count, (d1c, d2c, d3c) in enumerate(clean_pairs):
            d1 = cipher.F(cipher.F(d1c) * b)
            d2 = cipher.F(cipher.F(d2c) * b)
            d3 = cipher.F(cipher.F(d3c) * b)
            assert d2 == cipher.F(3 * d1 - d3)
            assert (d1, d2, d3) == raw_pairs[count]
        print(f"{clean_path} is valid")

# ---------------------------------------------------------------------------
# 4. DDT & Valid Pairs Filtering
# ---------------------------------------------------------------------------
def calculate_DDT(cipher,index):
    """
    Compute the Difference Distribution Table (DDT) for small S-box S[index].
    Rows/columns are indexed by signed differences in [-s+1, s-1] mapped to
    [0, 2s-1] (positive: [0,s-1], negative: [s, 2s-1]).
    Results are written to ./Data/{cipher.mode_name}/{cipher.mode_name}_ddt.
    """
    cipher_name = cipher.mode_name

    s = cipher.s[index]
    sbox_ext = cipher.sbox_table + list(range(cipher.p_prime, s))
    DDT = [[0] * (2 * s) for _ in range(2 * s)]
    count = 0

    for dx in range(s):
        # Forward pairs: x1 = x0 + dx
        for x0 in range(s - dx):
            x1 = x0 + dx
            count += 1
            y0, y1 = sbox_ext[x0], sbox_ext[x1]
            if y0 <= y1:
                DDT[dx][y1 - y0] += 1
            else:
                DDT[dx][s + (y0 - y1)] += 1
        # Backward pairs: x0 = x1 + dx
        for x1 in range(s - dx):
            x0 = x1 + dx
            count += 1
            y0, y1 = sbox_ext[x0], sbox_ext[x1]
            if y0 <= y1:
                DDT[s + dx][y1 - y0] += 1
            else:
                DDT[s + dx][s + (y0 - y1)] += 1

    dir_ddt = f"./Data/{cipher_name}/{cipher_name}_DDT"
    os.makedirs(dir_ddt, exist_ok=True)
    
    file_ddt = f"{dir_ddt}/{cipher_name}_DDT_{index}.txt"
    with open(file_ddt, 'w') as f:
        for row in DDT:
            f.write(str(row) + "\n")
    print(f"S-box {index} DDT built. Valid pairs: {count}")

def gen_valid_diff_pair_clean(cipher,index):
    """
    Filter input and output differences through the DDT to obtain valid (dx, dy) pairs for small-S-box S[index].
    """
    cipher_name = cipher.mode_name
    s = cipher.s[index]

    in_file = f"./Data/{cipher_name}/{cipher_name}_indiff_clean/{cipher_name}_indiff_pair_s{index}_clean.txt"
    out_file = f"./Data/{cipher_name}/{cipher_name}_outdiff_clean/{cipher_name}_outdiff_pair_s{index}_clean.txt"
    ddt_file = f"./Data/{cipher_name}/{cipher_name}_DDT/{cipher_name}_DDT_{index}.txt"

    in_diff_pair  = _parse_file(in_file)
    out_diff_pair = _parse_file(out_file)
    DDT           = _parse_file(ddt_file)

    def to_ddt_idx(v):
        return int(v) if int(v) >= 0 else s - int(v)

    valid_diff = []
    for in_diff in in_diff_pair:
        dx = [to_ddt_idx(v) for v in in_diff]
        for out_diff in out_diff_pair:
            dy = [to_ddt_idx(v) for v in out_diff]
            if DDT[dx[0]][dy[0]] and DDT[dx[1]][dy[1]] and DDT[dx[2]][dy[2]]:
                valid_diff.append(tuple(in_diff) + tuple(out_diff))

    unique_valid   = list(set(valid_diff))
    unique_indiff  = list(set(v[:3] for v in unique_valid))
    unique_outdiff = list(set(v[3:] for v in unique_valid))

    if len(unique_valid) > 0:
        print(f"S-box {index}: 2^{log2(len(unique_valid)):.4f} valid (dx,dy) pairs")
        print(f"S-box {index}: 2^{log2(len(unique_indiff)):.4f} valid (dx,dy) indiff pairs")
        print(f"S-box {index}: 2^{log2(len(unique_outdiff)):.4f} valid (dx,dy) outdiff pairs\n")
    else:
        print(f"S-box {index}: 0 valid pairs")

    dir_valid_diff = f"./Data/{cipher_name}/{cipher_name}_valid_diff_clean"
    dir_valid_indiff = f"./Data/{cipher_name}/{cipher_name}_valid_indiff_clean"
    dir_valid_outdiff = f"./Data/{cipher_name}/{cipher_name}_valid_outdiff_clean"

    os.makedirs(dir_valid_diff, exist_ok=True)
    os.makedirs(dir_valid_indiff, exist_ok=True)
    os.makedirs(dir_valid_outdiff, exist_ok=True)

    with open(f"{dir_valid_diff}/{cipher_name}_valid_diff_s{index}_clean.txt", 'w') as f:
        for entry in unique_valid:
            f.write(str(entry) + "\n")
            
    with open(f"{dir_valid_indiff}/{cipher_name}_valid_indiff_s{index}_clean.txt", 'w') as f:
        for entry in unique_indiff:
            f.write(str(entry) + "\n")
            
    with open(f"{dir_valid_outdiff}/{cipher_name}_valid_outdiff_s{index}_clean.txt", 'w') as f:
        for entry in unique_outdiff:
            f.write(str(entry) + "\n")

def gen_valid_diff_pair(cipher,index):

    cipher_name = cipher.mode_name
    s = cipher.s[index]

    in_file = f"./Data/{cipher_name}/{cipher_name}_valid_indiff_clean/{cipher_name}_valid_indiff_s{index}_clean.txt"
    indiff_pair_clean  = _parse_file(in_file)
    dir_valid_indiff = f"./Data/{cipher_name}/{cipher_name}_valid_indiff"

    os.makedirs(dir_valid_indiff, exist_ok=True)

    valid_indiff = []

    for indiff_clean in indiff_pair_clean:
        d1_in, d2_in, d3_in = indiff_clean

        d1_in = cipher.F(cipher.F(d1_in) * cipher.b[index])
        d2_in = cipher.F(cipher.F(d2_in) * cipher.b[index])
        d3_in = cipher.F(cipher.F(d3_in) * cipher.b[index])

        valid_indiff.append(tuple([d1_in,d2_in,d3_in]))

    with open(f"{dir_valid_indiff}/{cipher_name}_valid_indiff_s{index}.txt", 'w') as f:
        for entry in valid_indiff:
            f.write(str(entry) + "\n")

def gen_valid_pc_pair(cipher,index):
    """
    For each valid (dx, dy) pair of small-S-box S[index], compute the total number
    of plaintext solutions and the average number of solutions per difference pair.
    """

    cipher_name = cipher.mode_name
    s = cipher.s[index]

    ddt_file = f"./Data/{cipher_name}/{cipher_name}_DDT/{cipher_name}_DDT_{index}.txt"
    diff_file = f"./Data/{cipher_name}/{cipher_name}_valid_diff_clean/{cipher_name}_valid_diff_s{index}_clean.txt"

    try:
        DDT = _parse_file(ddt_file)
        diff_pair = _parse_file(diff_file)
    except FileNotFoundError:
        print(f"[{cipher_name}] S-box {index:<2} | No valid diff file found. Skipping.")
        return

    def to_ddt_idx(v):
        return int(v) if int(v) >= 0 else s - int(v)

    total_sol  = 0
    total_pair = 0

    for diff in diff_pair:
        in_diff  = diff[:3]
        out_diff = diff[3:]
        sol  = [DDT[to_ddt_idx(in_diff[i])][to_ddt_idx(out_diff[i])] for i in range(3)]
        pair = [sum(DDT[to_ddt_idx(in_diff[i])]) for i in range(3)]
        total_sol  += sol[0]  * sol[1]  * sol[2]
        total_pair += pair[0] * pair[1] * pair[2]

    n = len(diff_pair)
    if n > 0 and total_sol > 0 and total_pair > 0:
        print(f"S-box {index} | 2^{log2(n):.3f} pairs | "
              f"total sols: 2^{log2(total_sol):.3f} | "
              f"avg sols/pair: 2^{log2(total_sol/n):.3f} | "
              f"avg x/dx: 2^{log2(total_pair/n):.3f}")
    else:
        print(f"S-box {index} | {n} pairs | total sols: {total_sol}")

# ---------------------------------------------------------------------------
# 5. Main Function
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    #for cipher in [RC_BLS, RC_BN, RC_ST]:
    for cipher in [RC_BLS]:
        print(f"\n--- Instance: {cipher.mode_name} ---")
        print("\n--- Generating and Verifying Output Differences ---")
        for i in range(1, cipher.n):
            generate_outdiff_pair(cipher,i)
        check_outdiff_pair(cipher)
        check_outdiff_pair_clean(cipher)

        print("\n--- Generating and Verifying Input Differences ---")
        for i in range(1, cipher.n):
            generate_indiff_pair(cipher,i)
        check_input_diff(cipher)
        check_indiff_pair_clean(cipher)

        print("\n--- Building DDT ---")
        for i in range(1, cipher.n):
            calculate_DDT(cipher,i)
        print("\n---  Filtering Valid Pairs ---")
        for i in range(1, cipher.n):
            gen_valid_diff_pair_clean(cipher,i)
            gen_valid_diff_pair(cipher,i)
        print("\n---  Calculating Average Number of Solutions ---")
        for i in range(1, cipher.n):
            gen_valid_pc_pair(cipher,i)
        print("\n[✓] All generation and validation tasks completed successfully.")
