install_dir=/opt/buildtools/make-4.4.1-1.oe2403sp1

# install files
wget --no-check-certificate https://repo.openeuler.org/openEuler-24.03-LTS-SP1/source/Packages/make-4.4.1-1.oe2403sp1.src.rpm
ls make-4.4.1-1.oe2403sp1.src.rpm

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}

#check dependency（基础层已安装 build-essential，无需重复检查）
# function check_dependency(){
# for dependency in $1
# do
# if [ `dpkg -l | grep $dependency | wc -l` -eq 0 ];then
#     exit 1
# fi
# done
# }
# check_dependency "build-essential"

cp make-4.4.1-1.oe2403sp1.src.rpm ${install_dir}
cd ${install_dir}
rpm --version
cpio --version
rpm2cpio make-4.4.1-1.oe2403sp1.src.rpm | cpio -idm 2>&1 | grep -v "skipped"
tar -zxf make-4.4.1.tar.gz
cd make-4.4.1

##开始编译
tmp_cpus=$(grep -w processor /proc/cpuinfo|wc -l)
./configure --prefix=${install_dir}
make -j ${tmp_cpus}
make install
update-alternatives --install /usr/local/bin/make make ${install_dir}/bin/make 100
cd ..
rm -rf make-4.4.1 make-4.4.1.tar.gz make-4.4.1-1.oe2403sp1.src.rpm