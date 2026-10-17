set -eux
set -o pipefail
install_dir=/opt/buildtools/mockcpp
# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}
# check install files
wget --no-check-certificate https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mockcpp/mockcpp-2.6.tar.gz
ls mockcpp-2.6.tar.gz

tar -xzf mockcpp-2.6.tar.gz -C ${install_dir}