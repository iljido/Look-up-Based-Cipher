import math
import random

'''
Params
'''

Prime_BLS = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
Bucket = [679, 703, 688, 691, 702, 703, 697, 698, 695, 701, 701, 701, 699, 694, 701, 694, 700, 688, 700, 693, 691, 695, 679, 668, 694, 696, 693]
s1 = Bucket[-1]
s_bound = 659

Table_s_bound = [171, 178, 483, 527, 653, 408, 197, 599, 300, 607, 403, 511, 579, 520, 591, 412, 261, 559,
        551, 154, 180, 138, 596, 150, 276, 271, 48, 168, 362, 637, 467, 164, 536, 554, 287, 530,
        431, 92, 654, 518, 323, 572, 624, 4, 258, 439, 430, 495, 534, 222, 545, 31, 44, 18, 80, 55,
        399, 328, 505, 313, 441, 586, 501, 598, 566, 568, 77, 496, 106, 563, 537, 78, 50, 450, 445,
        166, 237, 617, 185, 404, 621, 578, 133, 517, 646, 98, 86, 492, 267, 193, 33, 476, 207, 17,
        487, 643, 52, 384, 74, 148, 121, 657, 633, 528, 269, 611, 567, 601, 391, 231, 226, 658,
        331, 191, 354, 23, 474, 277, 390, 341, 279, 442, 422, 638, 15, 196, 329, 377, 36, 433, 398,
        72, 256, 352, 253, 550, 635, 142, 343, 176, 500, 588, 413, 569, 266, 42, 283, 535, 410,
        538, 647, 85, 27, 423, 558, 61, 356, 348, 43, 19, 625, 291, 238, 274, 432, 448, 100, 642,
        260, 587, 622, 608, 366, 420, 477, 316, 605, 254, 130, 407, 471, 174, 631, 34, 652, 628,
        175, 134, 122, 192, 531, 217, 32, 257, 145, 307, 262, 83, 509, 440, 600, 589, 359, 522,
        268, 143, 498, 512, 333, 651, 151, 183, 126, 351, 39, 246, 242, 630, 543, 574, 610, 655,
        25, 494, 456, 612, 123, 315, 340, 296, 580, 503, 281, 428, 62, 10, 76, 203, 288, 91, 426,
        128, 629, 29, 218, 292, 447, 161, 117, 388, 540, 364, 245, 541, 224, 502, 370, 229, 90,
        466, 636, 208, 51, 562, 259, 344, 334, 111, 235, 488, 632, 577, 54, 386, 75, 181, 463, 421,
        24, 96, 406, 156, 158, 265, 5, 310, 37, 124, 88, 155, 480, 593, 202, 451, 1, 497, 645, 457,
        187, 56, 206, 179, 640, 249, 99, 240, 460, 490, 163, 369, 293, 186, 553, 46, 449, 41, 219,
        308, 7, 234, 336, 373, 372, 347, 215, 481, 542, 146, 357, 656, 136, 330, 595, 516, 592,
        273, 365, 8, 47, 641, 81, 484, 573, 614, 437, 533, 0, 282, 184, 400, 49, 114, 374, 280,
        499, 418, 139, 382, 613, 233, 345, 393, 575, 508, 299, 101, 582, 360, 285, 2, 376, 548,
        189, 648, 214, 618, 385, 371, 425, 552, 204, 286, 443, 210, 294, 211, 241, 461, 275, 165,
        350, 59, 583, 159, 434, 252, 71, 436, 529, 236, 475, 339, 367, 147, 170, 110, 22, 298, 506,
        172, 247, 513, 73, 230, 314, 239, 157, 116, 65, 11, 570, 40, 620, 205, 251, 594, 468, 69,
        489, 109, 452, 465, 312, 383, 129, 379, 335, 353, 602, 546, 243, 57, 473, 486, 320, 162,
        526, 115, 26, 560, 107, 458, 519, 169, 97, 358, 504, 414, 13, 459, 132, 167, 402, 14, 491,
        571, 105, 112, 363, 581, 194, 84, 349, 201, 462, 289, 53, 603, 209, 396, 303, 317, 102, 82,
        131, 639, 3, 435, 378, 415, 539, 223, 30, 510, 199, 479, 397, 45, 248, 561, 67, 213, 438,
        20, 405, 557, 120, 89, 584, 555, 264, 419, 525, 429, 392, 311, 68, 446, 270, 585, 113, 627,
        472, 38, 375, 327, 127, 417, 547, 12, 108, 368, 95, 250, 322, 198, 380, 149, 104, 87, 332,
        135, 28, 318, 482, 221, 188, 58, 544, 521, 93, 324, 64, 272, 297, 644, 453, 225, 606, 295,
        216, 152, 411, 361, 444, 469, 427, 507, 395, 609, 153, 381, 464, 424, 94, 9, 564, 321, 615,
        21, 227, 137, 70, 326, 549, 556, 565, 416, 470, 255, 60, 604, 590, 305, 35, 278, 6, 125,
        387, 220, 597, 63, 454, 401, 119, 302, 309, 342, 16, 619, 493, 290, 616, 173, 304, 195,
        524, 263, 212, 649, 626, 409, 338, 306, 389, 79, 160, 66, 177, 232, 478, 514, 650, 455,
        103, 144, 355, 182, 346, 284, 200, 634, 244, 140, 337, 325, 319, 532, 394, 118, 485, 301,
        623, 190, 523, 515, 576, 141, 228]
