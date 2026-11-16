#!/bin/bash

set -eux
set -o pipefail

install_dir=/opt/buildtools/python-3.11.4

# ---- 下载源码 ----
wget --no-check-certificate https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz
ls Python-3.11.4.tgz

# ---- 编译安装 ----
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}
tar -xf Python-3.11.4.tgz
cd Python-3.11.4/
./configure --prefix=${install_dir} --enable-shared --disable-test-modules
make -j "$(grep -w processor /proc/cpuinfo | wc -l)"
make install

# ---- 精简产物：删除测试套件、无用标准库模块与静态库 ----
rm -rf ${install_dir}/lib/python3.11/test \
       ${install_dir}/lib/python3.11/lib2to3 \
       ${install_dir}/lib/python3.11/idlelib \
       ${install_dir}/lib/python3.11/tkinter \
       ${install_dir}/lib/python3.11/turtledemo
find ${install_dir} -name 'libpython3.11.a' -delete

# ---- 注册环境变量与软链 ----
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

# ---- pip 源（国内镜像 + 关闭版本检查提示）----
mkdir -p ~/.pip
cat << EOF > ~/.pip/pip.conf
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
disable-pip-version-check = true
EOF

# =============================================================================
# 安装 Python 依赖（统一 -q 静默，按用途分组）
# =============================================================================

# ---- 1. 打包与构建工具 ----
pip3 install -q --upgrade pip
pip3 install -q wheel setuptools==70.3.0

# ---- 2. 单元测试框架（aura_ut.sh / openclaw_ut.sh 依赖预装的 pytest 系列）----
pip3 install -q pytest pytest-asyncio pytest-cov pytest-html pytest-mock coverage \
                pyfakefs faker tox asynctest hypothesis html-testRunner xmlrunner

# ---- 3. 通用工具库 ----
pip3 install -q numpy psutil pyyaml requests urllib3==1.26.5 regex attrs decorator \
                sympy scipy jinja2 pydot GitPython py-cpuinfo==9.0.0 \
                prometheus_client==0.23.1 partial_json_parser==0.2.1.1.post6

# ---- 4. AgentSDK 运行时依赖 ----
pip3 install -q torch==2.6.0 transformers sentence-transformers pylatexenc openai \
                hydra-core tensordict word2number codetiming \
                'grpcio>=1.62.2' pyOpenSSL 'protobuf>=4.24.4' \
                pyzmq==27.1.0 starlette==0.48.0 msgspec==0.19.0 blake3==1.0.8 \
                fastapi==0.119.0 aiohttp==3.13.0 gguf==0.17.1

# 仅打印已安装包数量（避免全量清单刷屏）
pip3 list --format=freeze | wc -l
