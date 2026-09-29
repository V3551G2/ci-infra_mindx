#!/bin/bash
set -eu
set -o pipefail

wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%209.0.0/Ascend-cann-toolkit_9.0.0_linux-x86_64.run
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%209.0.0/Ascend-cann-910b-ops_9.0.0_linux-x86_64.run
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%209.0.0/Ascend-cann-nnal_9.0.0_linux-x86_64.run
chmod +x *.run
echo y | ./Ascend-cann-toolkit_9.0.0_linux-x86_64.run --install --force

wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%209.0.0/Ascend-cann-device-sdk_9.0.0_linux-aarch64.zip
unzip Ascend-cann-device-sdk_9.0.0_linux-aarch64.zip
chmod +x *.run
echo y | ./cann-runtime-9.0.0-minios.aarch64.run --full --quiet --install-path=/usr/local/AscendMiniOs
echo y | ./cann-runtime-9.0.0-minios.aarch64.run --full --quiet --install-path=/usr/local/AscendMiniOSRun

set +eux
source /etc/profile
source /usr/local/Ascend/ascend-toolkit/set_env.sh
set -eux
echo y | ./Ascend-cann-nnal_9.0.0_linux-x86_64.run --install --install-path=/usr/local/Ascend
echo y | ./Ascend-cann-910b-ops_9.0.0_linux-x86_64.run --install --install-path=/usr/local/Ascend

ls -l /usr/local/Ascend
ls -l /usr/local/Ascend/ascend-toolkit/latest/toolkit/toolchain/
rm -rf CANN* Ascend*