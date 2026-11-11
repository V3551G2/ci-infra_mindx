#!/bin/bash
set -eu
set -o pipefail

# presmoke 运行时仅需要 ascend-toolkit(set_env.sh) + 310P 算子包。
# 不再安装 nnal(ATB，presmoke 不使用) 与 device-sdk/minios(仅自定义算子编译需要)。
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%208.3.RC2/Ascend-cann-toolkit_8.3.RC2_linux-$(uname -m).run
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%208.3.RC2/Ascend-cann-kernels-310p_8.3.RC2_linux-$(uname -m).run
chmod +x *.run
echo y | ./Ascend-cann-toolkit_8.3.RC2_linux-$(uname -m).run --install --force

set +eux
source /etc/profile
source /usr/local/Ascend/ascend-toolkit/set_env.sh
set -eux
echo y | ./Ascend-cann-kernels-310p_8.3.RC2_linux-$(uname -m).run --install --install-path=/usr/local/Ascend

ls -l /usr/local/Ascend
ls -l /usr/local/Ascend/ascend-toolkit/latest/toolkit/toolchain/
rm -rf CANN* Ascend*