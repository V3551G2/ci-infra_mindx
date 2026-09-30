set -eux
set -o pipefail
install_dir=/opt/buildtools/faiss
tmp_cpus=$(grep -w processor /proc/cpuinfo|wc -l)
TMP_PATH=$(pwd)

case $(uname -m) in
  x86_64)  OPENBLAS_TARGET=ATOM;;
  aarch64) OPENBLAS_TARGET=ARMV8;;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1;;
esac

# 安装wheel和build
apt-get update
apt-get install -y swig python3.10-dev
pip3 install wheel
pip3 install build

#安装OpenBLAS
wget https://github.com/xianyi/OpenBLAS/archive/v0.3.10.tar.gz -O OpenBLAS-0.3.10.tar.gz
tar -xf OpenBLAS-0.3.10.tar.gz
cd OpenBLAS-0.3.10
echo 'export PATH=/usr/bin:$PATH' >> /etc/profile
set +eux
source /etc/profile
set -eux
if [ ! -f /usr/lib/$(uname -m)-linux-gnu/libgfortran.so ]; then
  gfortran_lib=$(find /usr/lib/$(uname -m)-linux-gnu -name "libgfortran.so*" 2>/dev/null | head -1)
  [ -n "$gfortran_lib" ] && ln -sf "$gfortran_lib" /usr/lib/$(uname -m)-linux-gnu/libgfortran.so
fi
make FC=gfortran USE_OPENMP=1 TARGET=${OPENBLAS_TARGET} -j
make install
sed -i '47 d' /etc/profile
ln -sf /opt/OpenBLAS/lib/libopenblas.so /usr/lib/libopenblas.so
ln -sf /opt/OpenBLAS/lib/libopenblas.so.0 /usr/lib/libopenblas.so.0

install_path="/usr/local/faiss/faiss1.14.1"

cd ${TMP_PATH}
wget https://github.com/facebookresearch/faiss/archive/v1.14.1.tar.gz -O faiss-1.14.1.tar.gz
ls faiss-1.14.1.tar.gz

# clear
[ -d "${install_dir}" ] && rm -rf ${install_dir}
mkdir -p ${install_dir}

install_action="install"
tar xzf faiss-1.14.1.tar.gz

pip3 install --upgrade pip
pip3 install numpy

cd faiss-1.14.1/faiss
arch="$(uname -m)"
if [ "${arch}" = "aarch64" ]; then
  gcc_version="$(gcc -dumpversion)"
  if [ "${gcc_version}" = "4.8.5" ];then
    sed -i '20i /*' utils/simdlib.h
    sed -i '24i */' utils/simdlib.h
  fi
fi
sed -i "214 i\\
    \\
    virtual void search_with_filter (idx_t n, const float *x, idx_t k,\\
                                     float *distances, idx_t *lables, const void *mask = nullptr) const {}\\
" Index.h
sed -i "60 i\\
    \\
template <typename IndexT>\\
IndexIDMapTemplate<IndexT>::IndexIDMapTemplate (IndexT *index, std::vector<idx_t> &ids):\\
    index (index),\\
    own_fields (false)\\
{\\
    this->is_trained = index->is_trained;\\
    this->metric_type = index->metric_type;\\
    this->verbose = index->verbose;\\
    this->d = index->d;\\
    id_map = ids;\\
}\\
" IndexIDMap.cpp
sed -i "30 i\\
    \\
    explicit IndexIDMapTemplate (IndexT *index, std::vector<idx_t> &ids);\\
" IndexIDMap.h
# sed -i "217 i\\
#   utils/sorting.h
# " CMakeLists.txt
# modify source code end
cd ..
cmake -B build . -DFAISS_ENABLE_GPU=OFF -DFAISS_ENABLE_PYTHON=OFF -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${install_path}
cd build && make -j && make install
cd ../.. && rm -rf faiss-1.14.1.tar.gz && rm -rf faiss-1.14.1
cp ${install_path}/lib/libfaiss.so /usr/local/lib/
