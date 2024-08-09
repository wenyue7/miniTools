#!/usr/bin/env bash

# when add new plt:
#   1. add plt name in pltList
#   2. add build methed

# set -e

sel_tag_ker="rk_kernel_b: "
sel_tag_mod="rk_kernel_b_m: "
sel_tag_android="rk_kernel_b_android: "

pltList=(
    "1109/1126_android"
    "3288_android"
    "3328_android"
    "3399_android"
    "3568_android"
    "3588_android"
    "3576_android"
    "1106_linux_5.10"
    "px30_linux_4.4_4.19"
    "3326_linux_4.4_4.19"
    "3399_linux_5.10"
    "3568_linux_4.19"
    "3588_linux_5.10"
    "3576_linux_5.10_fpga"
    "3576_linux_6.1_fpga"
    "3576_linux_6.1"
    )

build_mode_list=(
    "build_kmod"
    "build_kernel"
    )

curPlt="3588_android"
cur_android_ver=""

KERNEL_VER=`make kernelversion`
VERSION=`head -n 10 Makefile | grep "^VERSION" | awk '{print $3}'`
PATCHLEVEL=`head -n 10 Makefile | grep "^PATCHLEVEL" | awk '{print $3}'`
SUBLEVEL=`head -n 10 Makefile | grep "^SUBLEVEL" | awk '{print $3}'`

m_arch=""
m_config=""
m_make=""
build_mod=""
adbCmd=""

get_arch()
{
    if [ -n "${curPlt}" ]; then
        case ${curPlt} in
            '1109/1126_android'\
            |'3288_android'\
            |'1106_linux_5.10')
                m_arch="arm"
                ;;
            '3328_android'\
            |'3399_android'\
            |'3568_android'\
            |'3588_android'\
            |'3576_android'\
            |'px30_linux_4.4_4.19'\
            |'3326_linux_4.4_4.19'\
            |'3399_linux_5.10'\
            |'3568_linux_4.19'\
            |'3588_linux_5.10'\
            |'3576_linux_5.10_fpga'\
            |'3576_linux_6.1_fpga'\
            |'3576_linux_6.1')
                m_arch="arm64"
                ;;
        esac
    fi
}

init_tools_env()
{
    if [ "${m_arch}" == "arm" ]; then
        export PATH=${HOME}/Projects/prebuilts/toolchains/arm/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf/bin:$PATH
        export CROSS_COMPILE=arm-linux-gnueabihf-
    # else
    #     if [ -n "`echo ${curPlt} | grep android`" ]; then
    #     else
    #     fi
    fi
}

