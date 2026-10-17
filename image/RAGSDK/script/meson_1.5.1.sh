set -eux
set -o pipefail

install_dir=/opt/buildtools/meson

[ -z "${install_dir}" ] && install_dir=/opt/buildtools/meson-1.5.1

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}

# check install files
wget https://github.com/mesonbuild/meson/releases//download/1.5.1/meson-1.5.1.tar.gz
ls meson-1.5.1.tar.gz
# check dependence
pip3 install -q setuptools
python_dir=$(which python3.11|xargs ls -l|awk '{print $NF}'|sed 's/python3.11$//g')
pip3 install -q meson-1.5.1.tar.gz
cp ${python_dir}/meson /usr/bin