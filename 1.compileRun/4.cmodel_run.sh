#!/bin/bash

# example: lhjRun.sh <proc> [<b>] [<bt>] [<gdb>] [<batch>]
clear

rootDir="/local/lhj/Projects/c_model2"
cmd_proc="null"
cmd_build=false
cmd_build_test=false
cmd_debug=false
cmd_batch=false

for para in $*
do
    case ${para} in
    "av1" | "hevc" | "avs2" | "vp9" | "avc")
        cmd_proc=${para}
        ;;
    "b")
        cmd_build=true
        ;;
    "bt")
        cmd_build_test=true
        ;;
    "gdb")
        cmd_debug=true
        ;;
    "batch")
        cmd_batch=true
        ;;
    *)
        echo "unsupport cmd"
        ;;
    esac
done

if [ $cmd_proc == "null" ]; then
    echo "proc is null"
    exit 0
fi

echo "proc: $cmd_proc"
echo "build: $cmd_build"
echo "build test: $cmd_build_test"
echo "debug: $cmd_debug"
echo "batch test: $cmd_batch"

# ============ check ============
function resultCheck()
{
    checkCnt=10
    for ((loop=0; loop<checkCnt; loop++))
    do
        # file1="testOut/Frame000${loop}/loopfilter_sao_out_check.txt"
        # file2="testOut/Frame000${loop}/loopfilter_sao_data.dat"

        # file1="testOut/Frame000${loop}/loopfilter_data.dat"
        # file2="testOut/Frame000${loop}/loopfilter_data_ver.dat"

        # file1="testOut/Frame000${loop}/loopfilter_origin_data.dat"
        # file2="testOut/Frame000${loop}/loopfilter_origin_data_ver.dat"

        file1="testOut/Frame000${loop}/filterd_dblk_mid_ver.dat"
        file2="Frame000${loop}/filterd_dblk_mid_ver.dat"

        if [[ -e ${file1} ]] && [[ -e ${file2} ]]; then
            # echo "file1: ${file1}"
            # echo "file2: ${file2}"
            # diff ${file1} ${file2} > /dev/null
            md5Val1=`md5sum ${file1} | awk '{print $1}'`
            md5Val2=`md5sum ${file2} | awk '{print $1}'`
            if [ $md5Val1 = $md5Val2 ]; then
                echo "--> [res]: frame:${loop} file compare pass"
            else
                echo "--> [res]: frame:${loop} file compare faile    vimdiff ${file1} ${file2}"
            fi
        fi
    done
}

# ============ build ============

function buildAv1()
{
    # rm CMake* Makefile aom* cmake_install.cmake config examples gen_src libaom_srcs.* resize_util -r

    # make clean &&
    #     cmake ..  &&
    #     make -j 10
    make clean
    cmake .. \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCONFIG_AV1_ENCODER=0 \
        -DCONFIG_AV1_DECODER=1 \
        -DAOM_TARGET_CPU=generic \
        -DCONFIG_MULTITHREAD=0 \
        -DENABLE_DOCS=0 \
        -DCONFIG_HARDWARE=1 &&
    make -B -j 10
}

function buildHevc()
{
    # rm CMake* Makefile aom* cmake_install.cmake config examples gen_src libaom_srcs.* resize_util -r

    # make clean &&
    #     cmake ..  &&
    #     make -j 10

    # cmake .. -DCMAKE_BUILD_TYPE=Debug -DERR_DETECT=1 -DCONFIG_HARDWARE=1 -DCMAKE_CXX_FLAGS="-Wall" &&
        make clean &&
        cmake .. -DCMAKE_BUILD_TYPE=Debug -DERR_DETECT=1 -DCONFIG_HARDWARE=1 &&
        make -j 10 &&
        make install
}

