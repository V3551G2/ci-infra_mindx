set -eux
set -o pipefail
install_dir=/opt/buildtools/googletest-1.11.0
# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}
# check install files
wget --no-check-certificate https://github.com/google/googletest/archive/refs/tags/release-1.11.0.tar.gz
ls release-1.11.0.tar.gz

tar -xzf release-1.11.0.tar.gz -C ${install_dir}