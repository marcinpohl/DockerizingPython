#!/bin/bash
### From Python Docker image?

umask 0077
set -euo pipefail
IFS=$'\n\t'

# ensure local python is preferred over distribution python
export PATH=/usr/local/bin:$PATH
export LANG=C.UTF-8

function has_avx2() { grep -q avx2 /proc/cpuinfo; }

function partB() {
    export GPG_KEY='0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D'
    export PYTHON_VERSION=3.7.3
    wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"
    wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc"
    GNUPGHOME="$(mktemp -d)"
    export GNUPGHOME
    ### TODO figure out download authentication
    #gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY"
    #gpg --batch --verify python.tar.xz.asc python.tar.xz
    #command -v gpgconf > /dev/null && gpgconf --kill all
    rm -rf -- "$GNUPGHOME" python.tar.xz.asc
    rm -fr -- /usr/src/python
    mkdir -p /usr/src/python
    tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz
    rm -- python.tar.xz

    pushd /usr/src/python
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"

    LANG=C
    ### TODO add secure flags
    CFLAGS="$(dpkg-buildflags --get CFLAGS) -O3"
    CXXFLAGS="$(dpkg-buildflags --get CFLAGS) -O3"

    if has_avx2; then
        CFLAGS="$CFLAGS -march=haswell -mfma"
        CXXFLAGS="$CXXFLAGS -march=haswell -mfma"
    fi

    ### Main parts
    make clean || true
    ./configure \
        --build="$gnuArch" \
        --enable-ipv6=yes  \
        --enable-loadable-sqlite-extensions \
        --enable-optimizations \
        --enable-shared \
        --with-computed-gotos \
        --with-lto=8 \
        --with-pymalloc  \
        --with-system-expat \
        --with-system-ffi \
        --without-cxx-main \
        --without-ensurepip
        ac_cv_header_bluetooth_bluetooth_h=no  \
        ac_cv_header_bluetooth_h=no  \
    make -j profile-opt
    LANG=C
    LD_LIBRARY_PATH=$(pwd) ./python -Wd -E -tt  Lib/test/regrtest.py -v -x test_asyncio test_uuid test_subprocess || true
    make install
    ldconfig

    #find /usr/local -depth \
    #    \( \
    #        \( -type d -a \( -name test -o -name tests \) \) \
    #        -o \
    #        \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    #    \) -delete
    #rm -rf -- /usr/src/python
    echo "  -->> new version of Python: $(/usr/local/bin/python3 --version)"
    popd
}


function partC() {
    wget -O - 'https://bootstrap.pypa.io/get-pip.py' \
    | /usr/local/bin/python3.7 - --disable-pip-version-check --no-cache-dir pip

    echo "  -->> new version of Pip: $(/usr/local/bin/pip3.7 --version)"
    /usr/local/bin/pip3.7 install --upgrade wheel setuptools pip
}

function partD() {
    ### Make some useful symlinks that are expected to exist
    ### It's ok to fail here, optionals
    set +e
    pushd /usr/local/bin
    ln -s idle3 idle
    ln -s pydoc3 pydoc
    ln -s python3 python
    ln -s python3-config python-config
    popd
    set -e
}

function partE() {
    ### cleanup
    rm -fr -- /usr/src/python
}

function partF() {
    mkdir -p /usr/src/afl
    pushd /usr/src/afl
    wget -c -O- http://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz \
    | tar xvz -C /usr/src/afl --strip-components=1
    make -j --debug=bj install
}


#partA
partB
partC
partD
#partE  ### disabled for debugging for now
partF