Table_s1 = [
171, 178, 483, 527, 653, 408, 197, 599, 300, 607, 403, 511, 579, 520, 591, 412, 261, 559, 551, 154, 180, 138, 596, 150, 276, 271, 48, 168, 362, 637, 467, 164, 536, 554, 287, 530, 431, 92, 654, 518, 323, 572, 624, 4, 258, 439, 430, 495, 534, 222, 545, 31, 44, 18, 80, 55, 399, 328, 505, 313, 441, 586, 501, 598, 566, 568, 77, 496, 106, 563, 537, 78, 50, 450, 445, 166, 237, 617, 185, 404, 621, 578, 133, 517, 646, 98, 86, 492, 267, 193, 33, 476, 207, 17, 487, 643, 52, 384, 74, 148, 121, 657, 633, 528, 269, 611, 567, 601, 391, 231, 226, 658, 331, 191, 354, 23, 474, 277, 390, 341, 279, 442, 422, 638, 15, 196, 329, 377, 36, 433, 398, 72, 256, 352, 253, 550, 635, 142, 343, 176, 500, 588, 413, 569, 266, 42, 283, 535, 410, 538, 647, 85, 27, 423, 558, 61, 356, 348, 43, 19, 625, 291, 238, 274, 432, 448, 100, 642, 260, 587, 622, 608, 366, 420, 477, 316, 605, 254, 130, 407, 471, 174, 631, 34, 652, 628, 175, 134, 122, 192, 531, 217, 32, 257, 145, 307, 262, 83, 509, 440, 600, 589, 359, 522, 268, 143, 498, 512, 333, 651, 151, 183, 126, 351, 39, 246, 242, 630, 543, 574, 610, 655, 25, 494, 456, 612, 123, 315, 340, 296, 580, 503, 281, 428, 62, 10, 76, 203, 288, 91, 426, 128, 629, 29, 218, 292, 447, 161, 117, 388, 540, 364, 245, 541, 224, 502, 370, 229, 90, 466, 636, 208, 51, 562, 259, 344, 334, 111, 235, 488, 632, 577, 54, 386, 75, 181, 463, 421, 24, 96, 406, 156, 158, 265, 5, 310, 37, 124, 88, 155, 480, 593, 202, 451, 1, 497, 645, 457, 187, 56, 206, 179, 640, 249, 99, 240, 460, 490, 163, 369, 293, 186, 553, 46, 449, 41, 219, 308, 7, 234, 336, 373, 372, 347, 215, 481, 542, 146, 357, 656, 136, 330, 595, 516, 592, 273, 365, 8, 47, 641, 81, 484, 573, 614, 437, 533, 0, 282, 184, 400, 49, 114, 374, 280, 499, 418, 139, 382, 613, 233, 345, 393, 575, 508, 299, 101, 582, 360, 285, 2, 376, 548, 189, 648, 214, 618, 385, 371, 425, 552, 204, 286, 443, 210, 294, 211, 241, 461, 275, 165, 350, 59, 583, 159, 434, 252, 71, 436, 529, 236, 475, 339, 367, 147, 170, 110, 22, 298, 506, 172, 247, 513, 73, 230, 314, 239, 157, 116, 65, 11, 570, 40, 620, 205, 251, 594, 468, 69, 489, 109, 452, 465, 312, 383, 129, 379, 335, 353, 602, 546, 243, 57, 473, 486, 320, 162, 526, 115, 26, 560, 107, 458, 519, 169, 97, 358, 504, 414, 13, 459, 132, 167, 402, 14, 491, 571, 105, 112, 363, 581, 194, 84, 349, 201, 462, 289, 53, 603, 209, 396, 303, 317, 102, 82, 131, 639, 3, 435, 378, 415, 539, 223, 30, 510, 199, 479, 397, 45, 248, 561, 67, 213, 438, 20, 405, 557, 120, 89, 584, 555, 264, 419, 525, 429, 392, 311, 68, 446, 270, 585, 113, 627, 472, 38, 375, 327, 127, 417, 547, 12, 108, 368, 95, 250, 322, 198, 380, 149, 104, 87, 332, 135, 28, 318, 482, 221, 188, 58, 544, 521, 93, 324, 64, 272, 297, 644, 453, 225, 606, 295, 216, 152, 411, 361, 444, 469, 427, 507, 395, 609, 153, 381, 464, 424, 94, 9, 564, 321, 615, 21, 227, 137, 70, 326, 549, 556, 565, 416, 470, 255, 60, 604, 590, 305, 35, 278, 6, 125, 387, 220, 597, 63, 454, 401, 119, 302, 309, 342, 16, 619, 493, 290, 616, 173, 304, 195, 524, 263, 212, 649, 626, 409, 338, 306, 389, 79, 160, 66, 177, 232, 478, 514, 650, 455, 103, 144, 355, 182, 346, 284, 200, 634, 244, 140, 337, 325, 319, 532, 394, 118, 485, 301, 623, 190, 523, 515, 576, 141, 228, 659, 660, 661, 662, 663, 664, 665, 666, 667, 668, 669, 670, 671, 672, 673, 674, 675, 676, 677, 678,679,680,681,682,683,684,685,686,687,688,689,690,691,692
]

