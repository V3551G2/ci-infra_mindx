#!/bin/bash

set -eux
set -o pipefail
install_dir=/opt/buildtools/obsutil

cd /opt/buildtools/
wget -q --no-check-certificate https://pytorch-package.obs.cn-north-4.myhuaweicloud.com/pta/tools/obsutil_linux_arm64.tar.gz

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
tar -zxf obsutil_linux_arm64.tar.gz
cd  ./obsutil_linux_arm64_*
! [[ -h ~/bin/obsutil ]] && ln -sf /opt/buildtools/obsutil_linux_arm64_*/obsutil /usr/bin/obsutil
# 凭据不固化进镜像：obsutil config 由 CI（build.yml 的 AK_CI/SK_CI）在构建阶段注入