gen_cmd()
{
    # select android config
    if [ -n "`echo ${curPlt} | grep android`" ]; then
        android_ver_list=(`find ./ | grep "android-[0-9].*config" | sed "s/.*android-//g" | awk -F'[.-]' '{print $1}' | uniq`)
        if [ "${android_ver_list}" == "0" ]; then
            cur_android_ver=${android_ver_list[0]}
        else
            selectNode "${sel_tag_android}" "android_ver_list" "cur_android_ver" "android version"
        fi
    fi

    if [ -n "`cat drivers/video/rockchip/mpp/Makefile | grep obj-m | sed \"s/#.*//g\"`" ]; then
        # modify drivers/video/rockchip/mpp/Makefile need modify:
        # obj-$(CONFIG_ROCKCHIP_MPP_SERVICE) --> obj-m
        selectNode "${sel_tag_mod}" "build_mode_list" "build_mod" "build method"
    else
        # default build kernel
        build_mod="build_kernel";
    fi

    if [ -n "${curPlt}" ]; then
        case ${curPlt} in
            '1109/1126_android')
                echo "======> selected ${curPlt} <======"
                m_config="rv1126_defconfig"
                m_target="rv1126-evb-ddr3-v13.img"
                m_make="make"
                ;;
            '3288_android')
                echo "======> selected ${curPlt} <======"
                m_config="rockchip_defconfig"
                m_target="rk3288-evb-android-rk808-edp.img"
                m_make="make"
                ;;
            '3328_android')
                echo "======> selected ${curPlt} <======"
                m_config="rockchip_defconfig"
                m_target="rk3328-evb-android-avb.img BOOT_IMG=./boot_rk3328EVB.img"
                m_make="make"
                ;;
            '3399_android')
                echo "======> selected ${curPlt} <======"
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/clang-r416183b/bin:$PATH
                m_config="rockchip_defconfig android-11.config disable_incfs.config"
                m_target="BOOT_IMG=./boot_sample.img rk3399-evb-ind-lpddr4-android-avb.img"
                m_make="make CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"
                ;;
            '3568_android')
                echo "======> selected ${curPlt} <======"
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/clang-r416183b/bin:$PATH
                m_config="rockchip_defconfig rk356x.config android-11.config"
                m_target="rk3566-evb1-ddr4-v10.img BOOT_IMG=boot1.img"
                m_make="make CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"
                ;;
            '3588_android')
                echo "======> selected ${curPlt} <======"
                # 根据 build.sh 按照本地环境修改
                # export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/clang-r416183b/bin:$PATH
                export PATH=${HOME}/Projects/prebuilts/toolchains/linux-x86_rk/clang-r487747c/bin:$PATH
                m_config="rockchip_defconfig android-11.config"
                m_target="BOOT_IMG=./boot_3588.img rk3588-evb1-lp4-v10.img"
                m_make="make CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"
                ;;
            '3576_android')
                echo "======> selected ${curPlt} <======"
                # 根据 build.sh 按照本地环境修改
                export PATH=${HOME}/Projects/prebuilts/toolchains/linux-x86_rk/clang-r487747c/bin:$PATH
                m_config="rockchip_defconfig android-14.config rk3576.config"
                m_target="BOOT_IMG=./boot_3576.img rk3576-evb1-v10.img"
                m_make="make CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"
                ;;
            '1106_linux_5.10')
                echo "======> selected ${curPlt} <======"
                m_config="rv1106_defconfig"
                m_target="rv1106g-evb1-v11.img"
                m_make="make"
                ;;
            'px30_linux_4.4_4.19')
                echo "======> selected ${curPlt} <======"
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$PATH
                export CROSS_COMPILE=aarch64-none-linux-gnu-
                m_config="px30_linux_defconfig"
                m_target="px30-evb-ddr3-v10-linux.img"
                m_make="make"
                ;;
            '3326_linux_4.4_4.19')
                echo "======> selected ${curPlt} <======"
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$PATH
                export CROSS_COMPILE=aarch64-none-linux-gnu-
                m_config="rk3326_linux_robot_defconfig"
                m_target="rk3326-evb-lp3-v10-linux.img"
                m_make="make"
                ;;
            '3399_linux_5.10')
                echo "======> selected ${curPlt} <======"
                # 根据 build.sh 按照本地环境修改
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$PATH
                export CROSS_COMPILE=aarch64-none-linux-gnu-
                m_config="rockchip_linux_defconfig"
                m_target="rk3399-evb-ind-lpddr4-linux.img"
                m_make="make"
                ;;
            '3568_linux_4.19')
                echo "======> selected ${curPlt} <======"
                # 根据 build.sh 按照本地环境修改
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$PATH
                export CROSS_COMPILE=aarch64-none-linux-gnu-
                m_config="rockchip_linux_defconfig"
                m_target="rk3568-evb1-ddr4-v10-linux.img"
                m_make="make"
                ;;
            '3588_linux_5.10')
                echo "======> selected ${curPlt} <======"
                # 根据 build.sh 按照本地环境修改
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$PATH
                export CROSS_COMPILE=aarch64-none-linux-gnu-
                m_config="rockchip_linux_defconfig"
                m_target="rk3588-evb1-lp4-v10.img"
                m_make="make"
                ;;
            '3576_linux_5.10_fpga')
                echo "======> selected ${curPlt} <======"
                # 根据 build.sh 按照本地环境修改
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/clang-r416183b/bin:$PATH
                export CROSS_COMPILE=aarch64-none-linux-gnu-
                m_config="rockchip_defconfig LT0=none LLVM=1 LLVM_IAS=1"
                m_target="rk3576-fpga.img LT0=none LLVM=1 LLVM_IAS=1"
                m_make="make"
                ;;
            '3576_linux_6.1_fpga')
                echo "======> selected ${curPlt} <======"
                # 根据 build.sh 按照本地环境修改
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/clang-r433403/bin:$PATH
                export CROSS_COMPILE=aarch64-none-linux-gnu-
                m_config="rockchip_defconfig LT0=none LLVM=1 LLVM_IAS=1"
                m_target="rk3576-fpga.img LT0=none LLVM=1 LLVM_IAS=1"
                m_make="make"
                ;;
            '3576_linux_6.1')
                echo "======> selected ${curPlt} <======"
                # 根据 build.sh 按照本地环境修改
                export PATH=${HOME}/Projects/prebuilts/toolchains/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$PATH
                export CROSS_COMPILE=aarch64-none-linux-gnu-
                m_config="rockchip_linux_defconfig"
                m_target="rk3576-evb1-v10-linux.img"
                m_make="make"
                ;;
        esac
    fi
}

