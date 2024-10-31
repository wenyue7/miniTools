#!/usr/bin/env bash
#########################################################################
# File Name: rkBatchTCore.sh
# Author: LiHongjin
# mail: 872648180@qq.com
# Created Time: Thu 31 Oct 2024 10:01:19 AM CST
#########################################################################

dev_id_l=()
prot=""
strmsDir=""
dev_dir=""

dev_info_l=(`adbs -l | awk '{print $1}'`)
strm_list=()

exe="mpi_dec_test"
paras_hevc="-t 16777220 -i "
paras_avc="-t 7 -i "
paras_vp9="-t 10 -i "
paras_avs2="-t 16777223 -i "
paras_av1="-t 16777224 -i "

test_cmd_hevc="${exe} ${paras_hevc}"
test_cmd_avc="${exe} ${paras_avc}"
test_cmd_avs2="${exe} ${paras_avs2}"
test_cmd_vp9="${exe} ${paras_vp9}"
test_cmd_av1="${exe} ${paras_av1}"

function usage()
{
    echo "usage: $0 [-h] [-d device] <-p prot> <-s strms_dir> [--ddir dev_dir]"
    echo "  -h|--help   help info"
    echo "  -d|--dev    device, def all"
    echo "  -p|--prot   protocol, hevc/h265/265/avc/h264/264/avs2/vp9/av1"
    echo "  -s|--strms  source dir, raw stream of the same protocol"
    echo "  --ddir      device work dir, def /sdcard"
}

function procParas()
{
    # 双中括号提供了针对字符串比较的高级特性，使用双中括号 [[ ]] 进行字符串比较时，
    # 可以把右边的项看做一个模式，故而可以在 [[ ]] 中使用正则表达式：
    # if [[ hello == hell* ]]; then
    #
    # 位置参数可以用shift命令左移。比如shift 3表示原来的$4现在变成$1，原来的$5现在变成
    # $2等等，原来的$1、$2、$3丢弃，$0不移动。不带参数的shift命令相当于shift 1。

    # proc cmd paras
    while [[ $# -gt 0 ]]; do
        key="$1"
        case ${key} in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--dev)
                dev_id_l=(${2})
                shift # move to next para
                ;;
            -p|--prot)
                case ${2} in
                    hevc|h265|265) prot="hevc" ;;
                    avc|h264|264) prot="avc" ;;
                    avs2) prot="avs2" ;;
                    vp9) prot="vp9" ;;
                    av1) prot="av1" ;;
                    *) echo "unsuport protocol" ;;
                esac
                shift # move to next para
                ;;
            -s|--strms)
                strmsDir="${2}"
                shift # move to next para
                ;;
            --ddir)
                dev_dir="${2}"
                shift # move to next para
                ;;
            *)
                # unknow para
                echo "unknow para: ${key}"
                exit 1
                ;;
        esac
        shift # move to next para
    done

    [ -z "${prot}" ] && echo "Err: -p|--prot is necessary" && usage && exit 0
    [ -z "${strmsDir}" ] && echo "Err: -s|--strms is necessary" && usage && exit 0
    [ ! -e "${strmsDir}" ] && echo "Err: -s|--strms is invalid" && usage && exit 0
    [ -z "${dev_dir}" ] && dev_dir="/sdcard"

    # strm_list=(`ls -1 ${strmsDir}`)

    # proc for single file
    # -exec：执行后面的命令。对找到的每个文件执行指定的操作。
    # {}：占位符，代表 find 命令找到的每个文件。把每个匹配的文件替换到这个位置。
    # \;：结束符，表示 -exec 命令的结束。\ 是为了转义;，以防Shell将其解释为命令结束。
    strm_list=(`find ${strmsDir}  -maxdepth 1 -type f -exec basename {} \;`)
    [ -f "${strmsDir}" ] && strmsDir=`dirname ${strmsDir}`
}

function exec_test()
{
    echo
    echo "======> test begin <======"
    for dev_idx in ${dev_id_l[@]}
    do
        for cur_strm in ${strm_list[@]}
        do
            echo "[dev_id]: ${dev_idx} [name]: ${dev_info_l[${dev_idx}]} [strm]: ${cur_strm}"

            adbs --idx ${dev_idx} shell "ls -d ${dev_dir} > /dev/null 2>&1"
            [ "$?" -ne "0" ] && echo "Error: device dir not exist: ${dev_dir}" && exit 0
            adbs --idx ${dev_idx} push ${strmsDir}/${cur_strm} ${dev_dir}

            eval test_cmd='$'test_cmd_${prot}
            cur_cmd="adbs --idx ${dev_idx} shell ${test_cmd} ${dev_dir}/${cur_strm}"
            echo "cur test cmd: ${cur_cmd}"
            ${cur_cmd}
            if [ $? -eq 0 ]; then
                # echo -e "\033[0m\033[1;32m pass  \033[0m"
                printf  "\033[0m\033[1;32m pass  \033[0m\n"
            else
                # echo -e "\033[0m\033[1;31m failed \033[0m"
                printf  "\033[0m\033[1;31m failed \033[0m\n"
            fi

            adbs --idx ${dev_idx} shell rm ${dev_dir}/${cur_strm}
            echo
        done
    done
    echo "======> test end <======"
}

function main()
{
    procParas $@
    if [ ${#dev_id_l[@]} == 0 ]; then dev_id_l=(`seq 0 $(($(adbs -c) - 1))`); fi

    echo "======> $0 paras <======"
    echo "dev_id_l: ${dev_id_l[@]}"
    echo "prot:     ${prot}"
    echo "strmsDir: ${strmsDir}"
    echo "dev_dir:  ${dev_dir}"

    exec_test
}

main $@
