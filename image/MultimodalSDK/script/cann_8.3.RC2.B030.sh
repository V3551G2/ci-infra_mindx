#!/bin/bash
set -eu
set -o pipefail

TOOLKIT_ROOT=/usr/local/Ascend/ascend-toolkit/latest

# 门禁编译仅需 CANN toolkit：提供 libascendcl.so + set_env.sh。
# kernels-310p / nnal / device-sdk(minios) 在 MultimodalSDK 全仓无任何引用，
# 且 Build_Arm/UT_cpp 跑在无 NPU 的 arm cpu 节点上，故不安装。
wget -q --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/CANN/CANN%208.3.RC2/Ascend-cann-toolkit_8.3.RC2_linux-aarch64.run
chmod +x Ascend-cann-toolkit_8.3.RC2_linux-aarch64.run
echo y | ./Ascend-cann-toolkit_8.3.RC2_linux-aarch64.run --install --force

ASCENDCL_LIB="${TOOLKIT_ROOT}/acllib/lib64/libascendcl.so"
if [ ! -e "${ASCENDCL_LIB}" ]; then
    echo "[ERROR] libascendcl.so not found after CANN toolkit install: ${ASCENDCL_LIB}"
    exit 1
fi

# ---------------------------------------------------------------------------
# 固化 securec.h
#   AccSDK / acc_data 的 CMake 用 find_path(securec.h) 在 /usr/local/Ascend/driver 下
#   按 PATH_SUFFIXES(include / runtime/include / compiler/include ...) 查找，
#   其中 compiler/include 等目录即将被裁剪，故先拷贝到 driver/include（find_path 首选，
#   且属于保留下来的 driver 目录），保证裁剪后仍能被找到。
# ---------------------------------------------------------------------------
SECUREC_H=$(find /usr/local/Ascend -name securec.h -type f 2>/dev/null | head -n1 || true)
if [ -n "${SECUREC_H}" ]; then
    mkdir -p /usr/local/Ascend/driver/include
    cp -f "${SECUREC_H}" /usr/local/Ascend/driver/include/securec.h
    echo "[INFO] securec.h pinned: ${SECUREC_H} -> /usr/local/Ascend/driver/include/securec.h"
else
    echo "[WARN] securec.h not found under /usr/local/Ascend"
fi

# ---------------------------------------------------------------------------
# 裁剪 CANN toolkit 冗余组件（保留 acllib/runtime/lib64/include/set_env.sh 等编译运行必需项）
#   以下组件仅服务于模型转换(ATC)、算子开发(Opp/AscendC)、性能工具与 IDE，
#   MultimodalSDK 的编译与 UT 均不引用，直接删除以缩小镜像体积。
#   保留：acllib(runtime 库+头文件)、runtime、lib64、include、conf、var、
#         set_env.sh、version.*、platform.ini、aarch64-linux/ 等。
# ---------------------------------------------------------------------------
PRUNE_DIRS="compiler opp ops tools mindstudio-toolkit test-ops bisheng_toolkit fwkacllib hccl pyACL python atc bin"
for d in ${PRUNE_DIRS}; do
    if [ -e "${TOOLKIT_ROOT}/${d}" ]; then
        rm -rf "${TOOLKIT_ROOT:?}/${d}"
        echo "[INFO] pruned: ${d}"
    fi
done

# ---------------------------------------------------------------------------
# 校验：裁剪后 set_env.sh 仍可 source、libascendcl.so 依赖完整；
#       若不满足则在此处立即失败并打印具体缺失库，避免产出不可用的镜像。
#       （set_env.sh 会追加未定义变量，故与 build_merge.sh 保持一致先初始化再 source）
# ---------------------------------------------------------------------------
set +eu
: "${LD_LIBRARY_PATH:=}"
: "${PYTHONPATH:=}"
: "${PATH:=}"
# shellcheck disable=SC1090
source /usr/local/Ascend/ascend-toolkit/set_env.sh
SETENV_RC=$?
set -eu
if [ "${SETENV_RC}" -ne 0 ]; then
    echo "[ERROR] CANN set_env.sh exited non-zero (${SETENV_RC}) after toolkit prune"
    exit 1
fi

export LD_LIBRARY_PATH="/usr/local/Ascend/driver/lib64:/usr/local/Ascend/driver/lib64/common:/usr/local/Ascend/driver/lib64/driver:${LD_LIBRARY_PATH:-}"
if ldd "${ASCENDCL_LIB}" 2>&1 | grep -q 'not found'; then
    echo "[ERROR] libascendcl.so has unresolved dependencies after toolkit prune:"
    ldd "${ASCENDCL_LIB}" | grep 'not found'
    exit 1
fi

echo "[INFO] CANN toolkit pruned & validated: $(du -sh /usr/local/Ascend/ascend-toolkit 2>/dev/null | cut -f1) (ascendcl OK)"

rm -rf Ascend-cann-toolkit_8.3.RC2_linux-aarch64.run CANN* Ascend*
