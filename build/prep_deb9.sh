#!/bin/bash
set -o pipefail
BASEDIR=$( cd -P "$( dirname "$0" )" && pwd )

pushd "${BASEDIR}" || exit

function _install_repo_keys() {
    sudo apt-get update -qy
    sudo apt-get install -qy --no-install-suggests --no-install-recommends \
            apt dirmngr wget
    sudo bash -c 'wget -qO- https://download.docker.com/linux/debian/gpg | apt-key add - '
    sudo bash -c 'wget -qO- https://dl.google.com/linux/linux_signing_key.pub | apt-key add - '
    sudo bash -c 'wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - '
    sudo bash -c 'wget -qO- https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add - '
    sudo bash -c 'wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg'
    sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
    sudo apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 74A941BA219EC810
}

function install_repos() {
_install_repo_keys

cat <<- END_TEXT > /etc/apt/sources.deb9.list
#------------------------------------------------------------------------------#
#                   OFFICIAL DEBIAN REPOS
#------------------------------------------------------------------------------#

###### Debian Main Repos
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free

deb http://deb.debian.org/debian/ stable-updates main contrib non-free
deb-src http://deb.debian.org/debian/ stable-updates main contrib non-free

deb http://deb.debian.org/debian-security stable/updates main
deb-src http://deb.debian.org/debian-security stable/updates main

deb http://ftp.debian.org/debian stretch-backports main
deb-src http://ftp.debian.org/debian stretch-backports main

#------------------------------------------------------------------------------#
#                      UNOFFICIAL  REPOS
#------------------------------------------------------------------------------#

###### 3rd Party Binary Repos
###Docker CE
deb [arch=amd64] https://download.docker.com/linux/debian stretch stable

###Google Chrome Browser
deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main

###MariaDB
deb [arch=i386,amd64] http://mirror.23media.de/mariadb/repo/10.2/debian stretch main
deb-src [arch=i386,amd64] http://mirror.23media.de/mariadb/repo/10.2/debian stretch main

###PostgreSQL
deb [arch=amd64,i386] http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main

###Sublime Text
deb https://download.sublimetext.com/ apt/stable/

###TOR
deb [arch=i386,amd64,armel,armhf] http://deb.torproject.org/torproject.org stable main
deb-src [arch=i386,amd64,armel,armhf] http://deb.torproject.org/torproject.org stable main

###Visual Studio Code
deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main
END_TEXT
}


function update_system() {
sudo apt-get update -qy \
    && sudo apt-get -t stretch dist-upgrade -yq --no-install-recommends -o Dpkg::Options::="--force-confold" \
    && sudo apt-get install -qy --no-install-suggests --no-install-recommends \
        apt-doc /
        apt-file /
        apt-offline /
        apt-transport-https /
        apt-utils /
        aria2 /
        autoconf /
        automake /
        autotools-dev /
        bash-completion /
        build-essential /
        ca-certificates /
        curl /
        git /
        gnupg2 /
        jq /
        libltdl-dev /
        libpython-dev /
        libpython2.7-dev /
        libtool /
        lsof /
        ltrace /
        mercurial /
        mlocate /
        most /
        multitail /
        pbzip2 /
        pigz /
        procps /
        pylint /
        python-coverage /
        python-dev /
        python-nose /
        python2.7-dev /
        python3-virtualenv /
        python3-{dev,venv} /
        software-properties-common /
        strace /
        tmux /
        vim /
        vim-syntastic /
        virtualenv /
        wget
}


function install_python() {
    sudo apt-get install python3-{dev,venv} bash-completion git mercurial vim tmux build-essential python3-venv jq procps mlocate pigz pbzip2
    python3 -mvenv "${HOME}/py35"
    "${HOME}/py35/bin/pip3.5" install -U pip setuptools wheel
    "${HOME}/py35/bin/pip3.5" install -U yapf radon pylint ipython
}

function install_shellcheck() {
    #DONE
    sudo apt-get install cabal-install
    cabal update
    cabal install ShellCheck
}


function install_aptfile() {
    #DONE
    sudo apt-get install apt-doc apt-file apt-offline apt-transport-https apt-utils aria2
    sudo apt-file update
}

function install_perf() {
    #DONE
    sudo apt-get install linux-perf
    echo 'kernel.perf_event_paranoid=-1' > /etc/sysctl.d/perf.conf
    sudo sysctl --system
    sudo sysctl kernel.perf_event_paranoid
}

function install_thinkpad() {
    echo 'options thinkpad_acpi fan_control=1' | sudo tee /etc/modprobe.d/thinkpad_acpi.conf

    cat - << EOSCRIPT | sudo tee /etc/modprobe.d/i915.conf
options i915 modeset=1
options i915 semaphores=1
options i915 enable_rc6=4
options i915 enable_dc=2
options i915 enable_fbc=1
EOSCRIPT

cat - << EOSCRIPT2 | sudo tee -a /etc/systemd/logind.conf
HandlePowerKey=poweroff
HandleHibernateKey=hibernate
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
EOSCRIPT2

}

