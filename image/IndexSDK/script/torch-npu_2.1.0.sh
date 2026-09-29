set -e
set -o pipefail

wget https://gitee.com/ascend/pytorch/releases/download/v6.0.0.1-pytorch2.1.0/torch_npu-2.1.0.post11-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
ls torch_npu-2.1.0.post11-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

pip3.11 install torch==2.1.0 --index-url https://download.pytorch.org/whl/cpu

pip3.11 install torch_npu-2.1.0.post11-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl --no-deps
rm -rf torch*whl