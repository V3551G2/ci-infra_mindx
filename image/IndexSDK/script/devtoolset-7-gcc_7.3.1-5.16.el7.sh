origin_dir=$(cd "$(dirname "$0")" || exit; pwd)
set -eux
set -o pipefail
source /etc/profile
os=$(cat /etc/os-release 2>/dev/null | grep ^ID= | awk -F= '{print $2}')
gcc --version
install_dir=/opt/rh/devtoolset-7
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}
wget https://aoe-flow.obs.cn-north-4.myhuaweicloud.com:443/inference/dockerfile/devtoolset7.zip
unzip devtoolset7.zip
ls
cp -r devtoolset7/src/* ${install_dir}
TARGET=root
LIBSTDCXX_VERSION="6.0.24"
echo "${install_dir}/${TARGET}"
mkdir -p "${install_dir}/${TARGET}"

cp devtoolset7/depend/*.deb ${install_dir}/${TARGET}
ls -l ${install_dir}/${TARGET}
if [ $os == 'ubuntu' ]; then
  libc_name=libc6_2.17-93ubuntu4_amd64
  libc_dev_name=libc6-dev_2.17-93ubuntu4_amd64
  libstdcpp_name=libstdc++6_4.8.2-19ubuntu1_amd64
  libstdcpp_path=./usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.19
  cd "${install_dir}/${TARGET}"
  echo "make dependency on ubuntu"
  if [ ! -f ${libc_name}.deb ]; then
    echo "${libc_name}.deb is not find."
  fi
  unar "${libc_name}.deb"
  ls -l ${libc_name}
  tar -C "${install_dir}/${TARGET}" -xvf "${libc_name}/data.tar.gz" && \
  rm -rf "${libc_name}.deb" "${libc_name}"

  if [ ! -f "${libc_dev_name}.deb" ]; then
    echo "${libc_dev_name}.deb is not find."
  fi
  unar "${libc_dev_name}.deb"
  ls -l ${libc_dev_name}
  tar -C "${install_dir}/${TARGET}" -xvf "${libc_dev_name}/data.tar.gz" && \
  rm -rf "${libc_dev_name}.deb" "${libc_dev_name}"

  ln -s  "/usr/include/linux/" "${install_dir}/${TARGET}/usr/include/linux"
  ln -s  "/usr/include/asm-generic" "${install_dir}/${TARGET}/usr/include/asm-generic"
  ln -s  "/usr/include/$(arch)-linux-gnu/asm" "${install_dir}/${TARGET}/usr/include/asm"

  # Symlinks in the binary distribution are set up for installation in /usr, we
  # need to fix up all the links to stay within /${TARGET}.
BASE="${install_dir}/${TARGET}"
find "${BASE}" -type l | while read l ; do
    if [[ "$(readlink "$l")" == /lib* ]]; then
      ORIG="$(readlink "$l")";
      rm "$l";
      ln -s "${BASE}${ORIG}" "$l"
    fi
  done
  unar "${libstdcpp_name}.deb" && \
  tar -C "${install_dir}/${TARGET}" -xf "${libstdcpp_name}/data.tar.xz" "${libstdcpp_path}" && \
  rm -rf "${libstdcpp_name}.deb" "${libstdcpp_name}"
fi

ls -l ${install_dir}
ls -l ${install_dir}/${TARGET}
cd ${install_dir}
mkdir -p "${TARGET}-src"

cp ${install_dir}/isl-0.16.1.tar.bz2 ${TARGET}-src
cp ${install_dir}/mpc-1.0.3.tar.gz	${TARGET}-src
cp ${install_dir}/gmp-6.1.0.tar.bz2 ${TARGET}-src
cp ${install_dir}/mpfr-3.1.4.tar.bz2 ${TARGET}-src
cp ${install_dir}/devtoolset-7-gcc-7.3.1-5.16.el7.src.rpm "${TARGET}-src"
# Build a devtoolset cross-compiler based on our glibc 2.12 sysroot setup.
cd "${TARGET}-src"
echo "step1: release devtoolset pkg."
rpm2cpio "devtoolset-7-gcc-7.3.1-5.16.el7.src.rpm" |cpio -idmv

echo "step2: release gcc pkg."
tar -xjf "gcc-7.3.1-20180303.tar.bz2" --strip 1

# Apply the devtoolset patches to gcc.  参考 tf的代码，需要看下补丁是否都打完了
echo "step3: patch gcc spec."

SPEC="gcc.spec"
grep '%patch' "${SPEC}" |while read cmd ; do
  N=$(echo "${cmd}" |sed 's,%patch\([0-9]\+\).*,\1,')
  if [[ $N =~ 1002 ]];then
    N=1002
  fi
  file=$(grep "Patch$N:" "${SPEC}" |sed 's,.*: ,,')
  parg=$(echo "${cmd}" |sed 's,.*\(-p[0-9]\).*,\1,')
  if [[ ! "${file}" =~ doxygen && "${cmd}" != \#* ]]; then
    echo "patch ${parg} -s < ${file}"
    patch ${parg} -s < "${file}"
  fi
done


echo "step5: prepare to compile gcc."
./contrib/download_prerequisites

mkdir -p "${TARGET}-build"
cd "${TARGET}-build"


echo "step6: compile gcc."
"../configure" \
      --prefix=/"${install_dir}/${TARGET}/usr" \
      --with-sysroot="${install_dir}/${TARGET}" \
      --disable-bootstrap \
      --disable-libmpx \
      --disable-libsanitizer \
      --disable-libunwind-exceptions \
      --disable-lto \
      --disable-multilib \
      --enable-__cxa_atexit \
      --enable-gnu-indirect-function \
      --enable-gnu-unique-object \
      --enable-initfini-array \
      --enable-languages="c,c++" \
      --enable-linker-build-id \
      --enable-plugin \
      --enable-shared \
      --enable-threads=posix \
      --with-default-libstdcxx-abi="gcc4-compatible" \
      --with-gcc-major-version-only \
      --with-linker-hash-style="gnu"

echo "step7: make gcc"
make -j 2 && make install
cd ${install_dir}/${TARGET}/usr/bin
ln -sf /usr/bin/ar ar
ln -sf gcc cc
ln -sf /opt/buildtools/python-3.11.4/lib/libpython3.11.so /opt/rh/devtoolset-7/root/usr/lib/libpython3.11.so
cp /usr/include/zconf.h /opt/rh/devtoolset-7/root/usr/include/
cp /usr/include/zlib.h /opt/rh/devtoolset-7/root/usr/include/
cp /usr/lib/$(uname -i)-linux-gnu/libz.*  /opt/rh/devtoolset-7/root/lib/$(uname -i)-linux-gnu/
cp -r /usr/include/openssl/ /opt/rh/devtoolset-7/root/usr/include/
cp /usr/include/$(uname -i)-linux-gnu/openssl/opensslconf.h /opt/rh/devtoolset-7/root/usr/include/openssl/
cp /usr/lib/$(uname -i)-linux-gnu/libcrypto.so /opt/rh/devtoolset-7/root/usr/lib/$(uname -i)-linux-gnu/
glibc_res=$(grep -r GLIBCXX_3.4.21 /opt/rh/devtoolset-7/root)
if [ -n "${glibc_res}" ];then
  for var in ${glibc_res[@]}
  do
    if [ -f ${var} ];then
      echo "delete ${var}"
      rm -f ${var}
    fi
  done
fi
if [ -f /opt/rh/devtoolset-7/root/usr/include/inttypes.h ];then
  rm -f /opt/rh/devtoolset-7/root/usr/include/inttypes.h
  cp /usr/include/inttypes.h /opt/rh/devtoolset-7/root/usr/include/
fi
cp ${install_dir}/${TARGET}-src/root-build/x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++_nonshared48.a ${install_dir}/${TARGET}/usr/lib/gcc/x86_64-pc-linux-gnu/7/libstdc++_nonshared.a
cp ${install_dir}/${TARGET}/usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.19 ${install_dir}/${TARGET}/usr/lib/gcc/x86_64-pc-linux-gnu/7/libstdc++.so.6

# cp -r /usr/include/fuse ${install_dir}/${TARGET}/usr/include/
# cp /usr/lib/$(uname -i)-linux-gnu/libfuse.so ${install_dir}/${TARGET}/usr/lib/$(uname -i)-linux-gnu/
# cp -r /usr/include/numa.h ${install_dir}/${TARGET}/usr/include/
# cp /usr/lib/$(uname -i)-linux-gnu/libnuma.so ${install_dir}/${TARGET}/usr/lib/$(uname -i)-linux-gnu/

# echo '#define LINUX_VERSION_CODE 199168' > ${install_dir}/${TARGET}/usr/include/linux/version.h
# echo '#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + (c))' >> ${install_dir}/${TARGET}/usr/include/linux/version.h

# echo '/* GNU ld script' >> ${install_dir}/${TARGET}/usr/lib/gcc/x86_64-pc-linux-gnu/7/libstdc++.so
# echo '   Use the shared library, but some functions are only in' >> ${install_dir}/${TARGET}/usr/lib/gcc/x86_64-pc-linux-gnu/7/libstdc++.so
# echo '   the static library, so try that secondarily.  */' >> ${install_dir}/${TARGET}/usr/lib/gcc/x86_64-pc-linux-gnu/7/libstdc++.so
# echo 'OUTPUT_FORMAT(elf64-x86-64)' >> ${install_dir}/${TARGET}/usr/lib/gcc/x86_64-pc-linux-gnu/7/libstdc++.so
# echo 'INPUT ( ./libstdc++.so.6 -lstdc++_nonshared )' >> ${install_dir}/${TARGET}/usr/lib/gcc/x86_64-pc-linux-gnu/7/libstdc++.so

