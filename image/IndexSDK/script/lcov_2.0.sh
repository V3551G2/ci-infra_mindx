set -eux
set -o pipefail

# lcov 2.0 运行依赖的 perl 模块（与 IndexSDK build/install_deps.sh 安装 lcov 前保持一致，
# 缺模块会导致 lcov --version 报错，进而 install_deps.sh 判为"未安装"又重新下载 github 版）
apt-get update
apt-get install -y libcapture-tiny-perl libdatetime-perl libtimedate-perl

install_dir=/opt/buildtools/lcov

[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir} && cd ${install_dir}

# 走 gitcode mirror，规避 github 跨境下载 503（install_deps.sh 的跳过条件是 lcov --version 含 "2.0"）
git clone https://gitcode.com/gh_mirrors/lc/lcov.git
cd lcov
git checkout v2.0
make install PREFIX=/usr/local
lcov --version
export PATH=/usr/local/bin:$PATH