def print_DDT(DDT):
    for i in range(0,len(DDT)):
        print(DDT[i])

def DDT_uniform(DDT):
    unique_values = set()
    for row in DDT:
        unique_values.update(row)
    # how many (val) are there in DDT entries
    count_dict = {str(val): 0 for val in unique_values} 

    for row in DDT:
        for val in row:
            count_dict[str(val)] += 1


    print(count_dict)
    for key, value in count_dict.items():
        print("{}: {}".format(key,value/(len(DDT)**2)))


# Only the least significant nibble s1 active
# For plaintexts, we only consider x0,x1 < s1

def Cal_DDT(Table,s):
    DDT = [[0 for i in range(2*s)] for j in range(2*s)]
    num_DDT = 0
    for a in range(-s+1,s):
        if (a >= 0):
            delta_x = a
        else:
            delta_x = Prime_BLS+a

        for x0 in range(0,s):

            x1 = (x0+delta_x)%Prime_BLS
            if (x1 < s):
                y0 = Table[x0]
                y1 = Table[x1]
                delta_y = (y1-y0)%Prime_BLS

                if (delta_y > Prime_BLS-s):
                    delta_y = abs(delta_y-Prime_BLS)+s
                if (delta_x > Prime_BLS-s):
                    delta_x = abs(delta_x-Prime_BLS)+s

                DDT[delta_x][delta_y] += 1
                num_DDT += 1

    return DDT

# For a fixed d_in/d_out pair, 
# def test_Pro(DDT,s):
#     for delta_x in range(0,s):
#         num = 0
#         for delta_y in DDT[delta_x]:
#             if delta_y != 0:
#                 num += 1
#         print("{}: {}".format(delta_x,num/(s**2)))

def generate_outdiff_pair(s1):

    outdiff_pair = []

    for d2_out in range(0,s1):
        d3_out = d2_out
        d1_out = (-3 * d2_out) % Prime_BLS
        if (d1_out < s1) or (d1_out > Prime_BLS-s1):
            outdiff_pair.append([d1_out,d2_out,d3_out])

    for d2_out in range(Prime_BLS-s1,Prime_BLS):
        d3_out = d2_out
        d1_out = (-3 * d2_out) % Prime_BLS
        if (d1_out < s1) or (d1_out > Prime_BLS-s1):
            if (d1_out,d2_out,d3_out) not in outdiff_pair:
                outdiff_pair.append([d1_out,d2_out,d3_out])
    print("we have 2^{} valid output diff for Bars".format(math.log(len(outdiff_pair))/math.log(2)))

    return outdiff_pair

