#!/bin/bash

set -eux
install_dir=/opt/buildtools/python-3.11.4
wget --no-check-certificate https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz
tmp_cpus=$(grep -w processor /proc/cpuinfo|wc -l)
ls Python-3.11.4.tgz
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}
tar -xf Python-3.11.4.tgz
cd Python-3.11.4/
./configure --prefix=${install_dir} --enable-shared
make -j ${tmp_cpus}
make clean
make install
sed -i '/PYTHON_HOME/d' /etc/profile
echo "export PYTHON_HOME=${install_dir}" >> /etc/profile
source /etc/profile
echo "export PATH=\$PYTHON_HOME/bin:\$PATH" >> /etc/profile
ln -sf ${install_dir}/bin/* /usr/local/bin
ln -sf ${install_dir}/bin/python3 /usr/local/bin/python3
ln -sf ${install_dir}/bin/python3.11 /usr/local/bin/python3.11
ln -sf ${install_dir}/bin/python3.11 /usr/local/bin/python3.11.4
ln -sf ${install_dir}/bin/pip3.11 /usr/local/bin/pip3
ln -sf ${install_dir}/bin/pip3.11 /usr/local/bin/pip3.11
ln -sf ${install_dir}/bin/pip3.11 /usr/local/bin/pip3.11.4
ldconfig
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.11.so /lib/libpython3.11.so
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.11.so.1.0 /lib/libpython3.11.so.1.0
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.so /lib/libpython3.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.so /lib64/libpython3.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.11.so /lib64/libpython3.11.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.11.so.1.0 /lib64/libpython3.11.so.1.0
ln -sf ${install_dir}/include/python3.11/* /usr/local/include/
mkdir -p ~/.pip
touch ~/.pip/pip.conf
cat << EOF >> ~/.pip/pip.conf
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
disable-pip-version-check = true
EOF

# 测试/构建基础依赖
pip3 install -q pytest
pip3 install -q pytest-html
pip3 install -q coverage
pip3 install -q pyfakefs
pip3 install -q pyyaml
pip3 install -q faker
pip3 install -q tox
pip3 install -q asynctest
pip3 install -q pytest-asyncio
pip3 install -q pytest-cov
pip3 install -q pytest-mock
pip3 install -q hypothesis

# 关键：先装 CPU 版 torch，避免后续 transformers/sentence-transformers 拖入 CUDA 版 torch（GB 级）
case $(uname -m) in
  x86_64)
    # x86_64 平台 PyPI 默认 torch 为 CUDA 版，需显式指定 CPU 源
    pip3 install -q torch==2.1.0 --index-url https://download.pytorch.org/whl/cpu
    ;;
  aarch64)
    # aarch64 平台 PyPI torch 即 CPU 版，直接按固定版本安装
    pip3 install -q torch==2.1.0
    ;;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1;;
esac

pip3 install -q grpcio>=1.62.2
pip3 install -q pyOpenSSL
pip3 install -q protobuf>=4.24.4
pip3 install -q transformers
pip3 install -q pylatexenc
pip3 install -q openai
pip3 install -q sentence-transformers
pip3 install -q hydra-core
pip3 install -q tensordict
pip3 install -q word2number
pip3 install -q codetiming

# 安装 python 第三方库（去重合并）
pip3 install -q regex
pip3 install -q html-testRunner
pip3 install -q xmlrunner
pip3 install -q requests
pip3 install -q pyinstaller==4.0

pip3.11 install -q --upgrade pip
pip3 install -q pipenv
pip3 install -q wheel
pip3 install -q setuptools==70.3.0
pip3 install -q numpy==1.26.4
pip3 install -q psutil
pip3 install -q jinja2
pip3 install -q pydot
pip3 install -q GitPython
pip3 install -q urllib3==1.26.5

pip3 install -q decorator
pip3 install -q sympy
pip3 install -q scipy
pip3 install -q attrs
pip3 list --format=freeze | wc -l

# AgentSDK / LLM 相关依赖（RAGSDK 与 AgentSDK 共用镜像）
pip3 install -q pyzmq==27.1.0
pip3 install -q starlette==0.48.0
pip3 install -q msgspec==0.19.0
pip3 install -q blake3==1.0.8
pip3 install -q fastapi==0.119.0
pip3 install -q aiohttp==3.13.0
pip3 install -q py-cpuinfo==9.0.0
pip3 install -q partial_json_parser==0.2.1.1.post6
pip3 install -q prometheus_client==0.23.1
pip3 install -q gguf==0.17.1