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

# 优先使用原始 GitHub 下载链接
DOWNLOAD_URL="https://github.com/llvm/llvm-project/releases/download/${LLVM_TAG}/${PKG_NAME}"
# 备用：内网 OBS 链接（GitHub 下载失败/过慢时替换为下行）
# DOWNLOAD_URL="https://mindcluster.obs.cn-north-4.myhuaweicloud.com/blueImageDependency/clang-tidy/${LLVM_VERSION}/${PKG_NAME}"

# 带重试的稳健下载（应对跨境网络抖动）
wget --tries=3 --timeout=30 --waitretry=10 "${DOWNLOAD_URL}"

# 解压并合并到 /usr/local：bin 落到 /usr/local/bin（默认已在 PATH），即刻全局可用
tar -Jxf "${PKG_NAME}" --strip-components=1 -C /usr/local
rm -f "${PKG_NAME}"

# 验证
clang --version
clang-tidy --version