rm -rf ${install_dir}/${TARGET}-src
rm -rf ${install_dir}/*.tar* ${install_dir}/*.rpm ${install_dir}/${TARGET}/*.deb
symlinks -d -r ${install_dir}/${TARGET}

cd ${origin_dir}
set -eux
set -o pipefail
source /etc/profile
os=$(cat /etc/os-release 2>/dev/null | grep ^ID= | awk -F= '{print $2}')
gcc --version

install_dir=/opt/rh/devtoolset-index
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}
wget https://aoe-flow.obs.cn-north-4.myhuaweicloud.com:443/inference/dockerfile/devtoolset7.zip
unzip devtoolset7.zip
ls
cp -r devtoolset7/src/* ${install_dir}
TARGET=root
LIBSTDCXX_VERSION="6.0.24"
echo "${install_dir}/${TARGET}"
mkdir -p "${install_dir}/${TARGET}"

cp devtoolset7/depend/*.deb ${install_dir}/${TARGET}
ls -l ${install_dir}/${TARGET}
if [ $os == 'ubuntu' ]; then
  libc_name=libc6_2.17-93ubuntu4_amd64
  libc_dev_name=libc6-dev_2.17-93ubuntu4_amd64
  libstdcpp_name=libstdc++6_4.8.2-19ubuntu1_amd64
  libstdcpp_path=./usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.19
  cd "${install_dir}/${TARGET}"
  echo "make dependency on ubuntu"
  if [ ! -f ${libc_name}.deb ]; then
    echo "${libc_name}.deb is not find."
  fi
  unar "${libc_name}.deb"
  ls -l ${libc_name}
  tar -C "${install_dir}/${TARGET}" -xvf "${libc_name}/data.tar.gz" && \
  rm -rf "${libc_name}.deb" "${libc_name}"

  if [ ! -f "${libc_dev_name}.deb" ]; then
    echo "${libc_dev_name}.deb is not find."
  fi
  unar "${libc_dev_name}.deb"
  ls -l ${libc_dev_name}
  tar -C "${install_dir}/${TARGET}" -xvf "${libc_dev_name}/data.tar.gz" && \
  rm -rf "${libc_dev_name}.deb" "${libc_dev_name}"

  ln -s  "/usr/include/linux/" "${install_dir}/${TARGET}/usr/include/linux"
  ln -s  "/usr/include/asm-generic" "${install_dir}/${TARGET}/usr/include/asm-generic"
  ln -s  "/usr/include/$(arch)-linux-gnu/asm" "${install_dir}/${TARGET}/usr/include/asm"

  # Symlinks in the binary distribution are set up for installation in /usr, we
  # need to fix up all the links to stay within /${TARGET}.
BASE="${install_dir}/${TARGET}"
find "${BASE}" -type l | while read l ; do
    if [[ "$(readlink "$l")" == /lib* ]]; then
      ORIG="$(readlink "$l")";
      rm "$l";
      ln -s "${BASE}${ORIG}" "$l"
    fi
  done
  unar "${libstdcpp_name}.deb" && \
  tar -C "${install_dir}/${TARGET}" -xf "${libstdcpp_name}/data.tar.xz" "${libstdcpp_path}" && \
  rm -rf "${libstdcpp_name}.deb" "${libstdcpp_name}"
fi

ls -l ${install_dir}
ls -l ${install_dir}/${TARGET}
cd ${install_dir}
mkdir -p "${TARGET}-src"

cp ${install_dir}/isl-0.16.1.tar.bz2 ${TARGET}-src
cp ${install_dir}/mpc-1.0.3.tar.gz	${TARGET}-src
cp ${install_dir}/gmp-6.1.0.tar.bz2 ${TARGET}-src
cp ${install_dir}/mpfr-3.1.4.tar.bz2 ${TARGET}-src
cp ${install_dir}/devtoolset-7-gcc-7.3.1-5.16.el7.src.rpm "${TARGET}-src"
# Build a devtoolset cross-compiler based on our glibc 2.12 sysroot setup.
cd "${TARGET}-src"
echo "step1: release devtoolset pkg."
rpm2cpio "devtoolset-7-gcc-7.3.1-5.16.el7.src.rpm" |cpio -idmv

echo "step2: release gcc pkg."
tar -xjf "gcc-7.3.1-20180303.tar.bz2" --strip 1

# Apply the devtoolset patches to gcc.  参考 tf的代码，需要看下补丁是否都打完了
echo "step3: patch gcc spec."

SPEC="gcc.spec"
grep '%patch' "${SPEC}" |while read cmd ; do
  N=$(echo "${cmd}" |sed 's,%patch\([0-9]\+\).*,\1,')
  if [[ $N =~ 1002 ]];then
    N=1002
  fi
  file=$(grep "Patch$N:" "${SPEC}" |sed 's,.*: ,,')
  parg=$(echo "${cmd}" |sed 's,.*\(-p[0-9]\).*,\1,')
  if [[ ! "${file}" =~ doxygen && "${cmd}" != \#* ]]; then
    echo "patch ${parg} -s < ${file}"
    patch ${parg} -s < "${file}"
  fi
done


echo "step5: prepare to compile gcc."
./contrib/download_prerequisites

mkdir -p "${TARGET}-build"
cd "${TARGET}-build"


echo "step6: compile gcc."
"../configure" \
      --prefix=/"${install_dir}/${TARGET}/usr" \
      --with-sysroot="${install_dir}/${TARGET}" \
      --disable-bootstrap \
      --disable-libmpx \
      --disable-libsanitizer \
      --disable-libunwind-exceptions \
      --disable-lto \
      --disable-multilib \
      --enable-__cxa_atexit \
      --enable-gnu-indirect-function \
      --enable-gnu-unique-object \
      --enable-initfini-array \
      --enable-languages="c,c++" \
      --enable-linker-build-id \
      --enable-plugin \
      --enable-shared \
      --enable-threads=posix \
      --with-gcc-major-version-only \
      --with-linker-hash-style="gnu"

echo "step7: make gcc"
make -j 2 && make install
cd ${install_dir}/${TARGET}/usr/bin
ln -sf /usr/bin/ar ar
ln -sf gcc cc
ls -l ${install_dir}/${TARGET}/usr/bin
ln -sf /opt/buildtools/python-3.11.4/lib/libpython3.11.so ${install_dir}/root/usr/lib/libpython3.11.so
cp /usr/include/zconf.h ${install_dir}/root/usr/include/
cp /usr/include/zlib.h ${install_dir}/root/usr/include/
cp /usr/lib/$(uname -i)-linux-gnu/libz.*  ${install_dir}/root/lib/$(uname -i)-linux-gnu/
cp -r /usr/include/openssl/ ${install_dir}/root/usr/include/
cp /usr/include/$(uname -i)-linux-gnu/openssl/opensslconf.h ${install_dir}/root/usr/include/openssl/
cp /usr/lib/$(uname -i)-linux-gnu/libcrypto.so ${install_dir}/root/usr/lib/$(uname -i)-linux-gnu/
if [ -f ${install_dir}/root/usr/include/inttypes.h ];then
  rm -f ${install_dir}/root/usr/include/inttypes.h
  cp /usr/include/inttypes.h ${install_dir}/root/usr/include/
fi

rm -rf ${install_dir}/${TARGET}-src
rm -rf ${install_dir}/*.tar* ${install_dir}/*.rpm ${install_dir}/${TARGET}/*.deb
symlinks -d -r ${install_dir}/${TARGET}

# cd ${origin_dir}
# tar xzf CMake-3.28.2.tar.gz
# pushd CMake-3.28.2
# sed -i 's#cmake_options="-DCMAKE_BOOTSTRAP=1"#cmake_options="-DCMAKE_BOOTSTRAP=1 -DCMAKE_BUILD_TYPE=Release"#1' bootstrap
# ./configure --prefix=${install_dir}/root/usr
# make -j 2
# make install
# popd
# rm -rf CMake-3.28.2.tar.gz