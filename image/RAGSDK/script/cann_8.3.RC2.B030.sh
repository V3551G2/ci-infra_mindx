#!/bin/bash
set -eu
set -o pipefail

# presmoke 运行时仅需要 ascend-toolkit(set_env.sh) + 算子二进制包。
# 算子包必须与 runner 实际机型匹配：self-hosted ragsdk 池实测 `npu-smi info` 机型为 910B4
# (见 Presmoke 任务诊断输出)，镜像内仅装 310p 算子时 aclnnGather 会报
#   error 561103 / "Op GatherElements does not has any binary"
# 即找不到与当前 SoC 匹配的算子二进制。故安装 910b 算子包；
# 同时保留 310p 算子包以兼容池内可能存在的 310P 机型(两份算子按 SoC 目录共存，互不冲突)。
# 不再安装 nnal(ATB，presmoke 不使用) 与 device-sdk/minios(仅自定义算子编译需要)。
CANN_PKG_URL=https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%208.3.RC2
wget --no-check-certificate ${CANN_PKG_URL}/Ascend-cann-toolkit_8.3.RC2_linux-$(uname -m).run
wget --no-check-certificate ${CANN_PKG_URL}/Ascend-cann-kernels-910b_8.3.RC2_linux-$(uname -m).run
wget --no-check-certificate ${CANN_PKG_URL}/Ascend-cann-kernels-310p_8.3.RC2_linux-$(uname -m).run
chmod +x *.run
echo y | ./Ascend-cann-toolkit_8.3.RC2_linux-$(uname -m).run --install --force

set +eux
source /etc/profile
source /usr/local/Ascend/ascend-toolkit/set_env.sh
set -eux
echo y | ./Ascend-cann-kernels-910b_8.3.RC2_linux-$(uname -m).run --install --install-path=/usr/local/Ascend
echo y | ./Ascend-cann-kernels-310p_8.3.RC2_linux-$(uname -m).run --install --install-path=/usr/local/Ascend

ls -l /usr/local/Ascend
ls -l /usr/local/Ascend/ascend-toolkit/latest/toolkit/toolchain/
ls -l /usr/local/Ascend/ascend-toolkit/latest/opp/built-in/op_impl/ai_core/tbe/kernel/
rm -rf CANN* Ascend*
