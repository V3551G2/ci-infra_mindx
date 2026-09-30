set -eux
set -o pipefail

LLVM_VERSION="22.1.8"
LLVM_TAG="llvmorg-${LLVM_VERSION}"

# 根据架构选择官方预编译包（x86_64 / aarch64）
case $(uname -m) in
  x86_64)  PKG_NAME="LLVM-${LLVM_VERSION}-Linux-X64.tar.xz";;
  aarch64) PKG_NAME="LLVM-${LLVM_VERSION}-Linux-ARM64.tar.xz";;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1;;
esac

# 主用：内网 OBS 高速稳定链接（GitHub 跨境下载易挂起，改走内网源）
DOWNLOAD_URL="https://mindcluster.obs.cn-north-4.myhuaweicloud.com/blueImageDependency/clang-tidy/${LLVM_VERSION}/${PKG_NAME}"
# 备用：GitHub 官方 release（OBS 不可用时替换为下行）
# DOWNLOAD_URL="https://github.com/llvm/llvm-project/releases/download/${LLVM_TAG}/${PKG_NAME}"

# 带重试的稳健下载（全局 wgetrc 已设 quiet=on 静默；--read-timeout 防连接僵死）
wget --tries=5 --timeout=60 --read-timeout=60 --waitretry=10 "${DOWNLOAD_URL}"

# 解压并合并到 /usr/local：bin 落到 /usr/local/bin（默认已在 PATH），即刻全局可用
tar -Jxf "${PKG_NAME}" --strip-components=1 -C /usr/local
rm -f "${PKG_NAME}"

# 验证
clang --version
clang-tidy --version