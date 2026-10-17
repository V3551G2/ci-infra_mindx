set -eux
set -o pipefail
install_dir=/opt/buildtools/ninja-1.12.0

# install files
wget --no-check-certificate https://github.com/ninja-build/ninja/archive/refs/tags/v1.12.0.tar.gz -O ninja-1.12.0.tar.gz
ls ninja-1.12.0.tar.gz

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}

tar xzf ninja-1.12.0.tar.gz -C ${install_dir}
cd ${install_dir}/ninja-1.12.0
sed -ie '1c#!/usr/bin/env python3' ./*.py
./configure.py --bootstrap
cp ninja /usr/local/bin
ldconfig