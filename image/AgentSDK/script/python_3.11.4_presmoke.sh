#!/bin/bash
# =============================================================================
# Python 3.11.4 (slim) for AgentSDK PreSmoke task images.
#
# 与编译/UT 镜像共用的 python_3.11.4.sh 保持同一套「编译安装 + 环境注册」逻辑，
# 仅裁剪 Python 依赖：PreSmoke_aura 只做配置解析/CLI 校验类用例，不需要
# torch / torch-npu / transformers / scipy / vllm / MindSpeed 等运行时大包。
# 运行期由 presmoke/aura/presmoke.sh 自行 pip install mlflow 与 ray。
# =============================================================================

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
# 安装 Python 依赖（PreSmoke 真实依赖：pytest 系列 + PyYAML）
# =============================================================================

# ---- 1. 打包与构建工具 ----
pip3 install -q --upgrade pip
pip3 install -q wheel setuptools==70.3.0

# ---- 2. 单元测试框架（presmoke.sh 依赖预装的 pytest 系列）----
pip3 install -q pytest pytest-asyncio pytest-cov pytest-html pytest-mock coverage

# ---- 3. 配置解析依赖（aura/scripts/base/get_yaml.py 使用 yaml.safe_load）----
pip3 install -q pyyaml

# 仅打印已安装包数量（避免全量清单刷屏）
pip3 list --format=freeze | wc -l
