#!/bin/bash
# 编译安装 Python 3.9.11 并预装 UT 运行所需 pip 依赖。
# 使用方：mind-cluster 的 UT_python / UT_mindio_cpp 门禁。
# 说明：
#   - 版本固定 3.9.11：执行脚本硬编码 /opt/buildtools/python-3.9.11。
#   - torch==2.1.0 / grpcio / protobuf 为 taskd 与 mindio 用例的真实依赖。
#   - SWIG 由 Dockerfile 通过 pip 安装（此处不处理，保持脚本职责单一）。
set -eux
set -o pipefail

install_dir=/opt/buildtools/python-3.9.11

cd /opt/buildtools/
wget --no-check-certificate https://repo.huaweicloud.com/python/3.9.11/Python-3.9.11.tgz
ls Python-3.9.11.tgz

tmp_cpus=$(grep -w processor /proc/cpuinfo | wc -l)

[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}

tar -xf Python-3.9.11.tgz
cd Python-3.9.11/
./configure --prefix=${install_dir}
make -j ${tmp_cpus}
make install

# 环境变量（供登录 shell 使用；构建期不 source，避免 set -u 下的意外退出）
sed -i '/PYTHON_HOME/d' /etc/profile
echo "export PYTHON_HOME=${install_dir}" >> /etc/profile
echo "export PATH=\$PYTHON_HOME/bin:\$PATH" >> /etc/profile

# 头部软链接（pip 安装产生的 console 脚本在末尾统一再链一次）
ln -sf ${install_dir}/bin/* /usr/local/bin
ln -sf ${install_dir}/bin/python3 /usr/local/bin/python3
ln -sf ${install_dir}/bin/python3.9 /usr/local/bin/python3.9
ln -sf ${install_dir}/bin/python3.9 /usr/local/bin/python3.9.11
ln -sf ${install_dir}/bin/pip3.9 /usr/local/bin/pip3
ln -sf ${install_dir}/bin/pip3.9 /usr/local/bin/pip3.9
ln -sf ${install_dir}/bin/pip3.9 /usr/local/bin/pip3.9.11
ldconfig

# 运行库软链接（部分组件按 /lib、/lib64 查找 libpython）
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.9.so /lib/libpython3.9.so
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.9.so.1.0 /lib/libpython3.9.so.1.0
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.so /lib/libpython3.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.so /lib64/libpython3.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.9.so /lib64/libpython3.9.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.9.so.1.0 /lib64/libpython3.9.so.1.0
ln -sf ${install_dir}/include/python3.9/* /usr/local/include/

# pip 国内源
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
EOF

# 预装 UT 依赖（去重后的一站式安装，--no-cache-dir 避免缓存膨胀）
# torch 单独用 CPU 源安装：默认 PyPI 的 torch==2.1.0 会连带约 2.6GB CUDA 依赖
# （nvidia-cudnn/cublas/nccl/... + triton），导致镜像过大、跨境推送 SWR 超时；
# UT 为 CPU 测试，无需 CUDA。
pip3 install --no-cache-dir \
    setuptools wheel \
    requests pyyaml faker tox asynctest \
    pytest pytest-html pytest-asyncio pytest-cov pytest-mock coverage pyfakefs hypothesis \
    "grpcio>=1.62.2" pyOpenSSL "protobuf>=4.24.4"
pip3 install --no-cache-dir torch==2.1.0+cpu --index-url https://download.pytorch.org/whl/cpu

# 末尾再链一次，暴露 pip 安装产生的 console 脚本（如 pytest/coverage）
ln -sf ${install_dir}/bin/* /usr/local/bin
