#!/bin/bash
set -eux
set -o pipefail
install_dir=/opt/buildtools/gcc_7.5.0

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}
tmp_cpus=$(grep -w processor /proc/cpuinfo|wc -l)

# get install file
cd /opt/buildtools/gcc_7.5.0
wget --no-check-certificate https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
wget --no-check-certificate https://ftp.gnu.org/gnu/mpfr/mpfr-4.1.0.tar.gz
wget --no-check-certificate https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
wget --no-check-certificate https://ftp.gnu.org/gnu/gcc/gcc-7.5.0/gcc-7.5.0.tar.gz

# gmp / mpfr / mpc 依赖源码编译（make、glibc 头文件已由基础层提供）

# install gmp
gmp_install_dir="${install_dir}/gmp-6.2.1"
[ -d "${gmp_install_dir}" ] && rm -rf ${gmp_install_dir}
mkdir -p ${gmp_install_dir}
tar xf gmp-6.2.1.tar.xz
cd gmp-6.2.1
./configure --prefix=${gmp_install_dir}
make -j ${tmp_cpus}
make install

# install mpfr
mpfr_install_dir="${install_dir}/mpfr-4.1.0"
[ -d "${mpfr_install_dir}" ] && rm -rf ${mpfr_install_dir}
mkdir -p ${mpfr_install_dir}
cd ..
tar xf mpfr-4.1.0.tar.gz
cd mpfr-4.1.0
./configure --prefix=${mpfr_install_dir} --with-gmp=${gmp_install_dir}
make -j ${tmp_cpus}
make install

# install mpc
mpc_install_dir="${install_dir}/mpc-1.2.1"
[ -d "${mpc_install_dir}" ] && rm -rf ${mpc_install_dir}
mkdir -p ${mpc_install_dir}
cd ..
tar xf mpc-1.2.1.tar.gz
cd mpc-1.2.1
./configure --prefix=${mpc_install_dir} --with-gmp=${gmp_install_dir} --with-mpfr=${mpfr_install_dir}
make -j ${tmp_cpus}
make install
cd ..

tar -xzf gcc-7.5.0.tar.gz
if [ -d "Backport-CVE-*" ]; then
    cp -rf Backport-CVE-* gcc-7.5.0/
    cd gcc-7.5.0
    for patch_file in Backport-CVE-*.patch; do
        if [ -f "$patch_file" ]; then
            echo "应用补丁: $patch_file"
            patch -p1 < "$patch_file"
        fi
    done
else
    cd gcc-7.5.0
    echo "注意：未找到安全补丁，跳过补丁应用"
fi

# 应用修复
sed -i '/sys\/ustat.h/d' libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
sed -i '/struct ustat/d' libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc

# 禁用有问题的sanitizer检查
sed -i '/CHECK_SIZE_AND_OFFSET(ipc_perm, mode);/s/^/#if 0\n/' libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
sed -i '/CHECK_SIZE_AND_OFFSET(ipc_perm, mode);/a #endif' libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc

# 配置时禁用sanitizer
./configure --prefix=${install_dir} \
  --enable-checking=release \
  --disable-bootstrap \
  --disable-multilib \
  --with-mpc=${mpc_install_dir} \
  --with-gmp=${gmp_install_dir} \
  --with-mpfr=${mpfr_install_dir} \
  --disable-libsanitizer

echo "${mpc_install_dir}/lib" >> /etc/ld.so.conf.d/libc.conf
echo "${gmp_install_dir}/lib" >> /etc/ld.so.conf.d/libc.conf
echo "${mpfr_install_dir}/lib" >> /etc/ld.so.conf.d/libc.conf
ldconfig

# 分步构建，先构建核心部分
make -j ${tmp_cpus} all-gcc all-target-libgcc > gcc_make_install.log 2>&1
make install-gcc install-target-libgcc >> gcc_make_install.log 2>&1

# 然后构建libstdc++（可选）
make -j ${tmp_cpus} all-target-libstdc++-v3 >> gcc_make_install.log 2>&1
make install-target-libstdc++-v3 >> gcc_make_install.log 2>&1

#create link
ln -sf ${install_dir}/bin/gcc ${install_dir}/bin/cc

# Environment Variable
echo "export GCC_HOME=${install_dir}" >> /etc/profile
echo "export PATH=\$GCC_HOME/bin:\$PATH" >> /etc/profile

#update libstdc++ library
cp ${install_dir}/lib64/libstdc++.so.6.0.24 /usr/lib/ || true
chmod 755 /usr/lib/libstdc++.so.6.0.24 2>/dev/null || true
ln -sf /usr/lib/libstdc++.so.6.0.24 /usr/lib/libstdc++.so.6 2>/dev/null || true

# 清理下载的源码包与构建日志（gmp/mpfr/mpc/gcc 源码目录即安装目录，保留）
cd /opt/buildtools/gcc_7.5.0
rm -f gmp-6.2.1.tar.xz mpfr-4.1.0.tar.gz mpc-1.2.1.tar.gz gcc-7.5.0.tar.gz gcc_make_install.log