#!/usr/bin/bash
# Build RAGSDK CI Docker images.
#

set -ex

tag="${1:?Usage: $0 <TAG>}"
shift

supplement=""
case "$tag" in
  # 统一门禁镜像：UT_python + UT_faultdiag_python 共用同一镜像
  mindcluster-ut-python-x86_64)
    ARCH=x86_64
    supplement=_ut_python
    ;;
  # UT_cpp 门禁镜像：仅 ascend-docker-runtime cli 单测（C/C++ + cmake + lcov）
  mindcluster-ut_cpp-x86_64)
    ARCH=x86_64
    supplement=_ut_cpp
    ;;
  *)
    echo "Unknown tag: ${tag}"
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile${supplement}.${ARCH}"
echo "===DOCKERFILE: ${DOCKERFILE}"

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "Dockerfile not found: ${DOCKERFILE}"
  exit 1
fi

# BUILD_ARGS=(
#   --build-arg PYTORCH_VERSION="${PYTORCH_VERSION}"
# )
# if [[ -n "${CANN_CHIP:-}" ]]; then
#   BUILD_ARGS+=(--build-arg CANN_CHIP="${CANN_CHIP}")
# fi
# if [[ -n "${PYTHON_VERSION:-}" ]]; then
#   BUILD_ARGS+=(--build-arg PYTHON_VERSION="${PYTHON_VERSION}")
# fi

TIMESTAMP="${TIMESTAMP:-$(TZ=Asia/Shanghai date +%Y%m%d%H%M)}"
IMAGE_TAG="${tag}-${TIMESTAMP}"

echo "Building ${IMAGE_TAG} ..."
echo "  Dockerfile: ${DOCKERFILE}"
# echo "  PyTorch:    ${PYTORCH_VERSION}"
# echo "  Version:    ${VERSION_DIR}"
# [[ -n "${PYTHON_VERSION:-}" ]] && echo "  Python:     ${PYTHON_VERSION}"
# [[ -n "${CANN_CHIP:-}" ]] && echo "  CANN chip:  ${CANN_CHIP}"

docker build \
  -f "${DOCKERFILE}" \
  -t "${IMAGE_TAG}" \
  "${BUILD_ARGS[@]}" \
  "${SCRIPT_DIR}"

echo "Image built: ${IMAGE_TAG}"