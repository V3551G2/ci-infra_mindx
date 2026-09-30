#!/bin/bash
set -eu
set -o pipefail

case $(uname -m) in
  x86_64)  HDK_ARCH=x86-64;;
  aarch64) HDK_ARCH=aarch64;;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1;;
esac

useradd HwHiAiUser
wget --no-check-certificate https://ascend-repo.obs.cn-east-2.myhuaweicloud.com/Ascend%20HDK/Ascend%20HDK%2025.3.RC1/Ascend-hdk-310p-npu-driver_25.3.rc1_linux-${HDK_ARCH}.run
ls Ascend-hdk-310p-npu-driver_25.3.rc1_linux-${HDK_ARCH}.run
chmod +x *.run
echo y |./Ascend-hdk-310p-npu-driver_25.3.rc1_linux-${HDK_ARCH}.run --noexec --extract=/usr/local/Ascend/
cp -rf /usr/local/Ascend/driver/lib64/libdcmi.so /usr/local/Ascend/driver/lib64/driver
chmod +666 /usr/local/Ascend/driver/lib64/driver -R
echo 'export LD_LIBRARY_PATH=/usr/local/Ascend/driver/lib64:/usr/local/Ascend/driver/lib64/common:/usr/local/Ascend/driver/lib64/driver:$LD_LIBRARY_PATH' >> /etc/profile
ls -l /usr/local/Ascend

echo "Version=25.3.rc1
ascendhal_version=7.35.23
aicpu_version=1.0
tdt_version=1.0
log_version=1.0
prof_version=2.0
dvppkernels_version=1.1
tsfw_version=1.0
Innerversion=V100R001C23SPC002B212
compatible_version=[V100R001C19],[V100R001C20],[V100R001C21],[V100R001C22],[V100R001C23]
compatible_version_fw=[6.4.0,6.4.99],[7.0.0,8.9.9]
package_version=25.3.rc1" > /usr/local/Ascend/driver/version.info
rm -rf Ascend*