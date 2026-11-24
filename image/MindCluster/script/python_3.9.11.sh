#!/bin/bash
# 门禁镜像（mindcluster-ut-mindio-cpp-x86_64）的 Python 3.9.11 安装脚本。
#
# 说明：UT_mindio_cpp 的执行入口 ut_mindio_cpp_execute.sh 硬编码
#       PYTHON_HOME=/opt/buildtools/python-3.9.11，故安装路径不可更改；
#       该脚本还会用 `python3 setup.py bdist_wheel` 生成 acp/tft 的 whl，
#       并要求 CMake 的 find_package(Python3 COMPONENTS Development) 可用，
#       因此这里用 --enable-shared 生成 libpython3.9.so 并导出头文件。
set -eu
set -o pipefail

install_dir=/opt/buildtools/python-3.9.11
tmp_cpus=$(grep -w processor /proc/cpuinfo | wc -l)

cd /opt/buildtools

# 下载源码（wget 已在 /root/.wgetrc 全局静默，仅保留错误输出）
wget --no-check-certificate https://repo.huaweicloud.com/python/3.9.11/Python-3.9.11.tgz
ls Python-3.9.11.tgz

[ -d "${install_dir}" ] && rm -rf "${install_dir}"
mkdir -p "${install_dir}"
tar -xf Python-3.9.11.tgz

# 全核并行编译安装（原脚本的 make clean 会触发重复编译，已去除）
cd Python-3.9.11
./configure --prefix=${install_dir} --enable-shared --with-ensurepip=install
make -j "${tmp_cpus}"
make install
cd ..

# 环境变量与软链，统一指向自编译的 Python 3.9.11
echo "export PYTHON_HOME=${install_dir}" >> /etc/profile
echo 'export PATH=$PYTHON_HOME/bin:$PATH' >> /etc/profile
ln -sf ${install_dir}/bin/* /usr/local/bin
ln -sf ${install_dir}/bin/python3 /usr/local/bin/python3
ln -sf ${install_dir}/bin/python3.9 /usr/local/bin/python3.9
ln -sf ${install_dir}/bin/pip3.9 /usr/local/bin/pip3
ln -sf ${install_dir}/bin/pip3.9 /usr/local/bin/pip3.9
ln -sf ${install_dir}/include/python3.9/* /usr/local/include/

# 导出共享库，供 find_package(Python3 ... Development) 与运行期加载使用
ln -sf ${install_dir}/lib/libpython3.9.so.1.0 /usr/lib/libpython3.9.so.1.0
ln -sf ${install_dir}/lib/libpython3.9.so /usr/lib/libpython3.9.so
ln -sf ${install_dir}/lib/libpython3.so /usr/lib/libpython3.so
ldconfig

# pip 配置：华为镜像源 + 关闭版本检查，减少输出
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'EOF'
[global]
index-url = https://repo.huaweicloud.com/repository/pypi/simple
trusted-host = repo.huaweicloud.com
timeout = 120
disable-pip-version-check = true
EOF

python3 --version
pip3 --version
