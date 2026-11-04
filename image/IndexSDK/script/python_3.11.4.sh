#!/bin/bash

set -eux
install_dir=/opt/buildtools/python-3.11.4
wget --no-check-certificate https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz
tmp_cpus=$(grep -w processor /proc/cpuinfo|wc -l)
pypi="--trusted-host repo.huaweicloud.com -i https://repo.huaweicloud.com/repository/pypi/simple"
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

# 安装构建工具
pip3 install -q --upgrade pip
pip3 install -q wheel setuptools==70.3.0

# 对齐源码仓 requirement.txt（numpy/decorator/sympy/pyyaml/protobuf/scipy/requests/attrs/psutil）
# + 源码实际 import 的 joblib（feature_retrieval/.../graph_build.py）
pip3 install -q pyyaml
pip3 install -q protobuf>=4.24.4
pip3 install -q requests
pip3 install -q numpy==1.26.4
pip3 install -q psutil
pip3 install -q decorator
pip3 install -q sympy
pip3 install -q scipy
pip3 install -q attrs
pip3 install -q joblib==1.4.2

pip3 list --format=freeze | wc -l