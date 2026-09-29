#!/bin/bash

set -eux
set -o pipefail
install_dir=/opt/buildtools/obsutil

cd /opt/buildtools/
wget --no-check-certificate https://pytorch-package.obs.cn-north-4.myhuaweicloud.com/pta/tools/obsutil_linux_amd64.tar.gz
ls obsutil_linux_amd64.tar.gz

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
tar -zxvf obsutil_linux_amd64.tar.gz
ls -al
cd  ./obsutil_linux_amd64_*
! [[ -h ~/bin/obsutil ]] && ln -sf /opt/buildtools/obsutil_linux_amd64_*/obsutil /usr/bin/obsutil
