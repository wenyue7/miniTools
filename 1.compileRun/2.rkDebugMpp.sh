#!/bin/bash
#########################################################################
# File Name: 2.rkDebugMpp.sh
# Author: LiHongjin
# mail: 872648180@qq.com
# Created Time: Wed Aug  9 16:58:55 2023
#########################################################################

# set -e

dbgToolName=""
dbgPltName=""
ToolPlatform=""
prjRoot=`pwd`

selectPlatform()
{
    echo "Please select platform:"
    echo "  1. android 32"
    echo "  2. android 64"
    echo "  3. linux 32"
    echo "  4. linux 64"
    read -p "Please select debug plt:" plt 
    if [ -n $plt ]; then
        case $plt in
            '1')
                dbgPltName="android_32"
                ToolPlatform="arm"
                ;;
            '2')
                dbgPltName="android_64"
                ToolPlatform="aarch64"
                ;;
            '3')
                dbgPltName="linux_32"
                ;;
            '4')
                dbgPltName="linux_64"
                ;;
        esac
    else
        plt="1"
        dbgPltName="android_32"
        echo "default platform: $dbgPltName"
    fi
}

selectTool()
{
    echo "Please select tool:"
    echo "  1. gdb"
    echo "  2. lldb"
    read -p "Please select debug tool:" dbgTool
    if [ -n $dbgTool ]; then
        case $dbgTool in
            '1')
                dbgToolName="gdb"
                ;;
            '2')
                dbgToolName="lldb"
                ;;
        esac
    else
        dbgTool="2"
        dbgToolName="lldb"
        echo "default dbg tool: $dbgToolName"
    fi
}

dbgLldb()
{
    # proc lldb tool
    NDKRoot="${HOME}/work/android/ndk/android-ndk-r23b"
    LldbPath="toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/12.0.8/lib/linux"
    LldbSer="${NDKRoot}/${LldbPath}/${ToolPlatform}/lldb-server"
    devName=`adb devices | grep -v "List of devices attached" | cut -f 1`
    listenP="8888"
    echo "selected lldb-server: ${LldbSer}"
    adb push ${LldbSer} /vendor/bin
    
    
    # server
    startSerCmd="lldb-server p --server --listen \"*:$listenP\""
    echo "startSerCmd"
    adb shell $startSerCmd &
    
    
    # client
    debugCmdFile="debug.lldb"
    if [ ! -e ${debugCmdFile} ];then
        echo "platform select remote-android" > ${debugCmdFile}
        echo "platform connect connect://${devName}:$listenP" >> ${debugCmdFile}
        echo "platform settings -w /vendor/bin" >> ${debugCmdFile}
        echo "file mpi_dec_test" >> ${debugCmdFile}
        echo "b main" >> ${debugCmdFile}
        echo "r -i" >> ${debugCmdFile}
    fi
    lldb -s ${debugCmdFile}
}

