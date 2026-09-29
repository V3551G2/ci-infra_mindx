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
EOF
pip3 install pytest
pip3 install pytest-html
pip3 install coverage
pip3 install pyfakefs
pip3 install pyyaml
pip3 install faker
pip3 install tox
pip3 install asynctest
pip3 install pytest
pip3 install pytest-asyncio
pip3 install pytest-html
pip3 install pytest-cov
pip3 install pytest-mock
pip3 install hypothesis
pip3 install grpcio>=1.62.2
pip3 install pyOpenSSL
pip3 install protobuf>=4.24.4
pip3 install transformers
pip3 install pylatexenc
pip3 install openai
pip3 install sentence-transformers
pip3 install hydra-core
pip3 install tensordict
pip3 install word2number
pip3 install codetiming

# 安装python第三方库
pip3 install coverage
pip3 install regex
pip3 install html-testRunner
pip3 install xmlrunner
pip3 install requests
pip3 install pyinstaller==4.0

pip3.11 install --upgrade pip
pip3 install coverage
pip3 install regex
pip3 install pyyaml
pip3 install html-testRunner
pip3 install xmlrunner
pip3 install pipenv
pip3 install requests
pip3 install wheel
pip3 install setuptools==70.3.0
pip3 install numpy==1.26.4
pip3 install psutil
pip3 install jinja2
pip3 install pydot
pip3 install GitPython
pip3 install urllib3==1.26.5

pip3 install decorator
pip3 install sympy
pip3 install scipy
pip3 install attrs
pip3 install opencv-python
pip3 list

pip3 install pandas==1.5.3
pip3 install ply==3.11
pip3 install joblib==1.4.2

# AgentSDK
pip3 install pyzmq==27.1.0
pip3 install starlette==0.48.0
pip3 install msgspec==0.19.0
pip3 install blake3==1.0.8
pip3 install fastapi==0.119.0
pip3 install aiohttp==3.13.0
pip3 install py-cpuinfo==9.0.0
pip3 install partial_json_parser==0.2.1.1.post6
pip3 install prometheus_client==0.23.1
pip3 install gguf==0.17.1