build_kernel_mod()
{
    if [ "${build_mod}" == "build_kernel" ]; then
        echo "======> compile kernel begin <======"
        config_cmd="${m_make} ARCH=${m_arch} ${m_config}"
        build_cmd="${m_make} ARCH=${m_arch} ${m_target} -j20"
        echo "config cmd: ${config_cmd}"
        echo "build  cmd: ${build_cmd}"
        ${config_cmd}
        if [ $? -ne 0 ]; then echo "config faile, cmd: ${config_cmd}"; exit 1; fi
        if [[ ${curPlt} == "3576_linux_5.10_fpga" || ${curPlt} == "3576_linux_6.1_fpga" ]]; then
            echo "modify .config for ${curPlt}";
            sed -i "s/# CONFIG_ROCKCHIP_MPP_RKVDEC3 is not set/CONFIG_ROCKCHIP_MPP_RKVDEC3=y/g" .config;
            # sed -i "s/# CONFIG_EXFAT_FS is not set/CONFIG_EXFAT_FS=y/g" .config;
            # sed -i "s/# CONFIG_NTFS_FS is not set/CONFIG_NTFS_FS=y/g" .config;
            if [ $? -ne 0 ]; then echo "modify .config faile"; fi
        fi
        if [ ${curPlt} == "3576_android" ]; then
            echo "modify .config for ${curPlt}";
            sed -i "s/# CONFIG_DEVMEM is not set/CONFIG_DEVMEM=y/g" .config;
            if [ $? -ne 0 ]; then echo "modify .config faile"; fi
        fi
        ${build_cmd}
        if [ $? -ne 0 ]; then echo "build faile, cmd: ${build_cmd}"; exit 1; fi
        echo "config cmd: ${config_cmd}"
        echo "build  cmd: ${build_cmd}"
        echo "======> compile kernel done <======"
    fi

    if [ "${build_mod}" == "build_kmod" ]; then
        echo "======> compile rk_vcodec.ko begin <======"
        build_mod_cmd="${m_make} ARCH=${m_arch} -C `pwd` M=`pwd`/drivers/video/rockchip/mpp modules"
        echo "build mod cmd: ${build_mod_cmd}"
        ${build_mod_cmd}
        echo "======> compile rk_vcodec.ko done <======"
    fi
}

download()
{
    if [ "${build_mod}" == "build_kernel" ]; then
        echo ""
        echo "======> copy boot.img to ~/test <======"
        echo "cur dir: `pwd`"
        cp boot.img ~/test

        echo ""
        echo "======> download boot.img <======"
        rkUT.sh -di -b
    fi

    if [ "${build_mod}" == "build_kmod" ]; then
        echo ""
        echo "======> reload rk_vcodec.ko <======"
        ${adbCmd} push drivers/video/rockchip/mpp/rk_vcodec.ko /data
        if [ -n "`${adbCmd} shell lsmod | grep rk_vcodec`" ]; then
            echo "rmmod old rk_vcodec.ko"
            ${adbCmd} shell rmmod rk_vcodec.ko
        fi
        echo "insmod rk_vcodec.ko"
        ${adbCmd} shell insmod /data/rk_vcodec.ko
    fi
}

# ====== main ======

adbCmd=$(adbs)
source $(dirname $(readlink -f $0))/../0.general_tools/0.select_node.sh

echo "KERNEL_VER = ${KERNEL_VER}"
echo "VERSION    = ${VERSION}"
echo "PATCHLEVEL = ${PATCHLEVEL}"
echo "SUBLEVEL   = ${SUBLEVEL}"

selectNode "${sel_tag_ker}" "pltList" "curPlt" "platform"
get_arch
init_tools_env
gen_cmd
build_kernel_mod
download

# set +e
