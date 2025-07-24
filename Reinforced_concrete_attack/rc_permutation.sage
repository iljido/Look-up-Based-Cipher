# Re-run after kernel reset: define class-based RC with SageMath functionality

from sage.all import *

BLS12_SBOX = [...]  # To be filled in programmatically below
BN254_SBOX = [...]  # To be filled in programmatically below

# Parsed from user input
with open("bls_sbox.txt", "r") as f1, open("bn_sbox.txt", "r") as f2:
    BLS12_SBOX = list(map(int, f1.read().replace("[", "").replace("]", "").split(",")))
    BN254_SBOX = list(map(int, f2.read().replace("[", "").replace("]", "").split(",")))


class ReinforcedConcreteRC:
    def __init__(self, mode_name="BLS381"):
        self.MODES = {
            "BLS381": {
                "p": int(
                    "0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001",
                    16,
                ),
                "alpha_beta": (1, 3, 2, 4),
                "s": list(
                    reversed(
                        [
                            693,
                            696,
                            694,
                            668,
                            679,
                            695,
                            691,
                            693,
                            700,
                            688,
                            700,
                            694,
                            701,
                            694,
                            699,
                            701,
                            701,
                            701,
                            695,
                            698,
                            697,
                            703,
                            702,
                            691,
                            688,
                            703,
                            679,
                        ]
                    )
                ),
                "p_prime": 659,
                "sbox_table": BLS12_SBOX,
            },
            "BN254": {
                "p": int(
                    "0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001",
                    16,
                ),
                "alpha_beta": (1, 3, 2, 4),
                "s": list(
                    reversed(
                        [
                            651,
                            658,
                            656,
                            666,
                            663,
                            654,
                            668,
                            677,
                            681,
                            683,
                            669,
                            681,
                            680,
                            677,
                            675,
                            668,
                            675,
                            683,
                            681,
                            683,
                            683,
                            655,
                            680,
                            683,
                            667,
                            678,
                            673,
                        ]
                    )
                ),
                "p_prime": 641,
                "sbox_table": BN254_SBOX,
            },
            "ST": {
                "p": int(
                    "0x3fa0000000000000000000000000000000000000000000000000000000000001",
                    16,
                ),
                "alpha_beta": (1, 2, 3, 4),
                "s": [1024] * 24 + [1023],
                "p_prime": 1018,
            },
        }

        mode = self.MODES[mode_name]
        self.p = mode["p"]
        self.F = GF(self.p)
        self.alpha1, self.alpha2, self.beta1, self.beta2 = map(
            self.F, mode["alpha_beta"]
        )
        self.s = mode["s"]
        self.s_inverse = list(reversed(self.s))
        # print(self.s_inverse)
        self.p_prime = mode["p_prime"]
        self.n = len(self.s)
        self.sbox_table = mode["sbox_table"]
        self.round_constants = [
            [
                self.F(
                    0x215510B29C6B20E05516126A5B33016A16A92610D560C7ECBCA2345DAB7AE0BF
                ),
                self.F(
                    0x07E9C9F7343A930646FBFF4CE7BEA19ED1938A6DB7CAEDAA5E38F47AAE527624
                ),
                self.F(
                    0x015B1F41EC3A6E2B66530DCFC410F859243E6777CF44BB88D7DB57E9018DE353
                ),
            ],
            [
                self.F(
                    0x22C704FEDE5CDA19337169658A93F22FAAD854E493A9658773D803688859AA82
                ),
                self.F(
                    0x28C05784ECFB24064874E90F67193017FB6091CCD4ED819F1A25A9517F3C040E
                ),
                self.F(
                    0x12BD9CAE9374F5AC3CEAA747B8C5738F5E3FAA3488B1E7F1B23DC9F52CAB9797
                ),
            ],
            [
                self.F(
                    0x06FDE3A5B074A23F3A643B30D5A2051E1390EA1432E9736615D416D83A7FD85F
                ),
                self.F(
                    0x103278C9BC3B3383E99424C36DAE2CCC9FCBF7181D53276BEA4A47D79EAAE473
                ),
                self.F(
                    0x12B44D1037C7F6BEC1507C0EB6D55FBF9A57F84904914EA7D3EB33EAC23D4B1A
                ),
            ],
            [
                self.F(
                    0x10D954340CDCAE3D7C81A1AD43E13CFC52B24EBA26BBEFBD4A820FEDE4537988
                ),
                self.F(
                    0x1D8FB5D1EC360409E602CC2E78CD0658B667EA4C36C25E9DD3CCA25196CBFA53
                ),
                self.F(
                    0x11709DF530356F7807DA53BAC1C8D389EF7E0A2EB94095ACDD276043D07EF44F
                ),
            ],
            [
                self.F(
                    0x0236C4EAB23CFBE95493E6A0101724602B08CB99C4BD98D7CA37C1ECBBEE1148
                ),
                self.F(
                    0x1E0474C2F00538F6A05D05DCFC43E73F88010D373B409C254631188DD0428551
                ),
                self.F(
                    0x284536744255C64D18C36F259925ED6D3C5BB282EB574101F57E7960E37555C6
                ),
            ],
            [
                self.F(
                    0x0C921FA35EC9B5D7B6D47EB972F9AE13B0877F063B27C35D3AF8EE36081CB19E
                ),
                self.F(
                    0x23419E1990860E770065CD4E96A7E76C68B8198906DCD0CDB5C546B83DB91EAA
                ),
                self.F(
                    0x1B58C7C715B261CDA1FBBAD214D50C6ED6EA812C7D6DB78ED023A77F825EDC63
                ),
            ],
            [
                self.F(
                    0x2258C2DF6C6B393D2471F2BED2E63D4B74772375424EA75E2DAA36F8A2226ECD
                ),
                self.F(
                    0x015BB2517D8872CC185AA6CA3C0D834DAD5FBE288FA1C38662D5DBB95FC96988
                ),
                self.F(
                    0x2D8CF5AA0B7C11FDB431D45897214B9332928DABD2AB1007874813D8AC431018
                ),
            ],
            [
                self.F(
                    0x101DCC35A6D62B54733A9854021027AC199B0FE6B73F61555203C956BB45C406
                ),
                self.F(
                    0x0407EC9A0A155CFAB1C30E6C2C2C05B0C7353167A196883A71C30FCD8F07FCF5
                ),
                self.F(
                    0x284E315339D5E4D0A248A9EF71F9AAF6560096869B4859BDCCC9B57A2BFBA8A0
                ),
            ],
        ]

        # MDS matrix
        self.M = Matrix(self.F, 3, 3, [[2, 1, 1], [1, 2, 1], [1, 1, 2]])

        # Round constants
        # self.round_constants = [[self.F(i * j + 17 * j + 37 * i + 11) for j in range(3)] for i in range(8)]

        # b_i values (product of s_{i+1} to s_n)
        # s_inverse=list(reversed(self.s))
        # self.new_b = [prod(self.s[j+1:]) if j+1 < self.n else 1 for j in range(self.n)]
        # self.new_b = [prod(self.s[j] for j in range(i+1, self.n)) for i in range(self.n)]
        # self.new_b.append(1)
        # s_inverse=list(reversed(self.s))
        self.b = [prod(self.s[j] for j in range(i + 1, self.n)) for i in range(self.n)]
        # self.b =[prod(self.s_inverse[j] for j in range(i+1, n)) for i in range(n)]
        self.b.append(1)  # b_n = 1
        self.b = self.b[: self.n]
        # self.new_b = self.b[::-1]

    def decomp(self, x):
        coeffs = []
        remainder = int(x)
        for i in range(self.n):
            bi = 1 if i == 0 else prod(self.s_inverse[j] for j in range(i))
            xi = (remainder // bi) % self.s_inverse[i]
            coeffs.append(xi)
            remainder -= xi * bi
        # print("decomp:", coeffs[::-1])
        return coeffs[::-1]

    def comp(self, digits):
        # print("digits:", digits)
        # print("self.b:", self.b)
        return sum(xi * bi for xi, bi in zip(digits, self.b)) % self.p

    def sbox(self, xi):
        return self.sbox_table[xi] if xi < self.p_prime else xi
        # return xi  # Placeholder; replace with SBox lookup if needed

    def bar(self, x, verbose=False):
        if verbose == True:
            print(self.decomp(x))
            print("self.b:", self.b)
        return self.comp([self.sbox(xi) for xi in self.decomp(x)])

    def bars(self, x_tuple):
        return tuple(self.bar(xi) for xi in x_tuple)

    def bricks(self, x_tuple):
        x1, x2, x3 = x_tuple
        y1 = x1 ^ 5
        y2 = x2 * (x1 ^ 2 + self.alpha1 * x1 + self.beta1)
        y3 = x3 * (x2 ^ 2 + self.alpha2 * x2 + self.beta2)
        return (y1, y2, y3)

    def concrete(self, j, x_tuple):
        v = vector(self.F, x_tuple)
        return tuple(self.M * v + vector(self.F, self.round_constants[j - 1]))

    def to_hex(self, x_tuple):
        return tuple(hex(xi) for xi in x_tuple)

    def RC(self, x_tuple):
        x = self.concrete(1, x_tuple)
        print("Initial concrete:", self.to_hex(x))
        # for i in range(len(x)):
        #     print(f"x[{i}]: {hex(x[i])}")
        x = self.bricks(x)
        print("After first bricks:", self.to_hex(x))
        x = self.concrete(2, x)
        print("After first concrete:", self.to_hex(x))
        x = self.bricks(x)
        print("After second bricks:", self.to_hex(x))
        x = self.concrete(3, x)
        print("After second concrete:", self.to_hex(x))
        x = self.bricks(x)
        print("After third bricks:", self.to_hex(x))
        x = self.concrete(4, x)
        print("After third concrete:", self.to_hex(x))
        x = self.bars(x)
        print("After bars:", self.to_hex(x))
        x = self.concrete(5, x)
        print("After fourth concrete:", self.to_hex(x))
        x = self.bricks(x)
        print("After fourth bricks:", self.to_hex(x))
        x = self.concrete(6, x)
        print("After fifth concrete:", self.to_hex(x))
        x = self.bricks(x)
        print("After fifth bricks:", self.to_hex(x))
        x = self.concrete(7, x)
        print("After sixth concrete:", self.to_hex(x))
        x = self.bricks(x)
        print("After sixth bricks:", self.to_hex(x))
        x = self.concrete(8, x)
        print("After seventh concrete:", self.to_hex(x))
        return x


# Instantiate and run
# RC_model = ReinforcedConcreteRC("BN254")
# F = RC_model.F
# input_state = (F(11), F(18), F(0))
# output_state = RC_model.RC(input_state)
# # # output_state
# print("output_state:", output_state)
# for i in output_state:
#     print(hex(i))
# print(F)
# print(RC_model.round_constants)
# print(RC_model.bars(input_state))
# print(F(10))
# print(F(RC_model.bar(6549)))

# print(F)
# print(0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001)