function buildAvs2()
{
    # rm CMake* Makefile aom* cmake_install.cmake config examples gen_src libaom_srcs.* resize_util -r
    cd Lbuild
    make clean &&
        cmake ../source \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_C_COMPILER=/bin/cc \
        -DCMAKE_CXX_COMPILER=/bin/c++ \
        -DCONFIG_HARDWARE=1 &&
        make -j 10
    cd ..
}

function buildVp9()
{
    # ./config.sh &&
    ./config.sh \
        --disable-vp8 \
        --disable-vp9-encoder \
        --disable-multithread \
        --disable-optimizations \
        --disable-docs \
        --disable-unit-tests \
        --enable-vp9-highbitdepth \
        --enable-debug \
        --enable-debug-libs \
        --disable-mmx \
        --disable-sse \
        --disable-sse2 \
        --disable-sse3 \
        --disable-ssse3 \
        --disable-sse4_1 \
        --disable-avx \
        --disable-avx2 \
        --disable-avx512 \
        --as=yasm \
        --enable-hardware &&
        make -B -j 6
        # make clean &&
}

function buildAvc()
{
    make clean \
        && make -j 20
}

# ============ run ============

function runSig()
{
    av1Cmd="./aomdec \
        -i /path/to/video \
        -o testOut/output.yuv \
        -b 0 \
        -e 10 \
        -c av1_vdp_cfg \
        -g av1_cmodel_cfg \
        -f loopfilter=0xF \
        -d testOut"

    hevcCmd="./hm \
        -i /path/to/video \
        -b 0 \
        -e 10 \
        -g hevc_cmodel_cfg \
        -f loopfilter=0xF \
        -d testOut"

    vp9Cmd="./vpxdec \
        -i /path/to/video \
        -o testOut/rec.yuv \
        -b 0 \
        -e 10 \
        -g vp9_cmodel_cfg \
        -f loopfilter=0xF \
        -d testOut"

    avs2Cmd="./Lbuild/bin/ldecod \
        -i /path/to/video \
        -o output/rec.yuv \
        -b 7 \
        -e 7 \
        -f loopfilter=0xF \
        -g source/bin/avs2_file_cmodel_cfg \
        -d testOut"

    avcCmd="./build/jm \
        -i /path/to/video \
        -b 0 \
        -e 0 \
        -g build/h264_cmodel_cfg \
        -f loopfilter=0xF \
        -d build"

    eval runCmd='$'${1}Cmd
    if [ "$2" == true ];then
        gdb --command=debug.gdb --args $runCmd
    else
        $runCmd
    fi

    echo "cmd: $runCmd"
}

function runAv1Batch()
{
    bash ~/Projects/batch_test.sh av1 /test_data/Allegro_AV1 \
        && bash ~/Projects/batch_test.sh av1 /test_data/Allegro_AV1_2020_09_28 \
        && bash ~/Projects/batch_test.sh av1 /test_data/movie_video_testdata/av1
}

function runHevcBatch()
{
    bash ~/Projects/batch_test.sh hevc /test_data/allegro_hevc_stream \
        && bash ~/Projects/batch_test.sh hevc /test_data/argon_streams_hevc_rockchip \
        && bash ~/Projects/batch_test.sh hevc /test_data/argon_streams_hevc_rockchip2 \
        && bash ~/Projects/batch_test.sh hevc /test_data/argon_streams_hevc_rockchip4 \
        && bash ~/Projects/batch_test.sh hevc /test_data/customer_error_stream/h265 \
        && bash ~/Projects/batch_test.sh hevc /test_data/error_stream_rk/err_stream_265 \
        && bash ~/Projects/batch_test.sh hevc /test_data/fpga_packet/normal_resolution/hevc \
        && bash ~/Projects/batch_test.sh hevc /test_data/fpga_packet/super_resolution/encoder_test/hevc \
        && bash ~/Projects/batch_test.sh hevc /test_data/fpga_packet/super_resolution/hevc \
        && bash ~/Projects/batch_test.sh hevc /test_data/hm-15.0-anchors \
        && bash ~/Projects/batch_test.sh hevc /test_data/mvc_stream_rk/H.265_mvc_stream \
        && bash ~/Projects/batch_test.sh hevc /test_data/movie_video_testdata/hevc \
        && bash ~/Projects/batch_test.sh hevc /test_data/super_resolution_stream/hevc \
        && bash ~/Projects/batch_test.sh hevc /test_data/super_resolution_stream/encoder_test/hevc
}

