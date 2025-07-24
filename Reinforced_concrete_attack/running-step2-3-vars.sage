# p=0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
# p=21888242871839275222246405745257275088548364400416034343698204186575808495617
p = 0x30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001
F = GF(p)
Ring = PolynomialRing(F, "x,y,z")
Ring.inject_variables()
alpha1 = F(1)
alpha2 = F(3)
beta1 = F(2)
beta2 = F(4)
M = Matrix(F, 3, 3, [[2, 1, 1], [1, 2, 1], [1, 1, 2]])
round_constants = [
    [
        F(0x215510B29C6B20E05516126A5B33016A16A92610D560C7ECBCA2345DAB7AE0BF),
        F(0x07E9C9F7343A930646FBFF4CE7BEA19ED1938A6DB7CAEDAA5E38F47AAE527624),
        F(0x015B1F41EC3A6E2B66530DCFC410F859243E6777CF44BB88D7DB57E9018DE353),
    ],
    [
        F(0x22C704FEDE5CDA19337169658A93F22FAAD854E493A9658773D803688859AA82),
        F(0x28C05784ECFB24064874E90F67193017FB6091CCD4ED819F1A25A9517F3C040E),
        F(0x12BD9CAE9374F5AC3CEAA747B8C5738F5E3FAA3488B1E7F1B23DC9F52CAB9797),
    ],
    [
        F(0x06FDE3A5B074A23F3A643B30D5A2051E1390EA1432E9736615D416D83A7FD85F),
        F(0x103278C9BC3B3383E99424C36DAE2CCC9FCBF7181D53276BEA4A47D79EAAE473),
        F(0x12B44D1037C7F6BEC1507C0EB6D55FBF9A57F84904914EA7D3EB33EAC23D4B1A),
    ],
    [
        F(0x10D954340CDCAE3D7C81A1AD43E13CFC52B24EBA26BBEFBD4A820FEDE4537988),
        F(0x1D8FB5D1EC360409E602CC2E78CD0658B667EA4C36C25E9DD3CCA25196CBFA53),
        F(0x11709DF530356F7807DA53BAC1C8D389EF7E0A2EB94095ACDD276043D07EF44F),
    ],
    [
        F(0x0236C4EAB23CFBE95493E6A0101724602B08CB99C4BD98D7CA37C1ECBBEE1148),
        F(0x1E0474C2F00538F6A05D05DCFC43E73F88010D373B409C254631188DD0428551),
        F(0x284536744255C64D18C36F259925ED6D3C5BB282EB574101F57E7960E37555C6),
    ],
    [
        F(0x0C921FA35EC9B5D7B6D47EB972F9AE13B0877F063B27C35D3AF8EE36081CB19E),
        F(0x23419E1990860E770065CD4E96A7E76C68B8198906DCD0CDB5C546B83DB91EAA),
        F(0x1B58C7C715B261CDA1FBBAD214D50C6ED6EA812C7D6DB78ED023A77F825EDC63),
    ],
    [
        F(0x2258C2DF6C6B393D2471F2BED2E63D4B74772375424EA75E2DAA36F8A2226ECD),
        F(0x015BB2517D8872CC185AA6CA3C0D834DAD5FBE288FA1C38662D5DBB95FC96988),
        F(0x2D8CF5AA0B7C11FDB431D45897214B9332928DABD2AB1007874813D8AC431018),
    ],
    [
        F(0x101DCC35A6D62B54733A9854021027AC199B0FE6B73F61555203C956BB45C406),
        F(0x0407EC9A0A155CFAB1C30E6C2C2C05B0C7353167A196883A71C30FCD8F07FCF5),
        F(0x284E315339D5E4D0A248A9EF71F9AAF6560096869B4859BDCCC9B57A2BFBA8A0),
    ],
]


def L(state, rc):
    # print(rc)
    v_state = vector(state)
    return M * v_state + vector(rc)


def S(state):
    new_state = []
    new_state.append(state[0] ^ 5)
    new_state.append(state[1] * (state[0] ^ 2 + alpha1 * state[0] + beta1))
    new_state.append(state[2] * (state[1] ^ 2 + alpha2 * state[1] + beta2))
    return new_state


def f(state):
    state = L(state)
    new_state = S(state)
    return new_state


# state=[m1,m2,0]
# p_state=[m1+dm1,m2-2*dm1,0]
# for i in range(3):
#     state=f(state)
# p_state=f(p_state)
# print(state)

## m1=x,x2=y,dm1=z
import subprocess
import re


