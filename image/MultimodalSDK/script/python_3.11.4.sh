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
./configure --prefix=${install_dir} --enable-shared --disable-test-modules
make clean || make distclean
make -j ${tmp_cpus}
make install
# 精简产物：删除测试套件、静态库及无关标准库模块
rm -rf ${install_dir}/lib/python3.11/test \
       ${install_dir}/lib/python3.11/lib2to3 \
       ${install_dir}/lib/python3.11/idlelib \
       ${install_dir}/lib/python3.11/tkinter \
       ${install_dir}/lib/python3.11/turtledemo
find ${install_dir} -name 'libpython3.11.a' -delete
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
# 构建/打包工具
pip3 install -q --upgrade pip
pip3 install -q wheel setuptools==70.3.0

# 对齐 build_script/build.sh 与源码 import：
#   torch-npu/torch/torchvision/transformers/pillow/numpy/einops/opencv-python
# 版本与门禁实跑一致（MultimodalSDK/build_script/build.sh 安装 torch-npu==2.9.1，
# test 阶段安装 torchvision==0.24.1），避免镜像预装版本在运行时被 pip 覆盖。
pip3 install -q numpy pillow==11.2.1 einops opencv-python
pip3 install -q "transformers==4.51.3"
pip3 install -q torch-npu==2.9.1
pip3 install -q torchvision==0.24.1

# 测试与覆盖率（build.sh 测试阶段：coverage/pytest/pytest-cov/pytest-html）
pip3 install -q pytest pytest-cov pytest-html coverage

pip3 list --format=freeze | wc -l