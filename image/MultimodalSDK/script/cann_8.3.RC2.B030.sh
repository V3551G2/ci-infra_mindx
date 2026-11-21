#!/bin/bash
set -eu
set -o pipefail

# 门禁编译仅需 CANN toolkit：提供 libascendcl.so + acllib/include + set_env.sh。
# kernels-310p / nnal / device-sdk(minios) 在 MultimodalSDK 全仓无任何引用，
# 且 Build_Arm/UT_cpp 跑在无 NPU 的 arm cpu 节点上，故不再安装。
wget -q --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%208.3.RC2/Ascend-cann-toolkit_8.3.RC2_linux-aarch64.run
chmod +x Ascend-cann-toolkit_8.3.RC2_linux-aarch64.run
echo y | ./Ascend-cann-toolkit_8.3.RC2_linux-aarch64.run --install --force

set +eu
source /usr/local/Ascend/ascend-toolkit/set_env.sh
set -eu
echo "[INFO] CANN toolkit installed, ascendcl: $(ls /usr/local/Ascend/ascend-toolkit/latest/acllib/lib64/libascendcl.so 2>/dev/null || echo MISSING)"

rm -rf Ascend-cann-toolkit_8.3.RC2_linux-aarch64.run CANN* Ascend*