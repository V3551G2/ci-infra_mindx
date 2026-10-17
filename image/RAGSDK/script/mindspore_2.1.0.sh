#!/bin/bash

set -eux
set -o pipefail
install_dir=/opt/buildtools/mindspore-lite-2.1.0

case $(uname -m) in
  x86_64)
    MS_TARBALL=mindspore-lite-2.1.0-linux-x64.tar.gz
    MS_URL=https://ms-release.obs.cn-north-4.myhuaweicloud.com/2.1.0/MindSpore/lite/release/linux/x86_64/cloud_fusion/python37/${MS_TARBALL}
    ;;
  aarch64)
    MS_TARBALL=mindspore-lite-2.1.0-linux-aarch64.tar.gz
    MS_URL=https://ms-release.obs.cn-north-4.myhuaweicloud.com/2.1.0/MindSpore/lite/release/linux/aarch64/${MS_TARBALL}
    ;;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1;;
esac

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}
# check install files
wget --no-check-certificate ${MS_URL}
ls ${MS_TARBALL}

tar -xzf ${MS_TARBALL} -C ${install_dir}