def construct_2round_system():
    state = [x, y, 0]
    p_state = [x + z, y - 2 * z, 0]
    system = []
    round = 0
    for r in range(round):
        state = f(state)
        p_state = f(p_state)

    state = L(state, round_constants[0])
    p_state = L(p_state, round_constants[0])

    state = S(state)
    p_state = S(p_state)

    state = L(state, round_constants[1])
    p_state = L(p_state, round_constants[1])
    system.append(p_state[0] - state[0])
    state = S(state)
    p_state = S(p_state)
    # constants = [0, -w[0], -w[1]]
    for i in range(1, 3):
        # print(state[i])
        # print(p_state[i])
        system.append(p_state[i] - state[i])
    # solve_with_magma(system)
    return system

    # f.write("#V;")


# 运行Magama并获取输出
def run_magma(file_name):
    # 运行Magma的命令
    magma_command = ["/mnt/e/Magma/magma.exe", file_name]
    result = subprocess.run(magma_command, capture_output=True, text=True)

    # 获取Magma的输出
    if result.returncode == 0:
        output = result.stdout

        # print("Magma Output:\n", output)
        return output
    else:
        print("Magma run failed!")
        return None


# 提取解
# def extract_solutions(magma_output):
#     # print("magma_output:", magma_output)
#     solutions = []


#     # 假设解在输出中类似于这样： [ <...>, <...>, <...> ]
#     lines = magma_output.splitlines()
#     for line in lines:
#         if line.startswith("["):
#             # 提取数字并转换为整数
#             if "<" in line:
#                 solution_str = line.strip()[2:-1]  # 去掉方括号
#                 print(solution_str)
#                 solution_values = solution_str.split(",")
#                 solution = [RC_model.F(val.strip()) for val in solution_values]
#                 solutions.append(solution)
#     print("solutions:", solutions)
#     return solutions
def extract_solutions(magma_output):
    # 使用正则表达式匹配所有尖括号内的内容
    cleaned_output = magma_output.replace("\\", "").replace("\n", "")
    matches = re.findall(r"<([^>]+)>", cleaned_output)
    # print(matches)

    # 处理每个匹配项
    solutions = []
    for match in matches[1:]:
        # 分割逗号分隔的数字字符串，去除空格并转换为整数
        array = [int(num.strip()) for num in match.split(",")]
        solutions.append(array)

    return solutions


# 定义构建系统和求解Magma文件
def solve_with_magma(system, w):
    magma_path = "/mnt/e/Magma/magma.exe"
    # file_name = f"./Magma-file/rc-2round-3-vars-BN254-w_{w[0]}_{w[1]}.magma"
    file_name = f"./Magma-file/rc-2round-3-vars-BN254.magma"
    result_file_name = f"./Magma-result-file/rc-2round-3-vars-BN254.txt"
    with open(file_name, "w") as f:
        f.write("p := {};\n".format(p))
        f.write("F := GF(p);\n")
        f.write('R<x,y,z> := PolynomialRing(F, 3, "grevlex");\n')
        f.write("I := ideal< R | ")

        for i, eq in enumerate(system):
            if i > 0:
                f.write(",\n")
            f.write(f"{eq}")
        f.write(">;\n")

        # 求解并获取结果
        f.write("V := Variety(I);\n")
        f.write("V;\n")
        f.write("exit;\n")

    # 运行Magama并提取解
    magma_output = run_magma(file_name)

    if magma_output:
        solutions = extract_solutions(magma_output)
        solutions_context = f"w = {w[0]}, {w[1]}\n"
        solutions_context += "Solutions:\n"
        solutions_context += "\n".join(
            [f"[{', '.join(map(str, s))}]" for s in solutions]
        )
        solutions_context += "\n"
        with open(result_file_name, "a") as result_file:
            result_file.write(solutions_context)
        for s in solutions:
            if verify_solution(s, w):
                print(f"Solution {s} passed validation!")
                return True

        # if solutions!=[]:
        #     return solutions
        # for solution in solutions:
        #     print(f"Solution: {solution}")
        #     if verify_solution(solution):
        #         print("Solution passed validation!")
        #     else:
        #         print("Solution failed validation!")


