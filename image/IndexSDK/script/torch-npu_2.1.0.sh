set -e
set -o pipefail

case $(uname -m) in
  x86_64)  WHEEL_ARCH=x86_64;;
  aarch64) WHEEL_ARCH=aarch64;;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1;;
esac

WHEEL=torch_npu-2.1.0.post11-cp311-cp311-manylinux_2_17_${WHEEL_ARCH}.manylinux2014_${WHEEL_ARCH}.whl
wget https://gitee.com/ascend/pytorch/releases/download/v6.0.0.1-pytorch2.1.0/${WHEEL}
ls ${WHEEL}

if [ "${WHEEL_ARCH}" = "x86_64" ]; then
  # x86_64 平台 PyPI 默认 torch 为 CUDA 版，需先装 CPU 版再 --no-deps 安装 torch_npu
  pip3.11 install -q torch==2.1.0 --index-url https://download.pytorch.org/whl/cpu
  pip3.11 install -q ${WHEEL} --no-deps
else
  # aarch64 平台 PyPI torch 即为 CPU 版，torch_npu 直接按依赖安装
  pip3.11 install -q ${WHEEL}
fi
rm -rf torch*whl