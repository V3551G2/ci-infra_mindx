#!/bin/bash
set -eu
set -o pipefail

install_dir=/opt/buildtools/python-3.11.4

# 下载并解压 Python 源码
wget --no-check-certificate https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz
ls Python-3.11.4.tgz

[ -d "${install_dir}" ] && rm -rf "${install_dir}"
mkdir -p "${install_dir}"
tar -xf Python-3.11.4.tgz

# 全核并行编译安装（去掉原 make clean，避免重复编译）
tmp_cpus=$(grep -w processor /proc/cpuinfo | wc -l)
cd Python-3.11.4/
./configure --prefix=${install_dir} --enable-shared
make -j "${tmp_cpus}"
make install
cd ..

# 环境变量与软链，统一指向自编译的 Python 3.11.4
echo "export PYTHON_HOME=${install_dir}" >> /etc/profile
echo 'export PATH=$PYTHON_HOME/bin:$PATH' >> /etc/profile
ln -sf ${install_dir}/bin/* /usr/local/bin
ln -sf ${install_dir}/bin/python3 /usr/local/bin/python3
ln -sf ${install_dir}/bin/python3.11 /usr/local/bin/python3.11
ln -sf ${install_dir}/bin/pip3.11 /usr/local/bin/pip3
ln -sf ${install_dir}/bin/pip3.11 /usr/local/bin/pip3.11
ln -sf ${install_dir}/include/python3.11/* /usr/local/include/
ldconfig
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.11.so /lib/libpython3.11.so
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.11.so.1.0 /lib/libpython3.11.so.1.0
[ -d "/usr/lib" ] && ln -sf ${install_dir}/lib/libpython3.so /lib/libpython3.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.so /lib64/libpython3.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.11.so /lib64/libpython3.11.so
[ -d "/usr/lib64" ] && ln -sf ${install_dir}/lib/libpython3.11.so.1.0 /lib64/libpython3.11.so.1.0

# pip 配置：华为镜像源 + 关闭版本检查，减少输出
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'EOF'
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
disable-pip-version-check = true
EOF

pip3.11 install -q --upgrade pip

# 打包工具：setup_linux.py develop / bdist_wheel 依赖
pip3 install -q wheel
pip3 install -q setuptools==70.3.0

# faultdiag 运行时/构建依赖（src/requirements.txt + build）
pip3 install -q numpy==1.26.4 pandas scikit-learn joblib ply

# faultdiag 测试框架（test/requirements.txt + run_dt.sh）
pip3 install -q pytest pytest-cov pytest-mock pytest-html coverage mock pexpect virtualenv

# faultdiag 诊断/清洗运行依赖（UT 执行脚本 + .devcontainer）
pip3 install -q openpyxl paramiko scp cryptography grpcio protobuf pyOpenSSL requests