function runAvs2Batch()
{
    bash ~/Projects/batch_test.sh avs2 /test_data/AVS2_allegro \
        && bash ~/Projects/batch_test.sh avs2 /test_data/avs2_rockchip \
        && bash ~/Projects/batch_test.sh avs2 /test_data/avs2_standard_workgroup \
        && bash ~/Projects/batch_test.sh avs2 /test_data/error_stream_rk/avs2_err_stream \
        && bash ~/Projects/batch_test.sh avs2 /test_data/fpga_packet/normal_resolution/avs2 \
        && bash ~/Projects/batch_test.sh avs2 /test_data/fpga_packet/super_resolution/avs2 \
        && bash ~/Projects/batch_test.sh avs2 /test_data/super_resolution_stream/avs2
}

function runVp9Batch()
{
    bash ~/Projects/batch_test.sh vp9 /test_data/argon_streams_vp9_rockchip \
        && bash ~/Projects/batch_test.sh vp9 /test_data/fpga_packet/normal_resolution/vp9 \
        && bash ~/Projects/batch_test.sh vp9 /test_data/fpga_packet/super_resolution/vp9 \
        && bash ~/Projects/batch_test.sh vp9 /test_data/super_resolution_stream/vp9
}

function runAvcBatch()
{
    bash ~/Projects/batch_test.sh avc /test_data/allegro_h264_stream \
        && bash ~/Projects/batch_test.sh avc /test_data/customer_error_stream/h264 \
        && bash ~/Projects/batch_test.sh avc /test_data/error_stream_rk/err_stream_264 \
        && bash ~/Projects/batch_test.sh avc /test_data/fpga_packet/normal_resolution/h264 \
        && bash ~/Projects/batch_test.sh avc /test_data/fpga_packet/super_resolution/encoder_test/h264 \
        && bash ~/Projects/batch_test.sh avc /test_data/fpga_packet/super_resolution/h264 \
        && bash ~/Projects/batch_test.sh avc /test_data/super_resolution_stream/h264
        # && bash ~/Projects/batch_test.sh avc /test_data/super_resolution_stream/encoder_test/h264
}

# ============ main ============
if [ $cmd_build_test == true ]; then
    cd "${rootDir}/c_model_av1/build/" && buildAv1 && runSig av1
    read -p "continue? [y/n]:" runOpt; if [ "$runOpt" == "n" ];then exit 0; fi
    
    cd "${rootDir}/c_model_avs2/RD19.5/" && buildAvs2 && runSig avs2
    read -p "continue? [y/n]:" runOpt; if [ "$runOpt" == "n" ];then exit 0; fi
    
    cd "${rootDir}/c_model_h264_v2/jm18.6/" && buildAvc && runSig avc
    read -p "continue? [y/n]:" runOpt; if [ "$runOpt" == "n" ];then exit 0; fi
    
    cd "${rootDir}/c_model_hevc_v2/build/" && buildHevc && runSig hevc
    read -p "continue? [y/n]:" runOpt; if [ "$runOpt" == "n" ];then exit 0; fi
    
    cd "${rootDir}/c_model_vp9_10bit/libvpx-1.11.0/build/" && buildVp9 && runSig vp9
else
    if [ $cmd_build == true ]; then
        build${cmd_proc^}
    fi
    if [ $? -eq 0 ]; then
        if [ $cmd_batch == true ]; then
            run${cmd_proc^}Batch
        else
            runSig $cmd_proc $cmd_debug
        fi
    fi
fi

# resultCheck
