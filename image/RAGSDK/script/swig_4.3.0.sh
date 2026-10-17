#!/bin/bash

set -eux
set -o pipefail
install_dir=/opt/buildtools/swig-4.3.0

cd /opt/buildtools/
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xzf bison-3.8.2.tar.gz
cd bison-3.8.2
./configure --prefix=/usr/local
make -j$(nproc)
sudo make install
cd /opt/buildtools/
rm -rf bison-3.8.2 bison-3.8.2.tar.gz

cd /opt/buildtools/
wget --no-check-certificate https://github.com/swig/swig/archive/refs/tags/v4.3.0.tar.gz -O swig-4.3.0.tar.gz
# check install files
ls swig-4.3.0.tar.gz

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
# mkdir -p ${install_dir}
tar -xzf swig-4.3.0.tar.gz
ls -al ./
cd ${install_dir}
./autogen.sh
./configure
make -j50
make install

if [ -d "/usr/bin/" ];then
    ln -s ${install_dir}/* /usr/bin/
fi
cd /opt/buildtools/
rm -f swig-4.3.0.tar.gz