def generate_indiff_pair(s1):

    indiff_pair = []

    for x in range(-s1+1,s1):
        x1 = (x)%Prime_BLS
        for y in range(-s1+1,s1):
            x3 = (y)%Prime_BLS

            # w2 = (x2-x1)%Prime_BLS
            # w3 = (x1-w2)%Prime_BLS

            x2 = (3*x1 - x3)%Prime_BLS
            if (x2 < s1) or (x2 > Prime_BLS-s1):
                # if (x1,x2,x3) not in indiff_pair:
                indiff_pair.append([x1,x2,x3])


    print("we have 2^{} valid input diff for Bars".format(math.log(len(indiff_pair))/math.log(2)))

    return indiff_pair

def connect_in_out(Table_s1,s1):
    indiff_pair = generate_indiff_pair(s1)
    outdiff_pair = generate_outdiff_pair(s1)
    DDT_s1 = Cal_DDT(Table_s1,s1)
    num_valid_diff = 0
    valid_diff = []

    for indiff in indiff_pair:
        for outdiff in outdiff_pair:
            d1_in = indiff[0]  
            d2_in = indiff[1]  
            d3_in = indiff[2]
            d1_out = outdiff[0]
            d2_out = outdiff[1]  
            d3_out = outdiff[2]

            if(d1_in > Prime_BLS-s1):
                d1_in = abs(Prime_BLS-d1_in)+s1
            if(d2_in > Prime_BLS-s1):
                d2_in = abs(Prime_BLS-d2_in)+s1
            if(d3_in > Prime_BLS-s1):
                d3_in = abs(Prime_BLS-d3_in)+s1
            if(d1_out > Prime_BLS-s1):
                d1_out = abs(Prime_BLS-d1_out)+s1
            if(d2_out > Prime_BLS-s1):
                d2_out = abs(Prime_BLS-d2_out)+s1
            if(d3_out > Prime_BLS-s1):
                d3_out = abs(Prime_BLS-d3_out)+s1


            if (DDT_s1[d1_in][d1_out] != 0) and (DDT_s1[d2_in][d2_out] != 0) and (DDT_s1[d3_in][d3_out] != 0):
                num_valid_diff += 1
                valid_diff_pair = [indiff[0],indiff[1],indiff[2],outdiff[0],outdiff[1],outdiff[2]]
                # if valid_diff_pair not in valid_diff:
                valid_diff.append(valid_diff_pair)

    print("we have 2^{} valid differences for Bars".format(math.log(num_valid_diff)/math.log(2)))

    valid_indiff = []
    valid_outdiff = []
    for valid_diff_pair in valid_diff:
        valid_indiff_pair = valid_diff_pair[:3]
        valid_outdiff_pair = valid_diff_pair[3:]
        valid_indiff.append(valid_indiff_pair)
        valid_outdiff.append(valid_outdiff_pair)

    unique_valid_indiff = list(set(tuple(row) for row in valid_indiff))
    unique_valid_outdiff = list(set(tuple(row) for row in valid_outdiff))

    print("we have 2^{} valid input differences for Bars".format(math.log(len(unique_valid_indiff))/math.log(2)))
    print("we have 2^{} valid output differences for Bars".format(math.log(len(unique_valid_outdiff))/math.log(2)))

    with open("./valid_indiff.txt", 'w') as f:
        for row in unique_valid_indiff:
            f.write(f"{row}\n")
    return valid_diff

def valid_pair_bars(valid_diff):
    pro = 0
    tmp = 0
    average_pro = 0

    l = len(valid_diff)
    for i in range(1000):

        n_diff = random.randint(0,l-1)
        diff =valid_diff[n_diff]
        num_pair = 0
        count = 0
        for x0 in range(0,s1):
            input_diff = diff[2]
            output_diff = diff[5]
            x1 = (x0 + input_diff)%Prime_BLS

            if (x1 < s1):
                num_pair += 1
                y0 = Table_s1[x0]
                y1 = Table_s1[x1]
                delta_out = (y1-y0) % Prime_BLS
                if delta_out == output_diff:
                    count += 1
        if count > 0:
            # pro = count/num_pair
            average_pro += count
            # tmp += 1
            print(i,count)
    print(average_pro/1000)



valid_diff = connect_in_out(Table_s1,s1)


