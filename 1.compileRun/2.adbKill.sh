#!/bin/bash
#########################################################################
# File Name: adbkill.sh
# Author: LiHongjin
# mail: 872648180@qq.com
# Created Time: 2021年12月28日 星期二 20时42分39秒
#########################################################################

adbCmd=$(adbs)
${adbCmd} shell pkill mediaserver
${adbCmd} shell pkill cameraserver
${adbCmd} shell killall media.codec
${adbCmd} shell killall rockchip.hardware.rockit.hw@1.0-service
