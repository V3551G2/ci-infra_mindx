#!/bin/bash

set -eux
set -o pipefail
ln -sf /bin/bash /bin/sh
install_dir=/opt/buildtools/cmake-3.28.2
wget --no-check-certificate https://github.com/Kitware/CMake/archive/refs/tags/v3.28.2.tar.gz
# check install files
ls v3.28.2.tar.gz
# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}

tmp_cpus=$(grep -w processor /proc/cpuinfo|wc -l)

tar xzf v3.28.2.tar.gz
pushd CMake-3.28.2
./configure --prefix=${install_dir}
make -j ${tmp_cpus}
make install
popd
rm -rf CMake-3.28.2

#link
[ -e "/usr/local/bin/cmake" ] && rm -rf /usr/local/bin/cmake
ln -sf ${install_dir}/bin/* /usr/local/bin
chmod 777 /opt/buildtools -R