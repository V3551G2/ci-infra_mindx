set -eux
set -o pipefail

install_dir=/opt/buildtools/lcov

[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir} && cd ${install_dir}

git clone -q https://gitcode.com/gh_mirrors/lc/lcov.git
cd lcov
git checkout -q v2.1
sudo make install PREFIX=/usr/local
lcov --version