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

# 解压到临时目录，裁剪后再合并到 /usr/local
mkdir -p /tmp/llvm-staging
tar -Jxf "${PKG_NAME}" --strip-components=1 -C /tmp/llvm-staging
rm -f "${PKG_NAME}"

# ===== 精简：clang-tidy 静态检查只需 clang 前端 + 动态库 + clang 资源头文件 =====
# 官方 clang-tidy 为动态链接，运行时仅需 .so，静态库（体积最大）可删
rm -rf /tmp/llvm-staging/lib/*.a
# C++ 开发头文件（仅编译期需要，clang-tidy 运行时不依赖）
rm -rf /tmp/llvm-staging/include
# 文档 / man
rm -rf /tmp/llvm-staging/share
# CMake 构建配置
rm -rf /tmp/llvm-staging/lib/cmake
# 命令行工具只保留 clang / clang++ / clang-tidy
for f in /tmp/llvm-staging/bin/*; do
  case "$(basename "$f")" in
    clang|clang++|clang-tidy) ;;
    *) rm -rf "$f" ;;
  esac
done

# 合并到 /usr/local（保留 lib/clang/22/include 内置头文件，检查代码必需）
cp -a /tmp/llvm-staging/. /usr/local/
rm -rf /tmp/llvm-staging

# 验证
clang --version
clang-tidy --version