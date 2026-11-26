#!/usr/bin/bash
# Build MultimodalSDK CI Docker images.
#

set -ex

tag="${1:?Usage: $0 <TAG>}"
shift

supplement=""
case "$tag" in
  multimodalsdk-aarch64)
    ARCH=aarch64
    ;;
  multimodalsdk-presmoke-aarch64)
    ARCH=aarch64
    supplement=_presmoke
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

print_image_size() {
  local img="$1" label="$2"
  local bytes
  bytes="$(docker image inspect -f '{{.Size}}' "${img}")"
  echo "${label}: $(awk -v b="${bytes}" 'BEGIN{printf "%.2f GB (%d bytes)", b/1024/1024/1024, b}')"
}

# 压平(squash)镜像：把多层合并为一层，使 Dockerfile 中 rm 掉的基础镜像文件真正从体积中消失。
# 背景：CANN 基础镜像的 /usr/local/Ascend 是一整层(10.6GB) COPY，单阶段 Dockerfile 里删除
# 其子目录只会新增白化条目、不会减小 `docker images` 体积；export|import 之后文件系统只保留
# 真实文件。为避免影响 build/UT 用的基础镜像，本步骤仅对 presmoke 生效。
squash_image() {
  local src="$1"
  local cname="squash_${src//[^A-Za-z0-9_.-]/_}_$$"
  local -a changes=()
  local e wd cmd ep user platform

  # 原样保留镜像配置（ENV/CMD/ENTRYPOINT/WORKDIR/USER），import 会丢失这些配置
  while IFS= read -r e; do
    if [[ -n "${e}" ]]; then
      changes+=(--change "ENV ${e}")
    fi
  done < <(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "${src}")
  wd="$(docker inspect -f '{{.Config.WorkingDir}}' "${src}")"
  cmd="$(docker inspect -f '{{json .Config.Cmd}}' "${src}")"
  ep="$(docker inspect -f '{{json .Config.Entrypoint}}' "${src}")"
  user="$(docker inspect -f '{{.Config.User}}' "${src}")"
  platform="$(docker inspect -f '{{.Os}}/{{.Architecture}}' "${src}")"
  if [[ -n "${wd}" ]]; then changes+=(--change "WORKDIR ${wd}"); fi
  if [[ -n "${cmd}" && "${cmd}" != "null" ]]; then changes+=(--change "CMD ${cmd}"); fi
  if [[ -n "${ep}" && "${ep}" != "null" ]]; then changes+=(--change "ENTRYPOINT ${ep}"); fi
  if [[ -n "${user}" ]]; then changes+=(--change "USER ${user}"); fi

  docker rm -f "${cname}" >/dev/null 2>&1 || true
  docker create --name "${cname}" "${src}" >/dev/null
  docker export "${cname}" | docker import \
    --platform "${platform}" \
    "${changes[@]}" \
    - "${src}:squashed"
  docker rm -f "${cname}" >/dev/null
  docker tag "${src}:squashed" "${src}"
  docker rmi "${src}:squashed" >/dev/null 2>&1 || true
}

# 释放构建缓存，避免压平时磁盘空间不足（需同时容纳 旧镜像 + 压平后的新镜像）
docker builder prune -af >/dev/null 2>&1 || true
df -h / || true

docker build \
  -f "${DOCKERFILE}" \
  -t "${IMAGE_TAG}" \
  "${BUILD_ARGS[@]}" \
  "${SCRIPT_DIR}"

echo "Image built: ${IMAGE_TAG}"
print_image_size "${IMAGE_TAG}" "Image size (before squash)"

if [[ "${supplement}" == "_presmoke" ]]; then
  echo "Squashing ${IMAGE_TAG} ..."
  squash_image "${IMAGE_TAG}"
fi

print_image_size "${IMAGE_TAG}" "Image size"
docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' "${IMAGE_TAG}"