#!/bin/bash

set -eux
set -o pipefail

case $(uname -m) in
  x86_64)  DEB_ARCH=amd64;;
  aarch64) DEB_ARCH=arm64;;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1;;
esac

install_dir=/opt/buildtools/obsutil

cd /opt/buildtools/
wget --no-check-certificate https://pytorch-package.obs.cn-north-4.myhuaweicloud.com/pta/tools/obsutil_linux_${DEB_ARCH}.tar.gz
ls obsutil_linux_${DEB_ARCH}.tar.gz

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
tar -zxvf obsutil_linux_${DEB_ARCH}.tar.gz
ls -al
cd  ./obsutil_linux_${DEB_ARCH}_*
! [[ -h ~/bin/obsutil ]] && ln -sf /opt/buildtools/obsutil_linux_${DEB_ARCH}_*/obsutil /usr/bin/obsutil