dbgGdb()
{
    debugCmdFile="debug.gdb"
    # create dir
    debugDirRoot="${prjRoot}/preinstall"
    debugDirBin=""
    debugDirLib=""
    debugDirBin2=""
    debugDirLib2=""
    debugBin=""
    debugLib=""

    if [ ${dbgPltName} == "android_32" ]; then
        debugDirBin="${debugDirRoot}/vendor/bin"
        debugDirLib="${debugDirRoot}/vendor/lib"
        if [ -e ${debugCmdFile} ]; then
            binFile=`cat debug.gdb | grep serverCmd | awk '{print $3}'`
        else
            binFile="mpi_dec_test"
        fi
        debugBin="${prjRoot}/build/android/arm/test/${binFile}"
        debugLib="${prjRoot}/build/android/arm/mpp/libmpp.so"
    elif [ ${dbgPltName} == "android_64" ]; then
        debugDirBin="${debugDirRoot}/vendor/bin"
        debugDirLib="${debugDirRoot}/vendor/lib64"
        if [ -e ${debugCmdFile} ]; then
            binFile=`cat debug.gdb | grep serverCmd | awk '{print $3}'`
        else
            binFile="mpi_dec_test"
        fi
        debugBin="${prjRoot}/build/android/arm/test/${binFile}"
        debugLib="${prjRoot}/build/android/aarch64/mpp/libmpp.so"
    elif [ ${dbgPltName} == "linux_32" ]; then
        debugDirBin="${debugDirRoot}/usr/bin"
        debugDirLib="${debugDirRoot}/usr/lib"
        debugDirBin2="${debugDirRoot}/oem/usr/bin"
        debugDirLib2="${debugDirRoot}/oem/usr/lib"
        if [ -e ${debugCmdFile} ]; then
            binFile=`cat debug.gdb | grep serverCmd | awk '{print $3}'`
        else
            binFile="mpi_dec_test"
        fi
        debugBin="${prjRoot}/build/android/arm/test/${binFile}"
        debugLib="${prjRoot}/build/linux/arm/mpp/librockchip_mpp.so.0"
    elif [ ${dbgPltName} == "linux_64" ]; then
        debugDirBin="${debugDirRoot}/usr/bin"
        debugDirLib="${debugDirRoot}/usr/lib64"
        debugDirBin2="${debugDirRoot}/oem/usr/bin"
        debugDirLib2="${debugDirRoot}/oem/usr/lib64"
        if [ -e ${debugCmdFile} ]; then
            binFile=`cat debug.gdb | grep serverCmd | awk '{print $3}'`
        else
            binFile="mpi_dec_test"
        fi
        debugBin="${prjRoot}/build/android/arm/test/${binFile}"
        debugLib="${prjRoot}/build/linux/arm/mpp/librockchip_mpp.so.0"
    fi
    echo "exec file: ${debugBin}"

    if [ ! -e ${debugDirBin} ];then mkdir -p ${debugDirBin}; fi
    if [ ! -e ${debugDirLib} ];then mkdir -p ${debugDirLib}; fi
    if [[ -e ${debugBin} && -e ${debugDirBin} ]]; then cp ${debugBin} ${debugDirBin}; fi
    if [[ -e ${debugLib} && -e ${debugDirLib} ]]; then cp ${debugLib} ${debugDirLib}; fi

    if [ -n ${debugDirBin2} ]; then
        if [ ! -e ${debugDirBin2} ];then mkdir -p ${debugDirBin2}; fi
        if [[ -e ${debugBin} && -e ${debugDirBin2} ]]; then cp ${debugBin} ${debugDirBin2}; fi
    fi
    if [ -n ${debugDirLib2} ]; then
        if [ ! -e ${debugDirLib2} ];then mkdir -p ${debugDirLib2}; fi
        if [[ -e ${debugLib} && -e ${debugDirLib2} ]]; then cp ${debugLib} ${debugDirLib2}; fi
    fi


    # proc gdb tool
    # CCToolsRoot="${HOME}/Projects/prebuilts/toolschain/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf"
    CCToolsRoot="${HOME}/Projects/prebuilts/gcc/linux-x86"
    if [[ ${dbgPltName} == "android_32" || ${dbgPltName} == "linux_32" ]]; then
        RemoteGdbSer="gdbserver"

        LocGdbSerPath="arm/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf/bin"
        LocGdbSer="${CCToolsRoot}/${LocGdbSerPath}/gdbserver"
        if [[ -e ${LocGdbSer} && -e ${debugDirBin} ]]; then cp ${LocGdbSer} ${debugDirBin}/gdbserver; fi

        haveSer=$(adb shell which ${RemoteGdbSer})
        if [ -z "$haveSer" ]; then
            echo "push ${debugDirBin}/${RemoteGdbSer} to plt"
            if [ ${dbgPltName} == "android_32" ]; then
                adb push ${debugDirBin}/${RemoteGdbSer} /vendor/bin;
            else # [ ${dbgPltName} == "linux_32" ]; then
                adb push ${debugDirBin}/${RemoteGdbSer} /usr/bin;
                adb push ${debugDirBin}/${RemoteGdbSer} /oem/usr/bin;
            fi
        fi
    elif [[ ${dbgPltName} == "android_64" || ${dbgPltName} == "linux_64" ]]; then
        RemoteGdbSer="gdbserver64"

        LocGdbSerPath="aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin"
        LocGdbSer="${CCToolsRoot}/${LocGdbSerPath}/gdbserver"
        if [[ -e ${LocGdbSer} && -e ${debugDirBin} ]]; then cp ${LocGdbSer} ${debugDirBin}/gdbserver64; fi

        haveSer=$(adb shell which ${RemoteGdbSer})
        if [ -z "$haveSer" ]; then
            echo "push ${debugDirBin}/${RemoteGdbSer} to plt"
            if [ ${dbgPltName} == "android_64" ]; then
                adb push ${debugDirBin}/${RemoteGdbSer} /vendor/bin;
            else # [ ${dbgPltName} == "linux_64" ]; then
                adb push ${debugDirBin}/${RemoteGdbSer} /usr/bin;
                adb push ${debugDirBin}/${RemoteGdbSer} /oem/usr/bin;
            fi
        fi
    else
        echo "RemoteGdbSer select error"
    fi

    # CCToolsRoot="${HOME}/work/android/ndk/android-ndk-r16b"
    # GdbPath="prebuilt/linux-x86_64/bin"
    # Gdb="${CCToolsRoot}/${GdbPath}/gdb"
    HostGdb="gdb-multiarch"

    listenP="8899"
    localP="8898"

    echo "selected gdbserver: ${RemoteGdbSer}"
    echo "selected gdb: ${HostGdb}"
    adb forward tcp:${localP} tcp:${listenP}
    echo "adb port map:"
    adb forward --list
    # adb push ${GdbSer} /vendor/bin


    # server
    # mpp cmd
    if [ -e ${debugCmdFile} ];then
        MppCmd=`cat ${debugCmdFile} | grep serverCmd | sed 's/.*serverCmd: //g'`;
    else
        MppCmd="mpi_dec_test -i /sdcard/test.h264"
    fi
    echo "server cmd: ${MppCmd}"
    startSerCmd="${RemoteGdbSer} localhost:$listenP ${MppCmd}"
    adb shell $startSerCmd &
    echo ""


    # client
    if [ ! -e ${debugCmdFile} ];then
        echo "# pwd: `pwd`" > ${debugCmdFile}
        echo "# serverCmd: mpi_dec_test -h" >> ${debugCmdFile}
        echo "" >> ${debugCmdFile}

        echo "# local sets" >> ${debugCmdFile}
        echo "set sysroot preinstall/" >> ${debugCmdFile}
        echo "# set solib-search-path preinstall/vendor/lib" >> ${debugCmdFile}
        echo "# cd preinstall" >> ${debugCmdFile}
        echo "# file preinstall/vendor/bin/mpi_dec_test" >> ${debugCmdFile}
        echo "# load preinstall/vendor/lib/libmpp.so" >> ${debugCmdFile}
        echo "" >> ${debugCmdFile}

        echo "# target sets" >> ${debugCmdFile}
        echo "target remote :${localP}" >> ${debugCmdFile}
        echo "# set sysroot remote:/" >> ${debugCmdFile}
        echo "# set solib-search-path target:/vendor/lib:/system/lib" >> ${debugCmdFile}
        echo "" >> ${debugCmdFile}

        echo "b main" >> ${debugCmdFile}
        echo "continue" >> ${debugCmdFile}
        echo "layout src" >> ${debugCmdFile}
    fi
    # gdb-multiarch
    ${HostGdb} --command=${debugCmdFile}


    adb forward --remove tcp:${localP}
    echo "adb port map:"
    adb forward --list
}

selectTool
selectPlatform
echo "tool:$dbgToolName pltName:$dbgPltName"

if [ "$dbgToolName" = "gdb" ]; then
    dbgGdb
fi
if [ "$dbgToolName" = "lldb" ]; then
    dbgLldb
fi

# set +e
