#!/bin/bash
set -eu
set -o pipefail

install_dir=/opt/buildtools/obsutil
cd /opt/buildtools/

wget --no-check-certificate https://pytorch-package.obs.cn-north-4.myhuaweicloud.com/pta/tools/obsutil_linux_amd64.tar.gz
ls obsutil_linux_amd64.tar.gz

[ -d "${install_dir}" ] && rm -rf "${install_dir}"
tar -zxf obsutil_linux_amd64.tar.gz

cd ./obsutil_linux_amd64_*/
ln -sf /opt/buildtools/obsutil_linux_amd64_*/obsutil /usr/bin/obsutil