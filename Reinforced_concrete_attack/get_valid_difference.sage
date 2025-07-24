load("rc_permutation.sage")

RC_model = ReinforcedConcreteRC("BN254")
F = RC_model.F

sn=RC_model.s[-1]
sv=RC_model.p_prime
offset = sn - 1
DDT=[[0 for _ in range(2*sn-1)] for _ in range(2*sn-1)]
def generate_DDT():
    for dx in range(sn):
        for x in range(sn):
            delta_x = dx - x
            # print("dx:", dx, "x:", x, "delta_x:", delta_x)
            # print("delta_x:", delta_x)
            # 计算 dy
            dy = dx if dx >= sv else RC_model.sbox_table[dx]
            y = x if x >= sv else RC_model.sbox_table[x]

            delta_y = dy - y
            # print("dy:", dy, "y:", y, "delta_y:", delta_y)
            # print("delta_y:", delta_y)

            # 映射负数索引到 [0, 1384]
            ix = delta_x + offset
            iy = delta_y + offset

            if 0 <= ix < 2 * sn - 1 and 0 <= iy < 2 * sn - 1:
                DDT[ix][iy] += 1
    
def get_valid_difference():
    ## get valid delta x3,y3
    x3y3_valid_pairs = 0
    x3_valid_delta_x = set()
    y3_valid_delta_y = set()
    x3y3_valid_difference_pair={}
    for i in range(2 * sn - 1):
        for j in range(2 * sn - 1):
            # if abs(i-(p-1))<int(floor(2*p/3)):
            if abs(j-(sn-1))<int(floor(sn/3)):
                    # print(abs(j-(p-1)))
                    # print(int(floor(sn/3)))
                if DDT[i][j] > 0:
                    if i-(sn-1)!=0 and j-(sn-1)!=0:
                        x3y3_valid_pairs += 1
                        if j-(sn-1) in x3y3_valid_difference_pair:
                            # x3y3_valid_difference_pair[i-(sn-1)].add(j-(sn-1))
                            x3y3_valid_difference_pair[j-(sn-1)].add(i-(sn-1))
                        else:
                            # x3y3_valid_difference_pair[i-(sn-1)]=set()
                            # x3y3_valid_difference_pair[i-(sn-1)].add(j-(sn-1))
                            x3y3_valid_difference_pair[j-(sn-1)]=set()
                            x3y3_valid_difference_pair[j-(sn-1)].add(i-(sn-1))
                        # x3y3_valid_difference_pair[(i-(p-1),j-(p-1))]=DDT[i][j]
                        x3_valid_delta_x.add(i-(sn-1))
                        y3_valid_delta_y.add(j-(sn-1))
    
    ## get the valid difference pairs delta x1,y1
    ## delta y1 = -3 * delta y3 = -3 * delta y2

    x1y1_valid_pairs = 0
    x1_valid_delta_x = set()
    y1_valid_delta_y = set()
    x1y1_valid_difference_pair={}
    for i in list(y3_valid_delta_y):
        for j in range(2 * sn - 1):
            if abs(j-(sn-1))<floor(2*sn/3):
                if DDT[j][-3*i+(sn-1)]!=0:
                    x1y1_valid_pairs+=1
                    x1_valid_delta_x.add(j-(sn-1))
                    y1_valid_delta_y.add(-3*i)
                    # x1y1_valid_difference_pair[(j-(p-1),-3*i)]=DDT[j][-3*i+(p-1)]
                    if -3*i in x1y1_valid_difference_pair:
                        # x1y1_valid_difference_pair[j-(sn-1)].add(-3*i)
                        x1y1_valid_difference_pair[-3*i].add(j-(sn-1))
                    else:
                        # x1y1_valid_difference_pair[j-(sn-1)]=set()
                        # x1y1_valid_difference_pair[j-(sn-1)].add(-3*i)
                        x1y1_valid_difference_pair[-3*i]=set()
                        x1y1_valid_difference_pair[-3*i].add(j-(sn-1))
    
    valid_difference_pairs=[]
    for y3,x3 in x3y3_valid_difference_pair.items():
        y1=-3*y3
        y2=y3
        for dx3 in list(x3):
            for dx1 in list(x1y1_valid_difference_pair[y1]):
                dx2=3*dx1-dx3
                # print("dx1,dx3:",dx1,dx3)
                # print("dx2:",dx2)
                if abs(dx2)<sn and DDT[dx2+offset][y2+offset] > 0:
                    valid_difference_pairs.append([(dx1,y1),(dx2,y2),(dx3,y3)])
    
    print("Valid difference pairs: 2^",float(log(len(valid_difference_pairs), 2)))

    file_valid_xyw="valid_w.txt"
    w_list=set()
    A = Matrix([[1, 1], [2, 1], [1, 2]])
    with open(file_valid_xyw, "w") as f:
        for d in valid_difference_pairs:
        # print(f"delta_x1={d[0][0]}, delta_y1={d[0][1]}, delta_x2={d[1][0]}, delta_y2={d[1][1]}, delta_x3={d[2][0]}, delta_y3={d[2][1]}")
            x1,x2,x3=d[0][0],d[1][0],d[2][0]
            B = vector([x1, x2, x3])
            solutions = A.solve_right(B)
            w = tuple(solutions)
            if w not in w_list:
                w_list.add(w)
                f.write(f"{w[0]} {w[1]}\n")

generate_DDT()
get_valid_difference()