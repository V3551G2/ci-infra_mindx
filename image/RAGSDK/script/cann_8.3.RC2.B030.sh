#!/bin/bash
set -eu
set -o pipefail

# CANN toolkit + kernels + nnal（按架构取 linux-x86_64 / linux-aarch64）
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%208.3.RC2/Ascend-cann-toolkit_8.3.RC2_linux-$(uname -m).run
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%208.3.RC2/Ascend-cann-kernels-310p_8.3.RC2_linux-$(uname -m).run
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%208.3.RC2/Ascend-cann-nnal_8.3.RC2_linux-$(uname -m).run
chmod +x *.run
echo y | ./Ascend-cann-toolkit_8.3.RC2_linux-$(uname -m).run --install --force

# device-sdk / minios 运行时（aarch64 公共步骤，x86/arm 两架构均安装）
wget --no-check-certificate https://mindcluster.obs.cn-north-4.myhuaweicloud.com/Ascend-cann-device-sdk_8.3.RC2_linux-aarch64.zip
unzip -q Ascend-cann-device-sdk_8.3.RC2_linux-aarch64.zip
chmod +x *.run
echo y | ./CANN-runtime-8.3.0.2.220-minios.aarch64.run --full --quiet --install-path=/usr/local/AscendMiniOs
echo y | ./CANN-runtime-8.3.0.2.220-minios.aarch64.run --full --quiet --install-path=/usr/local/AscendMiniOSRun

set +eux
source /etc/profile
source /usr/local/Ascend/ascend-toolkit/set_env.sh
set -eux
echo y | ./Ascend-cann-nnal_8.3.RC2_linux-$(uname -m).run --install --install-path=/usr/local/Ascend
echo y | ./Ascend-cann-kernels-310p_8.3.RC2_linux-$(uname -m).run --install --install-path=/usr/local/Ascend

ls -l /usr/local/Ascend
ls -l /usr/local/Ascend/ascend-toolkit/latest/toolkit/toolchain/
rm -rf CANN* Ascend*