function install_gdb82() {
    umask 0022
    wget -nv -q https://ftp.gnu.org/gnu/gdb/gdb-8.2.1.tar.xz -O- | tar xJv
    pushd gdb-8.2.1 || exit 1
    ### sometimes caches get in a way. distclean does NOT clean them everywhere
    make distclean
    find . -name 'config.cache' -delete
    sudo apt install autoconf   ### That's what was missing from my usual dev setup
    #./configure --prefix=/usr/local/gdb8.2.1b/ --with-python=/usr/bin/python3.5 --enable-tui --with-curses --enable-lto
    ./configure --prefix=/usr/local/gdb8.2.1b/ --with-python=/usr/bin/python3.5 \
        --enable-tui --with-curses --enable-lto \
        --with-intel-pt --with-libipt-prefix=
    ### https://github.com/cyrus-and/gdb-dashboard
    wget -P "$HOME" http://git.io/.gdbinit
    nice make --debug=bj -j8
    sudo make install
    umask 0077
    popd || exit 2
}


function install_lynis() {
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C80E383C3DE9F082E01391A0366C67DE91CA5D5F
sudo apt install apt-transport-https
echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99disable-translations
echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
sudo apt update
sudo apt install lynis
sudo lynis audit system --quiet
}


function install_gcloud() {
# https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
# https://cloud.google.com/sdk/docs/initializing
# Create environment variable for correct distribution

sudo apt-get install -qy --no-install-suggests --no-install-recommends \
    lsb-release
RELEASE="$(lsb_release -c -s)"
export CLOUD_SDK_REPO="cloud-sdk-${RELEASE}"

# Add the Cloud SDK distribution URI as a package source
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" \
  | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Import the Google Cloud Platform public key
wget -qO- https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo apt-key add -

# Update the package list and install the Cloud SDK
sudo apt-get update -qy \
  && sudo apt-get install -qy --no-install-suggests --no-install-recommends \
        google-cloud-sdk
}

function install_compute_image_packages() {
# https://wiki.debian.org/Cloud/GoogleComputeEngineImage
wget -qO- https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/google-cloud.list << EOM
deb http://packages.cloud.google.com/apt google-compute-engine-stretch-stable main
deb http://packages.cloud.google.com/apt google-cloud-packages-archive-keyring-stretch main
EOM
sudo apt update -qq -y \
  && sudo apt install -qq -y google-cloud-packages-archive-keyring
}

function install_kernel_from_backports() {
### DO NOT USE!!! yet...
echo deb http://http.debian.net/debian stretch-backports main contrib non-free > /etc/apt/sources.list.d/stretch-backports.list

apt update
#apt remove aufs-dkms ###Might be necessary, if you see: Error!  The dkms.conf for this module includes a BUILD_EXCLUSIVE directive which does not match this kernel/arch.  This indicates that it should not be built.
apt -t stretch-backports install linux-image-amd64 firmware-linux debian-kernel-handbook linux-headers-4.19.0-0.bpo.4-amd64 linux-compiler-gcc-6-x86 linux-headers-4.19.0-0.bpo.4-common linux-kbuild-4.19
### TODO use version/repo pinning for these so they dont get downgraded during regular upgrades
### logs for the upgrade:
# Commandline: apt -t stretch-backports install linux-image-amd64 firmware-linux debian-kernel-handbook
# Install: intel-microcode:amd64 (3.20180807a.2~bpo9+1, automatic), irqbalance:amd64 (1.1.0-2.3, automatic), iucode-tool:amd64 (2.3.1-1~bpo9+1, automatic), firmware-amd-graphics:amd64 (20190114-1~bpo9+2, automatic), debian-kernel-handbook:amd64 (1.0.18), amd64-microcode:amd64 (3.20181128.1~bpo9+1, automatic), firmware-linux-free:amd64 (3.4, automatic), libapparmor-perl:amd64 (2.11.0-3+deb9u2, automatic), firmware-linux-nonfree:amd64 (20190114-1~bpo9+2, automatic), firmware-misc-nonfree:amd64 (20190114-1~bpo9+2, automatic), apparmor:amd64 (2.11.0-3+deb9u2, automatic), linux-image-4.19.0-0.bpo.2-amd64:amd64 (4.19.16-1~bpo9+1, automatic), firmware-linux:amd64 (20190114-1~bpo9+2)

### BEWARE! This allegiedly helps, but it seems to be too greedy/upgrade too many packages that arent just kernel/firmware.
#apt-get -t stretch-backports upgrade
}

#install_repos
#update_system
#install_python
#install_shellcheck
#install_aptfile
#install_perf
#install_kernel_from_backports
install_gcloud  ### TO BE TESTED
install_compute_image_packages
#install_lynis

sudo apt-get autoremove || true
sudo apt-get autoclean || true
popd || exit
