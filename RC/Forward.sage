Prime_BLS = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
#p = 18446744073709551557
F = GF(Prime_BLS)
varlist = ['m1', 'm2', 'dm1']
P = PolynomialRing(F, names=varlist)
P.inject_variables()
m1, m2, dm1 = P.gens()
a1, a2, b1, b2 = P(1), P(3), P(2), P(4)

r = 5
C = [[F.random_element() for _ in range(3)] for _ in range(r)]

def Bricks(x1,x2,x3):
    y1, y2, y3 = P(0), P(0), P(0)
    
    y1 = x1**5
    y2 = x2*(x1**2 + a1*x1 + b1)
    y3 = x3*(x2**2 + a2*x2 + b2)
    return y1, y2, y3

def Concrete(x1,x2,x3,r):
    y1, y2, y3 = P(0), P(0), P(0)

    y1 = 2*x1 + x2 + x3 + C[r][0]
    y2 = x1 + 2*x2 + x3 + C[r][1]
    y3 = x1 + x2 + 2*x3 + C[r][2]

    return y1, y2, y3


def GenPolyNew(m1,m2,dm1):
    # input M1
    x1 = m1
    x2 = m2
    x3 = P(0)

    xx1 = m1 + dm1
    xx2 = m2 - 2*dm1
    xx3 = P(0)
    
    y1, y2, y3 = Concrete(x1, x2, x3, 0)
    yy1,yy2,yy3= Concrete(xx1,xx2,xx3,0)

    z1, z2, z3 = Bricks(y1, y2, y3)
    zz1,zz2,zz3= Bricks(yy1,yy2,yy3)

    t1, t2, t3 = Concrete(z1, z2, z3, 1)
    tt1,tt2,tt3= Concrete(zz1,zz2,zz3,1)

    s1, s2, s3 = Bricks(t1, t2, t3)
    ss1,ss2,ss3= Bricks(tt1,tt2,tt3)

    #u1, u2, u3 = Concrete(s1, s2, s3, 2)
    #uu1,uu2,uu3= Concrete(ss1,ss2,ss3,2)

    #v1, v2, v3 = Bricks(u1, u2, u3)
    #vv1,vv2,vv3= Bricks(uu1,uu2,uu3)
    
    f1 = tt1-t1
    f2 = ss2-s2
    f3 = ss3-s3

    return f1,f2,f3

f1,f2,f3=GenPoly(m1,m2,dm1)
print(f1, end = ",\n")
print(f2, end = ",\n")
print(f3, end = )
print(f1.degree(),f2.degree(),f3.degree())


