def verify_solution(solution, w):
    RC_model = ReinforcedConcreteRC("BN254")
    F = RC_model.F
    # solution=[7486373480841350577529127174885533180022463083137556757312412066948720102143, 17407358417091063196823918043454547178147574203821661285672455568300544350942,
    # 7066912698521033783925002256309680767907428262060105678191728631150100128426]
    m1 = F(solution[0])
    m2 = F(solution[1])
    delta_m1 = F(solution[2])
    p_m1 = delta_m1 + m1
    delta_m2 = -2 * delta_m1
    p_m2 = delta_m2 + m2
    input_state1 = (m1, m2, F(0))
    input_state2 = (p_m1, p_m2, F(0))

    input_state1 = RC_model.concrete(1, input_state1)
    input_state2 = RC_model.concrete(1, input_state2)
    # print("input_state1:", input_state1)
    # print("input_state2:", input_state2)
    # print("delta_input:",[input_state2[i]-input_state1[i] for i in range(3)])

    input_state1 = RC_model.bricks(input_state1)
    input_state2 = RC_model.bricks(input_state2)
    # print("input_state1 after bricks:", input_state1)
    # print("input_state2 after bricks:", input_state2)
    # print("delta_input after bricks:", [input_state2[i]-input_state1[i] for i in range(3)])

    input_state1 = RC_model.concrete(2, input_state1)
    input_state2 = RC_model.concrete(2, input_state2)
    # print("input_state1 after concrete 2:", input_state1)
    # print("input_state2 after concrete 2:", input_state2)
    # print("delta_input after concrete 2:", [input_state2[i]-input_state1[i] for i in range(3)])

    input_state1 = RC_model.bricks(input_state1)
    input_state2 = RC_model.bricks(input_state2)
    # print("input_state1 after bricks 2:", input_state1)
    # print("input_state2 after bricks 2:", input_state2)
    # print("delta_input after bricks 2:", [input_state2[i]-input_state1[i] for i in range(3)])

    input_state1 = RC_model.concrete(3, input_state1)
    input_state2 = RC_model.concrete(3, input_state2)
    # print("input_state1 after concrete 3:", input_state1)
    # print("input_state2 after concrete 3:", input_state2)
    # print("delta_input after concrete 3:", [input_state2[i]-input_state1[i] for i in range(3)])
    delta_x = [input_state2[i] - input_state1[i] for i in range(3)]
    delta_file_name = f"./delta-result-file/rc-2round-3-vars-BN254.txt"
    input_state1 = RC_model.bars(input_state1)
    input_state2 = RC_model.bars(input_state2)
    # print("input_state1 after bars:", input_state1)
    # print("input_state2 after bars:", input_state2)
    # print("delta_input after bars:", [input_state2[i]-input_state1[i] for i in range(3)])
    delta_y = [input_state2[i] - input_state1[i] for i in range(3)]
    delta_context = f"w = {w[0]}, {w[1]}\n"
    delta_context += f"delta_x: {delta_x}\n"
    delta_context += f"delta_y: {delta_y}\n"
    with open(delta_file_name, "a") as delta_file:
        # delta_file.write(f"delta_x: {delta_x}\n")
        # delta_file.write(f"delta_y: {delta_y}\n")
        delta_file.write(delta_context)
    # print("delta_x:", delta_x)
    # print("delta_y:", delta_y)
    # print()
    if delta_y[1] == delta_y[2] and delta_y[0] == -3 * delta_y[1]:
        return True
    else:
        return False


def read_w_values_from_file(file_path):
    w_values = []
    with open(file_path, "r") as file:
        lines = file.readlines()
        for line in lines:
            # 每一行按逗号分隔，并转换为整数
            w = list(map(int, line.strip().split(" ")))  # 使用 strip 去除空白符
            w_values.append(w)
    return w_values


load("rc_permutation.sage")

file_path = "valid_new_w.txt"  # 你要读取的文件路径
w_values = read_w_values_from_file(file_path)
new_system = construct_2round_system()
# system=new_system
print("begin:")
for w in w_values:
    # print("w:", w)
    # system = construct_2round_system(w)
    system=[new_system[0],0,0]
    constants = [0, -w[0], -w[1]]
    for i in range(1, 3):
        system[i] = new_system[i] + constants[i]
    # print(system)
    if solve_with_magma(system, w):
        print(f"Solution found for w = {w}")
        break
    # print(f"System for w = {w}:")
    # print(system)
# system=construct_2round_system([1,0])
# print("System of equations:")
# for eq in system:
# print(eq)
# file_name=solve_with_magma(system)
# magma_output = run_magma(file_name)

# if magma_output:
# solutions = extract_solutions(magma_output)
# for s in system:
#     print(f"{s},")
#     # print(s.degree())
# print()
