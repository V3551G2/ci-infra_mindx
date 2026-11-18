set -e
set -o pipefail
 
wget https://gitee.com/ascend/pytorch/releases/download/v6.0.0.1-pytorch2.1.0/torch_npu-2.1.0.post11-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
ls torch_npu-2.1.0.post11-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
 
pip3.11 install torch_npu-2.1.0.post11-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
rm -rf torch*whl