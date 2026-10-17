#!/bin/bash

set -eux
set -o pipefail
install_dir=/opt/buildtools/go_1.22.1

case $(uname -m) in
  x86_64)  GO_ARCH=amd64;;
  aarch64) GO_ARCH=arm64;;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1;;
esac

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}

#install go
cd /opt/buildtools/
wget --no-check-certificate https://golang.google.cn/dl/go1.22.1.linux-${GO_ARCH}.tar.gz
# check install files
ls go1.22.1.linux-${GO_ARCH}.tar.gz
tar xzf go1.22.1.linux-${GO_ARCH}.tar.gz
cp -rf go/* ${install_dir}
rm -rf go/
#link
ln -sf ${install_dir}/bin/* /usr/local/bin

#check version
go_version=$(go version|grep go1.22.1)
if [ -z "${go_version}" ];then
	echo "ERROR <Failed to install the go tool>."
	exit 1
else
	echo "Info <The go tool is successfully installed>."
	echo "Info <go information is : ${go_version}>."
fi

echo "export GOROOT=${install_dir}" >> /etc/profile
echo "export GO111MODULE='auto'" >> /etc/profile
echo "export GOPROXY=https://goproxy.cn,direct" >>/etc/profile
echo 'export GONOSUMDB=*' >>/etc/profile