#!/bin/bash
set -eu
set -o pipefail

wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%209.0.0/Ascend-cann-toolkit_9.0.0_linux-$(uname -m).run
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%209.0.0/Ascend-cann-910b-ops_9.0.0_linux-$(uname -m).run
chmod +x *.run
echo y | ./Ascend-cann-toolkit_9.0.0_linux-$(uname -m).run --install --force

set +eux
source /etc/profile
source /usr/local/Ascend/ascend-toolkit/set_env.sh
set -eux
echo y | ./Ascend-cann-910b-ops_9.0.0_linux-$(uname -m).run --install --install-path=/usr/local/Ascend

ls -l /usr/local/Ascend
ls -l /usr/local/Ascend/ascend-toolkit/latest/toolkit/toolchain/
rm -rf CANN* Ascend*