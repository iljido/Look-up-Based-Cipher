load("ReinforcedConcrete.sage")

def gen_rc_eqs(cipher, rounds_before_bars=2):

    print(f"[*] Initializing Cipher: {cipher.mode_name}")

    print(f"[*] Generating equation system for {rounds_before_bars} rounds...")

    P, diffs = cipher.generate_rc_system(r0=rounds_before_bars)
    
    f1 = diffs[f"R{rounds_before_bars}_AfterConcrete"][0]
    f2 = diffs[f"R{rounds_before_bars}_AfterBricks"][1]
    f3 = diffs[f"R{rounds_before_bars}_AfterBricks"][2]

    print("\n[+] System Generation Complete!")
    print(f"    Degree of f1: {f1.degree()}")
    print(f"    Degree of f2: {f2.degree()}")
    print(f"    Degree of f3: {f3.degree()}")

    print("\n[*] Verification...")

    v_m1  = cipher.F.random_element()
    v_m2  = cipher.F.random_element()
    v_dm1 = cipher.F.random_element()

    print(f"[*] Generated Random Inputs:")
    print(f"    m1  = {v_m1}")
    print(f"    m2  = {v_m2}")
    print(f"    dm1 = {v_dm1}")

    print("\n[*] Method A: Evaluating Polynomials...")
    f1_eval = f1(m1=v_m1, m2=v_m2, dm1=v_dm1)
    f2_eval = f2(m1=v_m1, m2=v_m2, dm1=v_dm1)
    f3_eval = f3(m1=v_m1, m2=v_m2, dm1=v_dm1)

    print(f"\n[*] Method B: Encrypt for {rounds_before_bars} rounds...")
    x0_tuple = (v_m1,       v_m2,           cipher.F(0))
    x1_tuple = (v_m1+v_dm1, v_m2-2*v_dm1,   cipher.F(0))

    f1_real, f2_real, f3_real = cipher.RC_round_diff(x0_tuple, x1_tuple, rounds_before_bars)

    assert (f1_eval, f2_eval, f3_eval) == (f1_real, f2_real, f3_real)
    print("\n[SUCCESS] Verification Complete!")

    filename = f"./poly/{cipher.mode_name}_{rounds_before_bars}r.txt"
    print(f"\n[*] Exporting polynomials to {filename} ...")
    
    with open(filename, "w") as f_out:
        f_out.write(f"f1 = {f1}\n\n")
        f_out.write(f"f2 = {f2}\n\n")
        f_out.write(f"f3 = {f3}\n")
        
    print("[+] Export complete!")

    eqs = [f1, f2, f3]
    filename = f"./poly/{cipher.mode_name}_{rounds_before_bars}r.sobj"
    save(eqs, filename)  
    print(f"[+] Exported natively to {filename}")


if __name__ == "__main__":

    RC_BLS = ReinforcedConcreteRC("BLS381")
    RC_BN  = ReinforcedConcreteRC("BN254")
    RC_ST  = ReinforcedConcreteRC("ST")

    for cipher, rounds_before_bars in [ (RC_BLS,2), (RC_BN,2), (RC_ST,3)]:
        print(f"\n--- Generate equations for {cipher.mode_name} \t: {rounds_before_bars} rounds ---\n")
        gen_rc_eqs(cipher, rounds_before_bars)
