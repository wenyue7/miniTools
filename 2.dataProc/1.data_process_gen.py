#!/usr/bin/env python
# 程序说明：
# 从一个或者多个文件中读取一列数字，检查这一列数字是否为递增、将数据去重排序、将数据绘制到同一个坐标系中
# usage: <app> <file1> <file2> <file3>
import sys,getopt
import numpy as np
import math
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.lines as mlines
import matplotlib.patheffects as pe

def loadData(fname):
    f = open(fname)
    lines = f.readlines()

    nums = []
    for line in lines:
        cur = float(line.strip('\n'))
        nums.append(cur)

    return nums

def loadDataGrp(fnames):
    dataGrp = []

    for i in range(len(fnames)):
        nums = loadData(fnames[i])
        dataGrp.append(nums)

    return dataGrp

def dumpListToFile(fname, ldata):
    f = open(fname, "w")
    for i in ldata:
        f.write(str(i)+"\n")
    f.close()

def compList(list1, list2):
    print("list1 size %d list2 size %d" % (len(list1), len(list2)))
    loopMax = len
    if len(list1) < len(list2):
        loopMax = len(list1)
    else:
        loopMax = len(list2)

    print("list1 != list2 in index ", end='')
    for i in range(loopMax):
        if list1[i] != list2[i]:
            print(" ", i, end='')
    print()

def sortPoints(nums, delRep):
    nums.sort()
    if delRep == True :
        # 先将列表转换为集合，因为集合是不重复的，故直接删除重复元素
        return list(set(nums))
    return nums

def checkNumsInc(nums):
    lineNum = 0
    prev = 0
    cur = 0
    print("not increase in lineNum: ", end = '')
    for i in range(len(nums)):
        lineNum = lineNum + 1
        cur = nums[i]
        if prev > cur:
            print(" ", lineNum, end='')
        prev = cur
    print()
    return

# 获取所有预定义颜色
all_colors = list(mcolors.CSS4_COLORS.keys())
# 获取所有预定义的标记
all_markers = list(mlines.Line2D.markers.keys())
# 获取所有预定义的线型
all_linestyles = list(mlines.Line2D.lineStyles.keys())
tab_loc_ha = ['center', 'right', 'left']
tab_loc_va = ['center', 'top', 'bottom', 'baseline', 'center_baseline']

def plotVal(fileNames, dataGrp, refLineEn, refLine, showTag, showLine, calcAvg):
    if len(fileNames) != len(dataGrp):
        print("error: file cnt and data cnt is not equal")
        print("file cnt is %d data cnt is %d" % (len(fileNames), (len(dataGrp))))
        return

    fig = plt.figure()  # an empty figure with no Axes
    ax = fig.add_subplot()
    loopCnt = len(fileNames)

    for i in range(loopCnt):
        line_style = ['']
        if showLine == True:
            line_style = all_linestyles
        x = list(range(len(dataGrp[i])))
        line, = ax.plot(x, dataGrp[i],
                marker=all_markers[(i+int(i/len(all_markers)))%len(all_markers)],
                color=all_colors[i%len(all_colors)],
                linestyle=line_style[i%len(line_style)],
                # 设置标记的填充颜色，设置标记的边框颜色，设置边框的宽度，效果没有设置阴影好
                # markerfacecolor='yellow', markeredgecolor='black', markeredgewidth=2,
                alpha=1/2,
                label=fileNames[i])  # Plot some data on the axes.
        # 为线条和点设置阴影效果
        line.set_path_effects([pe.withStroke(linewidth=5, foreground="gray"), pe.Normal()])


        if showTag == True:
            for a, b in zip(x, dataGrp[i]):
                tab_loc_x = int(i / len(tab_loc_va))
                tab_loc_y = int(i % len(tab_loc_va))
                ax.text(a, b, (a, b), fontsize=10, ha=tab_loc_ha[tab_loc_x], \
                        va=tab_loc_va[tab_loc_y], color=all_colors[i%len(all_colors)])
        if calcAvg == True:
            avg = np.mean(dataGrp[i])
            plt.axhline(avg, color=all_colors[i%len(all_colors)], linestyle="dashdot", label="avg: "+str(avg))

        ax.legend()  # Add a legend.

    if refLineEn[0] == True:
        plt.axhline(refLine[0], linestyle='--', c='r')
    if refLineEn[1] == True:
        plt.axvline(refLine[1], linestyle='--', c='orangered')

    plt.show()

def help():
    print('opt:')
    print('  -h,--help  print help info')
    print('  -s     sort and delete repeate data')
    print('  --hl   add horizontal reference line')
    print('  --vl   add vertical reference line')
    print('  -t     display point tag')
    print('  -d     display diff')
    print('  -l     display line')
    print('  -a     display avg')
    print('  -f     input file')

def main(argv):

    # print('para num :', len(sys.argv))
    # print('para list:', str(sys.argv))

    # control para
    drAndSort = False
    refLineEn = [False, False] # [hor, ver]
    refLine = [0, 0] # [hor, ver]
    showTag = False
    showLine = False
    calcDiff = False
    calcAvg = False
    fileNames = []
    dataGrpCnt = 0

    try:
        opts, args = getopt.getopt(argv,"hsf:tlad", ["help=", "hl=", "vl="])
    except getopt.GetoptError:
        help()
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit()
        elif opt in ("-s"):
            drAndSort = True
        elif opt in ("--hl"):
            refLineEn[0] = True
            refLine[0] = arg
        elif opt in ("--vl"):
            refLineEn[1] = True
            refLine[1] = arg
        elif opt in ("-t"):
            showTag = True
        elif opt in ("-l"):
            showLine = True
        elif opt in ("-d"):
            calcDiff = True
        elif opt in ("-a"):
            calcAvg = True
        elif opt in ("-f"):
            fileNames.append(str(arg))
            dataGrpCnt += 1

    if dataGrpCnt == 0:
        help()
        sys.exit(0)


    dataGrp =  loadDataGrp(fileNames)
    print("==================== result ====================")
    for i in range(dataGrpCnt):
        print("====> %s <====" % fileNames[i])
        print("cnt: %d" % (len(dataGrp[i])))
        print("avg: %d" % np.mean(dataGrp[i]))
        # print("sum: %d" % sum(dataGrp[i]))
        if drAndSort == True:
            dataGrp[i] = sortPoints(dataGrp[i], False)
        if calcDiff == True:
            for j in range(len(dataGrp[i])-1):
                dataGrp[i][j] = dataGrp[i][j+1] - dataGrp[i][j]
            dataGrp[i].pop()
        checkNumsInc(dataGrp[i])

    print()
    plotVal(fileNames, dataGrp, refLineEn, refLine, showTag, showLine, calcAvg)


if __name__ == '__main__':
    main(sys.argv[1:])   # 过滤掉命令行中的文件名
