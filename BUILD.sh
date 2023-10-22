#!/bin/bash -eu

# Name: BUILD.sh
# Author: Ladar Levison

# Description: This script installs all of the dependencies needed to 
#   to rebuild the QEMU/Virt/Spice packages for RHEL. It presumes the
#   system is a fresh, near minimal install. And freely makes changes
#   and/or installs packages that may not be needed. It should not be
#   run on a production system, but rather used inside a disposable
#   virtual machine, or container. 

# License: This script is hereby placed in the public domain, AND IS 
#   ROVIDED BY THE AUTHORS 'AS IS' WITHOUT ANY EXPRESS, IMPLIED, OR
#   IMAGINARY WARRANTIES. THIS INCLUDES BUT IS NOT LIMITED TO, THE IMPLIED
#   WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE,
#   ALL OF WHICH ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS
#   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SCRIPT. THIS 
#   APPLIES REGARDLESS OF JURISDICTION, PHYSICAL OR VIRTUAL LOCATION, AND
#   sREMAINS APPLICABLE EVEN IF YOU HAVE BEEN ADVISED OF THE RISKS.

# To build QEMU using vagrant.
# [ "$(basename $PWD)" == "qemu-builder" ] && { vagrant destroy -f && cd ../ && rm -rf qemu-builder/ ; } ; \
# mkdir qemu-builder && cd qemu-builder && vagrant init --minimal generic/alma9 && \
# sed -i "s/^end$/  config.vm.hostname = \"qemu.builder\"\n  config.ssh.forward_x11 = true\n  config.ssh.forward_agent = true\n  config.vm.provider :libvirt do \|v, override\|\n    v.cpus = 12\n    v.cputopology :sockets => '1', :cores => '6', :threads => '2'\n    v.machine_type = 'q35'\n    v.nested = true\n    v.memory = 12384\n    v.video_vram = 512\n  end\nend/g" Vagrantfile && \
# vagrant destroy -f && vagrant up --provider=libvirt && vagrant ssh-config > config && \
# vagrant upload /home/ladar/Documents/Configuration/workstation/alma-9-build-qemu.sh BUILD.sh && \
# vagrant ssh -c 'sudo mv BUILD.sh /root/' && \
# vagrant ssh -c "sudo su -l -c 'time bash -eu /root/BUILD.sh'" && \
# printf "get -r RPMS\n"| sftp -F config default

# If necessary the following will reset the guest environment to a blank slate,
# and then prepare it by installing the official QEMU packages. Once complete,
# it will attempt an install/replace the official packages will the freshly 
# built packages RPMS.
# vagrant destroy -f && vagrant up && vagrant ssh-config > config && \
# vagrant upload /home/ladar/Documents/Configuration/workstation/alma-9-libvirt.sh libvirt.sh && \
# vagrant upload RPMS-v$(date +%Y%m%d)/ RPMS && \
# vagrant ssh -c 'sudo bash -eu libvirt.sh' && \
# vagrant ssh -c 'cd RPMS ; bash -ex INSTALL.sh'

# Otherwise, to install the new RPMs onto the host machine.
# cd RPMS-v$(date +%Y%m%d) && bash -ex INSTALL.sh
export BTRH_EPOCH=2048

# The QEMU socket tests generate a lot of connection requests. To avoid an 
# overflow, which can cause the unit tests to fail, we increase the backlog
# and retry values.
sysctl net.ipv4.tcp_max_syn_backlog=65536 net.ipv4.tcp_syn_retries=60 net.ipv4.tcp_synack_retries=50

# Disable SELinux to avoid potential bugs. 
setenforce 0

mkdir -p /etc/systemd/system.conf.d/
cat <<-EOF > /etc/security/limits.d/50-all.conf
*      soft    memlock    262144
*      hard    memlock    262144
*      soft    nproc      65536
*      hard    nproc      65536
*      soft    nofile     1048576
*      hard    nofile     1048576
*      soft    stack      unlimited
*      hard    stack      unlimited
EOF

cat >/etc/systemd/system.conf.d/10-filelimit.conf <<EOF
[Manager]
DefaultLimitNOFILE=1048576
DefaultLimitNOFILESoft=1048576
DefaultLimitMEMLOCK=268435456
DefaultLimitMEMLOCKSoft=268435456
DefaultLimitSTACK=infinity
DefaultLimitSTACKSoft=infinity
DefaultLimitNPROC=65536
DefaultLimitNPROCSoft=65536
EOF

chcon "system_u:object_r:etc_t:s0" /etc/security/limits.d/50-all.conf
systemctl daemon-reload

ulimit -n 524288
ulimit -l 262144
ulimit -u 65536
ulimit -s unlimited

sed -i '/metadata_expire/d' /etc/dnf/dnf.conf
sed -i '/mirrorlist_expire/d' /etc/dnf/dnf.conf
printf "\nmetadata_expire=9800\nmirrorlist_expire=9800\n\n" >> /etc/dnf/dnf.conf

# Stop/disable the makecache units to avoid conflicts with the DNF commands below.
systemctl disable dnf-makecache.timer dnf-makecache.service &> /dev/null
systemctl stop dnf-makecache.timer dnf-makecache.service &> /dev/null

pidwait dnf || echo "DNF isn't running."

dnf clean all --enablerepo=*
dnf update --quiet --assumeyes && \
dnf --enablerepo=extras --quiet --assumeyes install epel-release && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9 && \
dnf --enablerepo=extras --quiet --assumeyes install elrepo-release && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org && \
dnf install --quiet --assumeyes https://download1.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E "%{?fedora}%{?rhel}").noarch.rpm && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-el-9 && \
dnf install --quiet --assumeyes https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E "%{?fedora}%{?rhel}").noarch.rpm && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-el-9 && \
dnf install --quiet --assumeyes https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E "%{?rhel}").rpm && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi.el$(rpm -E '%{?rhel}')

sed -i -e "s/^[# ]*baseurl/# baseurl/g" /etc/yum.repos.d/almalinux-*.repo
sed -i -e "s/^[# ]*mirrorlist/mirrorlist/g" /etc/yum.repos.d/almalinux-*.repo

sed -i 's/&protocol\=https//g' /etc/yum.repos.d/epel.repo
sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/epel.repo
sed -i 's/&protocol\=https//g' /etc/yum.repos.d/epel-testing.repo
sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/epel-testing.repo
sed -i 's/baseurl/#baseurl/g' /etc/yum.repos.d/epel.repo

sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/elrepo.repo 
sed -i -e "s/^[# ]*mirrorlist/# mirrorlist/g" /etc/yum.repos.d/elrepo.repo 

sed -i 's/baseurl\=http:/baseurl\=https:/g' /etc/yum.repos.d/rpmfusion-free-updates.repo
sed -i 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/rpmfusion-free-updates.repo
sed -i 's/&protocol\=https//g' /etc/yum.repos.d/rpmfusion-free-updates.repo
sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/rpmfusion-free-updates.repo
sed -i 's/baseurl\=http:/baseurl\=https:/g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
sed -i 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
sed -i 's/&protocol\=https//g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
sed -i 's/baseurl\=http:/baseurl\=https:/g' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sed -i 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sed -i 's/&protocol\=https//g' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sed -i 's/baseurl\=http:/baseurl\=https:/g' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
sed -i 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
sed -i 's/&protocol\=https//g' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo

sed -i 's/cdn.remirepo.net/rpms.remirepo.net/g' /etc/yum.repos.d/remi.repo
sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/remi.repo 
sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/remi-safe.repo 
sed -i 's/cdn.remirepo.net/rpms.remirepo.net/g' /etc/yum.repos.d/remi-safe.repo
sed -i 's/cdn.remirepo.net/rpms.remirepo.net/g' /etc/yum.repos.d/remi-modular.repo
sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/remi-modular.repo 

# Try and catch any problems with the repo configurations early, so we don't waste time.
if [ ! $(sudo dnf repolist --quiet appstream 2>&1 | grep -Eo "^appstream") ] || \
[ ! $(sudo dnf repolist --quiet appstream-debuginfo 2>&1 | grep -Eo "^appstream-debuginfo") ] || \
[ ! $(sudo dnf repolist --quiet baseos 2>&1 | grep -Eo "^baseos") ] || \
[ ! $(sudo dnf repolist --quiet baseos-debuginfo 2>&1 | grep -Eo "^baseos-debuginfo") ] || \
[ ! $(sudo dnf repolist --quiet crb 2>&1 | grep -Eo "^crb") ] || \
[ ! $(sudo dnf repolist --quiet crb-debuginfo 2>&1 | grep -Eo "^crb-debuginfo") ] || \
[ ! $(sudo dnf repolist --quiet elrepo 2>&1 | grep -Eo "^elrepo") ] || \
[ ! $(sudo dnf repolist --quiet epel 2>&1 | grep -Eo "^epel") ] || \
[ ! $(sudo dnf repolist --quiet extras 2>&1 | grep -Eo "^extras") ] || \
[ ! $(sudo dnf repolist --quiet plus 2>&1 | grep -Eo "^plus") ] || \
[ ! $(sudo dnf repolist --quiet remi 2>&1 | grep -Eo "^remi") ] || \
[ ! $(sudo dnf repolist --quiet remi-debuginfo 2>&1 | grep -Eo "^remi-debuginfo") ] || \
[ ! $(sudo dnf repolist --quiet remi-modular 2>&1 | grep -Eo "^remi-modular") ] || \
[ ! $(sudo dnf repolist --quiet remi-safe 2>&1 | grep -Eo "^remi-safe") ] || \
[ ! $(sudo dnf repolist --quiet rpmfusion-free-updates 2>&1 | grep -Eo "^rpmfusion-free-updates") ] || \
[ ! $(sudo dnf repolist --quiet rpmfusion-nonfree-updates 2>&1 | grep -Eo "^rpmfusion-nonfree-updates") ]; then
printf "\n\e[1;91m# One of the RHEL/Alma package repositories used by this build script is missing.\e[0;0m\n\n"
exit 1
fi

if [ "$(curl -Lso /dev/null --write-out '%{http_code}' https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/36/Everything/source/tree)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/36/Everything/source/tree/repodata/repomd.xml)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/36/Everything/source/tree)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/36/Everything/source/tree/repodata/repomd.xml)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://mirrors.kernel.org/fedora/releases/38/Everything/source/tree)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://mirrors.kernel.org/fedora/releases/38/Everything/source/tree/repodata/repomd.xml)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://mirrors.kernel.org/fedora/updates/38/Everything/source/tree)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://mirrors.kernel.org/fedora/updates/38/Everything/source/tree/repodata/repomd.xml)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://mirrors.kernel.org/fedora/development/rawhide/Everything/source/tree)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://mirrors.kernel.org/fedora/development/rawhide/Everything/source/tree/repodata/repomd.xml)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://mirrors.kernel.org/fedora/development/rawhide/Modular/source/tree)" != "200" ] || \
[ "$(curl -Lso /dev/null --write-out '%{http_code}' https://mirrors.kernel.org/fedora/development/rawhide/Modular/source/tree/repodata/repomd.xml)" != "200" ]; then
printf "\n\e[1;91m# One of the Fedora source code repositories used by this build script is missing or invalid.\e[0;0m\n\n" ;
exit 1
fi

# As a final step we clean the cache, and reload it so the new GPG keys get approved.
dnf --enablerepo=* clean all && dnf --enablerepo=* --quiet --assumeyes makecache

# Kill all of the extra gpg-agent daemons that get spawned when the RPM PGP keys are imported.
killall gpg-agent

# Update the existing packages. Install the software groups. Install individual packages.
dnf --quiet --assumeyes update && \
dnf --quiet --assumeyes --with-optional \
--enablerepo=baseos --enablerepo=appstream --enablerepo=epel --enablerepo=extras --enablerepo=plus \
--enablerepo=crb --enablerepo=remi --enablerepo=remi-safe --enablerepo=remi-modular --enablerepo=elrepo \
--enablerepo=rpmfusion-free-updates --enablerepo=rpmfusion-nonfree-updates group install \
"Development Tools" "Additional Development" "Platform Development" "RPM Development Tools" "Debugging Tools" \
"Desktop Debugging and Performance Tools" "KDE Software Development" "KDE Plasma Workspaces" \
"KDE Plasma Workspaces" "KDE Frameworks 5 Software Development" && \
dnf --quiet --assumeyes --allowerasing \
--enablerepo=baseos --enablerepo=appstream --enablerepo=epel --enablerepo=extras --enablerepo=plus \
--enablerepo=crb --enablerepo=remi --enablerepo=remi-safe --enablerepo=remi-modular --enablerepo=elrepo \
--enablerepo=rpmfusion-free-updates --enablerepo=rpmfusion-nonfree-updates install \
 acpica-tools alsa-lib-devel asciidoc audit-libs-devel autoconf automake bash bc binutils binutils-devel \
 bison brlapi-devel byacc bzip2-devel cmake ctags cyrus-sasl-devel daxctl-devel dbus-daemon \
 dbus-devel dbus-glib-devel dbus-libs dbus-x11 dbusmenu-qt5-devel device-mapper-multipath-devel diffstat \
 diffutils dosfstools dwarves epel-rpm-macros elfutils elfutils-devel elfutils-libelf-devel expect \
 findutils flex fuse-devel fuse-encfs fuse-overlayfs fuse-sshfs fuse3 fuse3-devel gawk gcc rpm-sign \
 gcc-aarch64-linux-gnu gcc-arm-linux-gnu gcc-c++ gcc-powerpc64-linux-gnu gcc-sparc64-linux-gnu \
 gcc-x86_64-linux-gnu gdb gettext git git-core glib2-devel glib2-static glibc-devel glibc-static glslang \
 gnupg2 gnutls-devel gnutls-utils gstreamer1-devel gstreamer1-plugins-bad-free-devel rpm-build  \
 gstreamer1-plugins-base-devel gstreamer1-plugins-ugly gtk3-devel gzip help2man hmaccalc hostname iasl \
 intltool ipxe-roms-qemu java-devel jna kabi-dw libaio-devel libattr-devel libbpf-devel libcap-devel \
 libcap-ng-devel libcurl-devel libdbusmenu-devel libdbusmenu-gtk2-devel libdbusmenu-gtk3-devel \
 libdbusmenu-jsonloader-devel libdrm-devel libepoxy-devel libfdt-devel libiscsi-devel libjpeg-devel \
 libpng-devel librbd-devel libseccomp-devel libselinux-devel libslirp-devel libssh-devel \
 libtasn1-devel libtool libudev-devel liburing-devel libusbx-devel libuuid-devel libxkbcommon-devel \
 libzstd-devel ltrace lz4-devel lzo-devel m4 make mesa-libgbm-devel meson module-init-tools \
 mtools nasm ncurses-devel net-tools newt-devel numactl-devel opensc openssl openssl-devel opus-devel \
 orc-devel pam-devel patch patchutils pciutils-devel pcre-devel pcre-static pcre2-devel pcsc-lite-devel \
 perl perl-devel perl-ExtUtils-Embed perl-Fedora-VSP perl-generators perl-Test-Harness pesign \
 pipewire-jack-audio-connection-kit-devel pixman-devel pkgconf pkgconf-m4 pkgconf-pkg-config pkgconfig \
 pulseaudio-libs-devel python3-cryptography python3-devel python3-docutils python3-future python3-pytest \
 python3-sphinx python3-sphinx_rtd_theme python3-tomli rdma-core rdma-core-devel redhat-rpm-config \
 rpmconf rpmdevtools rpmlint rpmrebuild rsync SDL2-devel SDL2_image-devel \
 snappy-devel softhsm source-highlight sparse sssd-dbus strace systemd-devel systemtap \
 systemtap-sdt-devel tar tcsh texinfo usbguard-dbus usbredir-devel valgrind valgrind-devel vte291-devel \
 x264-devel x265-devel xauth xdg-dbus-proxy xmlto xorg-x11-util-macros xorriso xz zlib-devel zlib-static \
 gobject-introspection-devel gtk-doc usbutils vala wayland-protocols-devel samba-winbind-clients \
 libnghttp2-devel latexmk python3-sphinx-latex redhat-display-fonts redhat-text-fonts fonts-rpm-macros \
 pyproject-rpm-macros python3-wheel virt-manager libvirt-devel libvirt-client libosinfo gi-docgen \
 python3-typogrify python3-smartypants gi-docgen-fonts selinux-policy-devel policycoreutils-devel \
 libvala vala libvala-devel libssh2 libssh2-devel numactl numactl-devel augeas device-mapper-devel \
 libpcap-devel libarchive-devel libtirpc-devel parted-devel rpcgen sanlock-devel scrub \
 wireshark-devel yajl-devel libsmi sanlock-lib wireshark wireshark-cli sanlock librados-devel \
 librbd-devel file-devel qt5-qtbase-private-devel xdg-user-dirs kf5-kwindowsystem-devel \
 polkit-qt5-1-devel kf5-filesystem kf5-kwindowsystem polkit-qt5-1 krdc-devel \
 libvncserver-devel freerdp freerdp-libs krdc krdc-libs libvncserver libwinpr \
 perl-LockFile-Simple perl-Sys-Virt perl-XML-NamespaceSupport perl-XML-SAX perl-podlators \
 perl-XML-SAX-Base perl-XML-Simple  freerdp-devel kf5-kwallet-devel libsodium-devel \
 libappindicator-gtk3-devel libxkbfile-devel libappindicator-gtk3 libindicator-gtk3 libwinpr-devel \
 xorg-x11-server-devel libXfont2-devel libfontenc-devel gdbm-devel libdaemon-devel \
 libevent-devel python3-gobject-devel xmltoman gdbm tigervnc fltk tigervnc-icons \
 gnome-session gnome-control-center-filesystem libXxf86vm-devel libvdpau-devel \
 libedit-devel libvdpau-trace doxygen doxygen-doxywizard vnstat \
 libcmocka-devel opencryptoki-libs python3-alembic python3-greenlet python3-keylime \
 python3-lark-parser python3-pyasn1 python3-pyasn1-modules python3-sqlalchemy \
 python3-tornado texlive-adjustbox texlive-anysize texlive-appendix \
 texlive-attachfile2 texlive-beamer texlive-breqn texlive-cite texlive-collectbox \
 texlive-collection-latexrecommended texlive-crop texlive-ctable texlive-epstopdf \
 texlive-etoc texlive-euenc texlive-extsizes texlive-fancybox texlive-fancyref \
 texlive-finstrut texlive-footnotehyper texlive-hanging texlive-ifoddpage \
 texlive-import texlive-jknapltx texlive-l3experimental texlive-latexbug \
 texlive-linegoal texlive-lineno texlive-listofitems texlive-ltabptch \
 texlive-lwarp texlive-mathspec texlive-mathtools texlive-mdwtools \
 texlive-metalogo texlive-microtype texlive-mnsymbol texlive-multirow \
 texlive-newfloat texlive-newunicodechar texlive-ntgclass texlive-pdflscape \
 texlive-pdfpages texlive-psfrag texlive-ragged2e texlive-rcs \
 texlive-realscripts texlive-sansmath texlive-sansmathaccent \
 texlive-section texlive-sectsty texlive-seminar texlive-sepnum \
 texlive-stackengine texlive-tabu texlive-textcase texlive-tocloft \
 texlive-translator texlive-typehtml texlive-ucharcat texlive-ulem \
 texlive-xltxtra texlive-xtab wireshark wireshark-cli \
 doxygen-latex json-c-devel libcmocka trousers trousers-devel \
 trousers-static python3-flake8 python3-mccabe gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu \
 python3-pycodestyle python3-pyflakes nfs-utils virtiofsd \
 iscsi-initiator-utils lzop systemd-container mdevctl nethogs kf5-kwallet-devel \
 libappindicator-gtk3-devel libsecret-devel vte291-devel webkit2gtk3-devel webkit2gtk3-jsc-devel \
 kf5-kwindowsystem-devel krdc-devel libseccomp-devel opensc polkit-qt5-1-devel qt5-linguist \
 qt5-qtbase-private-devel qt5-qtmultimedia-devel qt5-qttools-devel wireshark-devel qt5-designer \
 qt5-doctools qt5-qtdeclarative-devel qt5-qttools qt5-qttools-common qt5-qttools-libs-designer \
 qt5-qttools-libs-designercomponents qt5-qttools-libs-help libpcap-devel augeas-devel \
 createrepo_c createrepo_c-libs gjs gperf hivex-devel icoutils jansson-devel libconfig-devel \
 lua-devel lua-rpm-macros netpbm netpbm-progs ocaml ocaml-compiler-libs ocaml-fileutils \
 ocaml-fileutils-devel ocaml-findlib ocaml-findlib-devel ocaml-gettext ocaml-gettext-devel \
 ocaml-hivex ocaml-hivex-devel ocaml-ocamldoc ocaml-runtime perl-Devel-Symdump perl-Locale-gettext \
 perl-Pod-Coverage perl-Test-Pod perl-Test-Pod-Coverage perl-Text-CharWidth perl-Text-WrapI18N \
 perl-YAML-Tiny po4a ruby ruby-default-gems ruby-devel ruby-libs rubygem-bigdecimal rubygem-bundler \
 rubygem-io-console rubygem-irb rubygem-json rubygem-power_assert rubygem-psych rubygem-rake \
 rubygem-rdoc rubygem-test-unit rubygems supermin-devel perl-hivex attr cryptsetup dhclient \
 syslinux syslinux-extlinux dhcp-common ipcalc syslinux-extlinux-nonlinux syslinux-nonlinux \
 geolite2-city geolite2-country perl-Expect perl-IO-Tty libldm-devel libldm php-devel \
 php-cli php-common php-fedora-autoloader php-nikic-php-parser4 golang golang-src golang-bin \
 debootstrap keyrings-filesystem dpkg debian-keyring ubu-keyring hfsplus-tools kpartx \
  dbus-x11 xorg-x11-xauth xorg-x11-server-common xorg-x11-server-Xorg xorg-x11-server-Xwayland \
 libvala vala libvala-devel libssh2 libssh2-devel numactl numactl-devel augeas device-mapper-devel\
 libarchive-devel libtirpc-devel parted-devel rpcgen sanlock-devel scrub \
 yajl-devel libsmi sanlock-lib  sanlock librados-devel librbd-devel mlocate cronie \
 cronie-anacron gedit gedit-plugin-bookmarks gedit-plugin-bracketcompletion \
 gedit-plugin-codecomment gedit-plugin-colorpicker gedit-plugin-colorschemer \
 gedit-plugin-commander gedit-plugin-drawspaces gedit-plugin-findinfiles \
 gedit-plugin-joinlines gedit-plugin-multiedit gedit-plugin-sessionsaver \
 gedit-plugin-smartspaces gedit-plugin-synctex gedit-plugin-terminal \
 gedit-plugin-textsize gedit-plugin-translate gedit-plugin-wordcompletion gedit-plugins \
 gedit-plugins-data gspell gvfs http-parser libpeas-gtk libpeas-loader-python3 xterm \
 xterm-resize zenity libpeas gtkspell3 ctpl-libs geany geany-devel geany-libgeany \
 geany-plugins-addons geany-plugins-autoclose geany-plugins-automark geany-plugins-codenav \
 geany-plugins-commander geany-plugins-common geany-plugins-debugger \
 geany-plugins-defineformat geany-plugins-geanyctags geany-plugins-geanydoc \
 geany-plugins-geanyextrasel geany-plugins-geanygendoc geany-plugins-geanyinsertnum \
 geany-plugins-geanymacro geany-plugins-geanyminiscript geany-plugins-geanynumberedbookmarks \
 geany-plugins-geanypg geany-plugins-geanyprj geany-plugins-geanyvc geany-plugins-geniuspaste \
 geany-plugins-git-changebar geany-plugins-keyrecord geany-plugins-latex \
 geany-plugins-lineoperations geany-plugins-lipsum geany-plugins-markdown geany-plugins-overview \
 geany-plugins-pairtaghighlighter geany-plugins-pohelper geany-plugins-pretty-printer \
 geany-plugins-projectorganizer geany-plugins-scope geany-plugins-sendmail geany-plugins-shiftcolumn \
 geany-plugins-spellcheck geany-plugins-tableconvert geany-plugins-treebrowser \
 geany-plugins-updatechecker geany-plugins-vimode geany-plugins-workbench geany-plugins-xmlsnippets \
 gedit-plugin-editorconfig libgit2 python3-editorconfig meld \
 ntfs-3g ntfsprogs ntfs-3g-system-compression ntfs-3g-libs which zerofree hexedit perl-JSON \
 clevis clevis-luks jq jose libjose luksmeta libluksmeta oniguruma libnbd-devel \
 kernel-cross-headers lm_sensors lm_sensors-libs lm_sensors-devel opencl-headers opencl-filesystem \
 ocl-icd ocl-icd-devel clinfo intel-gmmlib libxshmfence parallel xcb-util-devel \
 libpmem2 libpmem2-devel libpmem libpmem-devel libpmemblk libpmemblk-devel \
 libpmemlog libpmemlog-devel libpmemobj libpmemobj++-devel libpmemobj++-doc \
 libpmemobj-devel libpmempool libpmempool-devel \
 libgcrypt libgcrypt-devel libgpg-error nettle nettle-devel \
 tpm2-tools tpm2-tss tpm2-tss-devel tpm2-pkcs11 tpm2-pkcs11-tools \
 swtpm swtpm-libs swtpm-tools \
 libtpms tss2 tss2-devel rng-tools \
 seabios seabios-bin seavgabios-bin libsmbios \
 llvm llvm-toolset llvm-static llvm-test llvm-devel clang-devel \
 clang-analyzer clang-libs clang-resource-filesystem clang-tools-extra python3-clang \
 spirv-tools spirv-tools-libs spirv-headers-devel spirv-tools-devel || exit 1

curl -LOs https://archive.org/download/libblkio-eln125/libblkio-1.2.2-2.eln125.x86_64.rpm
curl -LOs https://archive.org/download/libblkio-eln125/libblkio-devel-1.2.2-2.eln125.x86_64.rpm

sha256sum -c <<-EOF || { printf "\n\e[1;91m# The libblkio download failed.\e[0;0m\n\n" ; exit 1 ; }
637892248b0875e1b2ca2e14039ca20fa1a7d91f765385040f58e8487dca83ad  libblkio-1.2.2-2.eln125.x86_64.rpm
6f0ab5cf409c448b32ee9bdf6875d2e8c7557475dc294edf80fbcc478516c25e  libblkio-devel-1.2.2-2.eln125.x86_64.rpm
EOF

dnf --quiet --assumeyes --enablerepo=epel --enablerepo=extras --enablerepo=plus --enablerepo=crb install \
capstone capstone-devel python3-capstone \
libblkio-1.2.2-2.eln125.x86_64.rpm libblkio-devel-1.2.2-2.eln125.x86_64.rpm || \
{ printf "\n\e[1;91m# The capstone/libblkio install failed.\e[0;0m\n\n" ; exit 1 ; }

rm --force libblkio-1.2.2-2.eln125.x86_64.rpm libblkio-devel-1.2.2-2.eln125.x86_64.rpm 

# Enable the locate database update cron job.
echo "* * * * * root command bash -c '/usr/bin/updatedb'" | sudo tee /etc/cron.d/updatedb > /dev/null

# Update the SSH server config and restart the service.
sed -i 's/.*X11Forwarding.*/X11Forwarding yes/g' /etc/ssh/sshd_config
sed -i 's/.*X11UseLocalhost.*/X11UseLocalhost no/g' /etc/ssh/sshd_config
sed -i 's/.*X11DisplayOffset.*/X11DisplayOffset 10/g' /etc/ssh/sshd_config
sudo systemctl restart sshd.service 2> /dev/null

# Disable the command aliases since they sometimes break compile logic.
sed -i '/alias/d' $HOME/.cshrc
sed -i '/alias/d' $HOME/.tcshrc
sed -i '/alias/d' $HOME/.bashrc

[ ! -d /root/.parallel/ ] && mkdir /root/.parallel/
touch /root/.parallel/will-cite
chmod 755 /root/.parallel/
chmod 644 /root/.parallel/will-cite

# Mock build user/group setup.
groupadd mock
useradd mockbuild 
usermod -aG mock mockbuild 

## Start the build phase.
mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Notify the user that the setup is finished.
printf "\e[1;92m# Software install is complete.\e[0;0m\n"

# Download the source package files. Note these URLs point to rawhide, and are transient.
cd ~/rpmbuild/SRPMS/

# fc37 repo
# dnf download --quiet --disablerepo=* --repofrompath="fc37,https://mirrors.kernel.org/fedora/releases/37/Everything/source/tree/" --source phodav libsoup3 

# Use the QXL driver source code from RHEL v8.
# curl -fso xorg-x11-drv-qxl-0.1.5-11.el8.src.rpm https://mirrors.lavabit.com/alma-archive/8.7/AppStream/Source/Packages/xorg-x11-drv-qxl-0.1.5-11.el8.src.rpm
# sha256sum -c <<-EOF || { printf "\n\e[1;91m# The xorg-x11-drv-qxl download failed.\e[0;0m\n\n" ; exit 1 ; }
# 1c7b841d20cc9da69c1ff9716d4a0231b3d35e3a88145786b3da892246f73e31  xorg-x11-drv-qxl-0.1.5-11.el8.src.rpm
# EOF

# Fedora Release Repo
# https://mirrors.kernel.org/fedora/linux/releases/##/Everything/source/tree
# Fedora Update Repo
# https://mirrors.kernel.org/fedora/updates/##/Everything/source/tree

# Fedora Rawgude Repo
# https://mirrors.kernel.org/fedora/development/rawhide/Everything/source/tree

# Archived Fedora Release Repo
# https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/##/Everything/source/tree
# Archived Fedora Update Repo
# https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/##/Everything/source/tree


# To enable the Mesa OpenCL driver, we need libclc. But even though libclc from fc37 matches up with
# the el9 version of llvm, but also requires the spirv-llvm-translator-tools package, which provides 
# the /usr/bin/llvm-spirv tool.

dnf download --quiet --source mesa avahi pcre2 libguestfs guestfs-tools || exit 1

dnf download --quiet --disablerepo=* --repofrompath="fc36,https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/36/Everything/source/tree" --repofrompath="fc36-updates,https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/36/Everything/source/tree" --source phodav spice-gtk || exit 1

# dnf download --quiet --disablerepo=* --repofrompath="fc37,https://mirrors.kernel.org/fedora/releases/37/Everything/source/tree" --repofrompath="fc37-updates,https://mirrors.kernel.org/fedora/updates/37/Everything/source/tree" --source PACKAGE || exit 1

dnf download --quiet --disablerepo=* --repofrompath="fc38,https://mirrors.kernel.org/fedora/releases/38/Everything/source/tree" --repofrompath="fc38-updates,https://mirrors.kernel.org/fedora/updates/38/Everything/source/tree" --source xorg-x11-drv-intel xorg-x11-drv-nouveau xorg-x11-drv-qxl libXvMC  || exit 1

dnf download --quiet --disablerepo=* --repofrompath="rawhide,https://mirrors.kernel.org/fedora/development/rawhide/Everything/source/tree" --source edk2 fcode-utils libcacard lzfse openbios python-pefile python-virt-firmware SLOF qemu spice spice-protocol virglrenderer virt-manager virt-viewer virt-backup passt libvirt libvirt-glib libvirt-dbus libvirt-python osinfo-db osinfo-db-tools libosinfo qt-virt-manager qtermwidget lxqt-build-tools liblxqt libqtxdg chunkfs gtk-vnc remmina || exit 1
rpm -i *src.rpm || exit 1

# The network intensive tasks are finished.
printf "\e[1;92m# Source download is done.\e[0;0m\n"

# Patch the source/spec files.
cd ~/rpmbuild/SPECS/

git config --global init.defaultBranch master && git config --global user.name default && git config --global user.email default || exit 1
git init && git add *.spec && git commit -m "Default spec files." || exit 1

patch -p1 <<-PATCH 
diff --git a/SLOF.spec b/SLOF.spec
index bb51fbc..24b43ce 100644
--- a/SLOF.spec
+++ b/SLOF.spec
@@ -6,12 +6,8 @@
 # Disable debuginfo because it is of no use to us.
 %global debug_package %{nil}
 
-%if 0%{?fedora:1}
 %define cross 1
 %define targetdir qemu
-%else
-%define targetdir qemu-kvm
-%endif
 
 Name:           SLOF
 Version:        %{gittagdate}
PATCH

patch -p1 <<-PATCH 
diff --git a/virt-viewer.spec b/virt-viewer.spec
index 0284701..2453c04 100644
--- a/virt-viewer.spec
+++ b/virt-viewer.spec
@@ -2,7 +2,7 @@
 
 %if 0%{?rhel} >= 9
 %global with_govirt 0
-%global with_spice 0
+%global with_spice 1
 %else
 # Disabled since it is still stuck on soup2
 %global with_govirt 0
PATCH

patch -p1 <<-PATCH
diff --git a/liblxqt.spec b/liblxqt.spec
index 64a52b9..fa175d8 100644
--- a/liblxqt.spec
+++ b/liblxqt.spec
@@ -108,6 +108,8 @@ touch -r %{SOURCE1} %{buildroot}%{rpm_macros_dir}/macros.lxqt
 %license COPYING
 %doc AUTHORS README.md
 %dir %{_datadir}/lxqt/translations/%{name}
+%{_datadir}/lxqt/translations/liblxqt/liblxqt_ast.qm
+%{_datadir}/lxqt/translations/liblxqt/liblxqt_arn.qm
 
 %changelog
 * Thu Jan 19 2023 Fedora Release Engineering <releng@fedoraproject.org> - 1.2.0-2
PATCH

patch -p1 <<-PATCH
diff --git a/libvirt-python.spec b/libvirt-python.spec
index c45fa38..e8f4ae7 100644
--- a/libvirt-python.spec
+++ b/libvirt-python.spec
@@ -19,7 +19,7 @@ Release: 1%{?dist}
 Source0: https://libvirt.org/sources/python/%{name}-%{version}.tar.gz
 Url: https://libvirt.org
 License: LGPL-2.1-or-later
-BuildRequires: libvirt-devel == %{version}
+BuildRequires: libvirt-devel >= %{version}
 BuildRequires: python3-devel
 BuildRequires: python3-pytest
 BuildRequires: python3-lxml
PATCH

patch -p1 <<-PATCH
diff --git a/qtermwidget.spec b/qtermwidget.spec
index e93ec2e..a199bbc 100644
--- a/qtermwidget.spec
+++ b/qtermwidget.spec
@@ -54,15 +54,22 @@ This package provides translations for the qtermwidget package.
 %if 0%{?el7}
 scl enable devtoolset-7 - <<\\EOF
 %endif
-%{cmake_lxqt} -DPULL_TRANSLATIONS=NO ..
 
-make %{?_smp_mflags} -C %{_vpath_builddir}
+mkdir build
+cd build
+
+%cmake3 -DPULL_TRANSLATIONS=NO ..
+
+%cmake_build
+
 %if 0%{?el7}
 EOF
 %endif
 
 %install
-make install/fast DESTDIR=%{buildroot} -C %{_vpath_builddir}
+cd build
+%cmake_install
+
 %find_lang qtermwidget --with-qt
 
 %ldconfig_scriptlets
@@ -81,7 +88,7 @@ make install/fast DESTDIR=%{buildroot} -C %{_vpath_builddir}
 %{_libdir}/cmake/%{name}%{SOVERSION}
 
 
-%files l10n -f qtermwidget.lang
+%files l10n -f build/qtermwidget.lang
 %license LICENSE
 %doc AUTHORS CHANGELOG README.md
 %dir %{_datadir}/qtermwidget5/translations
PATCH

# Patch the avahi spec file so we can silence the syntax warnings.
# patch -p1 <<-PATCH
# diff --git a/avahi.spec b/avahi.spec
# index fde84ff..463df9d 100644
# --- a/avahi.spec
# +++ b/avahi.spec
# @@ -48,7 +48,7 @@
 
#  Name:             avahi
#  Version:          0.8
# -Release:          12%{?dist}.1
# +Release:          12%{?dist}.${BTRH_EPOCH}
#  Summary:          Local network service discovery
#  License:          LGPLv2+
#  URL:              http://avahi.org
# @@ -122,7 +122,7 @@ BuildRequires:    gcc-c++
#  Source0:          https://github.com/lathiat/avahi/archive/%{version}-%{beta}.tar.gz#/%{name}-%{version}-%{beta}.tar.gz
#  %else
#  Source0:          https://github.com/lathiat/avahi/releases/download/v%{version}/avahi-%{version}.tar.gz
# -#Source0:         http://avahi.org/download/avahi-%{version}.tar.gz
# +#Source0:         http://avahi.org/download/avahi-% {version}.tar.gz
#  %endif
 
#  ## upstream patches
# @@ -206,7 +206,7 @@ This library contains a GObject wrapper for the Avahi API
#  Summary:          Libraries and header files for Avahi GObject development
#  Requires:         %{name}-devel%{?_isa} = %{version}-%{release}
#  Requires:         %{name}-gobject%{?_isa} = %{version}-%{release}
# -#Requires:         %{name}-glib-devel = %{version}-%{release}
# +#Requires:         % {name}-glib-devel = % {version}-% {release}
 
#  %description gobject-devel
#  The avahi-gobject-devel package contains the header files and libraries
# @@ -236,7 +236,7 @@ Summary:          Libraries and header files for Avahi UI development
#  Requires:         %{name}-devel%{?_isa} = %{version}-%{release}
#  Requires:         %{name}-ui%{?_isa} = %{version}-%{release}
#  Requires:         %{name}-ui-gtk3%{?_isa} = %{version}-%{release}
# -#Requires:         %{name}-glib-devel = %{version}-%{release}
# +#Requires:         % {name}-glib-devel = % {version}-% {release}
 
#  %description ui-devel
#  The avahi-ui-devel package contains the header files and libraries
# @@ -351,7 +351,7 @@ necessary for developing programs using avahi.
#  %package compat-howl
#  Summary:          Libraries for howl compatibility
#  Requires:         %{name}-libs%{?_isa} = %{version}-%{release}
# -Obsoletes:        howl-libs
# +Obsoletes:        howl-libs <= 10000
#  Provides:         howl-libs
 
#  %description compat-howl
# @@ -361,7 +361,7 @@ Libraries that are compatible with those provided by the howl package.
#  Summary:          Header files for development with the howl compatibility libraries
#  Requires:         %{name}-compat-howl%{?_isa} = %{version}-%{release}
#  Requires:         %{name}-devel%{?_isa} = %{version}-%{release}
# -Obsoletes:        howl-devel
# +Obsoletes:        howl-devel <= 10000
#  Provides:         howl-devel
 
#  %description compat-howl-devel
# @@ -719,15 +719,15 @@ exit 0
 
#  %files gobject
#  %{_libdir}/libavahi-gobject.so.*
# -#%{_libdir}/girepository-1.0/Avahi-0.6.typelib
# -#%{_libdir}/girepository-1.0/AvahiCore-0.6.typelib
# +### % {_libdir}/girepository-1.0/Avahi-0.6.typelib
# +### % {_libdir}/girepository-1.0/AvahiCore-0.6.typelib
 
#  %files gobject-devel
#  %{_libdir}/libavahi-gobject.so
#  %{_includedir}/avahi-gobject
#  %{_libdir}/pkgconfig/avahi-gobject.pc
# -#%{_datadir}/gir-1.0/Avahi-0.6.gir
# -#%{_datadir}/gir-1.0/AvahiCore-0.6.gir
# +### % {_datadir}/gir-1.0/Avahi-0.6.gir
# +### % {_datadir}/gir-1.0/AvahiCore-0.6.gir
 
#  %if %{without bootstrap}
#  %files ui
# PATCH

patch -p1 <<-PATCH
diff --git a/avahi.spec b/avahi.spec
index fde84ff..463df9d 100644
--- a/avahi.spec
+++ b/avahi.spec
@@ -351,7 +351,7 @@ necessary for developing programs using avahi.
 %package compat-howl
 Summary:          Libraries for howl compatibility
 Requires:         %{name}-libs%{?_isa} = %{version}-%{release}
-Obsoletes:        howl-libs
+Obsoletes:        howl-libs <= 10000
 Provides:         howl-libs
 
 %description compat-howl
@@ -361,7 +361,7 @@ Libraries that are compatible with those provided by the howl package.
 Summary:          Header files for development with the howl compatibility libraries
 Requires:         %{name}-compat-howl%{?_isa} = %{version}-%{release}
 Requires:         %{name}-devel%{?_isa} = %{version}-%{release}
-Obsoletes:        howl-devel
+Obsoletes:        howl-devel <= 10000
 Provides:         howl-devel
 
 %description compat-howl-devel
@@ -719,15 +719,15 @@ exit 0
 
 %files gobject
 %{_libdir}/libavahi-gobject.so.*
-#%{_libdir}/girepository-1.0/Avahi-0.6.typelib
-#%{_libdir}/girepository-1.0/AvahiCore-0.6.typelib
+### % {_libdir}/girepository-1.0/Avahi-0.6.typelib
+### % {_libdir}/girepository-1.0/AvahiCore-0.6.typelib
 
 %files gobject-devel
 %{_libdir}/libavahi-gobject.so
 %{_includedir}/avahi-gobject
 %{_libdir}/pkgconfig/avahi-gobject.pc
-#%{_datadir}/gir-1.0/Avahi-0.6.gir
-#%{_datadir}/gir-1.0/AvahiCore-0.6.gir
+### % {_datadir}/gir-1.0/Avahi-0.6.gir
+### % {_datadir}/gir-1.0/AvahiCore-0.6.gir
 
 %if %{without bootstrap}
 %files ui
PATCH

patch -p1 <<-PATCH 
diff --git a/remmina.spec b/remmina.spec
index 978bc3c..82c7dd8 100644
--- a/remmina.spec
+++ b/remmina.spec
@@ -29,10 +29,8 @@ BuildRequires: libsodium-devel
 BuildRequires: python3-devel
 BuildRequires: xdg-utils
 BuildRequires: pkgconfig(appindicator3-0.1)
-%if 0%{?fedora} || 0%{?rhel} == 8
 BuildRequires: pkgconfig(avahi-ui)
 BuildRequires: pkgconfig(avahi-ui-gtk3)
-%endif
 BuildRequires: pkgconfig(freerdp2)
 BuildRequires: pkgconfig(gtk+-3.0)
 BuildRequires: pkgconfig(json-glib-1.0)
@@ -45,9 +43,7 @@ BuildRequires: pkgconfig(libsoup-2.4)
 BuildRequires: pkgconfig(libssh) >= 0.8.0
 BuildRequires: pkgconfig(libvncserver)
 BuildRequires: pkgconfig(libpcre2-8)
-%if 0%{?fedora} || 0%{?rhel} == 8
 BuildRequires: pkgconfig(spice-client-gtk-3.0)
-%endif
 BuildRequires: pkgconfig(vte-2.91)
 %if 0%{?fedora} >= 37
 BuildRequires: pkgconfig(webkit2gtk-4.1)
@@ -136,7 +132,6 @@ computers in front of either large monitors or tiny net-books.
 This package contains the VNC plugin for the Remmina remote desktop
 client.
 
-%if 0%{?fedora} || 0%{?rhel} == 8
 %package plugins-spice
 Summary: SPICE plugin for Remmina Remote Desktop Client
 Requires: %{name}%{?_isa} = %{version}-%{release}
@@ -148,7 +143,6 @@ computers in front of either large monitors or tiny net-books.
 
 This package contains the SPICE plugin for the Remmina remote desktop
 client.
-%endif
 
 %package plugins-www
 Summary: WWW plugin for Remmina Remote Desktop Client
@@ -221,11 +215,7 @@ that shows up under the display manager session menu.
     -DCMAKE_INSTALL_LIBDIR=%{_lib} \\
     -DCMAKE_INSTALL_PREFIX=%{_prefix} \\
     -DHAVE_LIBAPPINDICATOR=ON \\
-%if 0%{?fedora} || 0%{?rhel} == 8
     -DWITH_AVAHI=ON \\
-%else
-    -DWITH_AVAHI=OFF \\
-%endif
     -DWITH_FREERDP=ON \\
     -DWITH_GCRYPT=ON \\
     -DWITH_GETTEXT=ON \\
@@ -234,11 +224,7 @@ that shows up under the display manager session menu.
     -DWITH_LIBSSH=ON \\
     -DWITH_NEWS=OFF \\
     -DWITH_PYTHONLIBS=ON \\
-%if 0%{?fedora} || 0%{?rhel} == 8
     -DWITH_SPICE=ON \\
-%else
-    -DWITH_SPICE=OFF \\
-%endif
     -DWITH_VTE=ON \\
 %if 0%{?fedora} || 0%{?rhel} == 8
     -DWITH_X2GO=ON
@@ -301,12 +287,10 @@ appstream-util validate-relax --nonet %{buildroot}/%{_datadir}/metainfo/*.appdat
 %{_datadir}/icons/hicolor/*/emblems/org.remmina.Remmina-vnc-ssh-symbolic.svg
 %{_datadir}/icons/hicolor/*/emblems/org.remmina.Remmina-vnc-symbolic.svg
 
-%if 0%{?fedora} || 0%{?rhel} == 8
 %files plugins-spice
 %{_libdir}/remmina/plugins/remmina-plugin-spice.so
 %{_datadir}/icons/hicolor/*/emblems/org.remmina.Remmina-spice-ssh-symbolic.svg
 %{_datadir}/icons/hicolor/*/emblems/org.remmina.Remmina-spice-symbolic.svg
-%endif
 
 %files plugins-www
 %{_libdir}/remmina/plugins/remmina-plugin-www.so
PATCH

patch -p1 <<-PATCH
diff --git a/libguestfs.spec b/libguestfs.spec
index 17eee1b..a5ca381 100644
--- a/libguestfs.spec
+++ b/libguestfs.spec
@@ -141,10 +141,8 @@ BuildRequires: rpm-devel
 BuildRequires: cpio
 BuildRequires: libconfig-devel
 BuildRequires: xz-devel
-%if !0%{?rhel}
 BuildRequires: zip
 BuildRequires: unzip
-%endif
 BuildRequires: systemd-units
 BuildRequires: netpbm-progs
 BuildRequires: icoutils
@@ -154,9 +152,7 @@ BuildRequires: perl(Expect)
 %endif
 BuildRequires: libacl-devel
 BuildRequires: libcap-devel
-%if !0%{?rhel}
 BuildRequires: libldm-devel
-%endif
 BuildRequires: jansson-devel
 BuildRequires: systemd-devel
 BuildRequires: bash-completion
@@ -228,10 +224,8 @@ BuildRequires: clevis-luks
 BuildRequires: coreutils
 BuildRequires: cpio
 BuildRequires: cryptsetup
-%if !0%{?rhel}
 BuildRequires: curl
 BuildRequires: debootstrap
-%endif
 BuildRequires: dhclient
 BuildRequires: diffutils
 BuildRequires: dosfstools
@@ -245,24 +239,18 @@ BuildRequires: gfs2-utils
 %endif
 BuildRequires: grep
 BuildRequires: gzip
-%if !0%{?rhel}
 %ifnarch ppc
 BuildRequires: hfsplus-tools
 %endif
-%endif
 BuildRequires: hivex-libs
 BuildRequires: iproute
 BuildRequires: iputils
 BuildRequires: kernel
 BuildRequires: kmod
-%if !0%{?rhel}
 BuildRequires: kpartx
-%endif
 BuildRequires: less
 BuildRequires: libcap
-%if !0%{?rhel}
 BuildRequires: libldm
-%endif
 BuildRequires: libselinux
 BuildRequires: libxml2
 BuildRequires: lsof
@@ -270,9 +258,7 @@ BuildRequires: lsscsi
 BuildRequires: lvm2
 BuildRequires: lzop
 BuildRequires: mdadm
-%if !0%{?rhel}
 BuildRequires: ntfs-3g ntfsprogs ntfs-3g-system-compression
-%endif
 BuildRequires: openssh-clients
 BuildRequires: parted
 BuildRequires: pciutils
@@ -298,15 +284,11 @@ BuildRequires: tar
 BuildRequires: udev
 BuildRequires: util-linux
 BuildRequires: vim-minimal
-%if !0%{?rhel}
 BuildRequires: which
-%endif
 BuildRequires: xfsprogs
 BuildRequires: xz
 BuildRequires: yajl
-%if !0%{?rhel}
 BuildRequires: zerofree
-%endif
 %if !0%{?rhel}
 %ifnarch %{arm} aarch64 s390 s390x riscv64
 # http://zfs-fuse.net/issues/94
@@ -349,15 +331,13 @@ Requires:      xz
 
 # For qemu direct and libvirt backends.
 Requires:      qemu-kvm-core
-%if !0%{?rhel}
 Suggests:      qemu-block-curl
+%if !0%{?rhel}
 Suggests:      qemu-block-gluster
-Suggests:      qemu-block-iscsi
 %endif
+Suggests:      qemu-block-iscsi
 Suggests:      qemu-block-rbd
-%if !0%{?rhel}
 Suggests:      qemu-block-ssh
-%endif
 Recommends:    libvirt-daemon-config-network
 Requires:      libvirt-daemon-driver-qemu >= 7.1.0
 Requires:      libvirt-daemon-driver-secret
@@ -383,7 +363,6 @@ Conflicts:     libguestfs-winsupport
 Conflicts:     libguestfs-winsupport < 7.2
 %endif
 
-
 %description
 Libguestfs is a library for accessing and modifying virtual machine
 disk images.  http://libguestfs.org
@@ -398,14 +377,12 @@ For enhanced features, install:
 %if !0%{?rhel}
      libguestfs-forensics  adds filesystem forensics support
           libguestfs-gfs2  adds Global Filesystem (GFS2) support
-       libguestfs-hfsplus  adds HFS+ (Mac filesystem) support
 %endif
+       libguestfs-hfsplus  adds HFS+ (Mac filesystem) support
  libguestfs-inspect-icons  adds support for inspecting guest icons
         libguestfs-rescue  enhances virt-rescue shell with more tools
          libguestfs-rsync  rsync to/from guest filesystems
-%if !0%{?rhel}
            libguestfs-ufs  adds UFS (BSD) support
-%endif
            libguestfs-xfs  adds XFS support
 %if !0%{?rhel}
            libguestfs-zfs  adds ZFS support
@@ -487,7 +464,6 @@ disk images containing GFS2.
 %endif
 
 
-%if !0%{?rhel}
 %ifnarch ppc
 %package hfsplus
 Summary:       HFS+ support for %{name}
@@ -498,7 +474,6 @@ Requires:      %{name}%{?_isa} = %{epoch}:%{version}-%{release}
 This adds HFS+ support to %{name}.  Install it if you want to process
 disk images containing HFS+ / Mac OS Extended filesystems.
 %endif
-%endif
 
 
 %package rescue
@@ -522,7 +497,6 @@ This adds rsync support to %{name}.  Install it if you want to use
 rsync to upload or download files into disk images.
 
 
-%if !0%{?rhel}
 %package ufs
 Summary:       UFS (BSD) support for %{name}
 License:       LGPLv2+
@@ -531,7 +505,6 @@ Requires:      %{name}%{?_isa} = %{epoch}:%{version}-%{release}
 %description ufs
 This adds UFS support to %{name}.  Install it if you want to process
 disk images containing UFS (BSD filesystems).
-%endif
 
 
 %package xfs
@@ -683,7 +656,6 @@ This package is needed if you want to write software using the
 GObject bindings.  It also contains GObject Introspection information.
 
 
-%if !0%{?rhel}
 %package vala
 Summary:       Vala for %{name}
 Requires:      %{name}-devel%{?_isa} = %{epoch}:%{version}-%{release}
@@ -692,7 +664,6 @@ Requires:      vala
 
 %description vala
 %{name}-vala contains GObject bindings for %{name}.
-%endif
 
 
 
@@ -765,9 +736,6 @@ sed -e "s|/var/cache/yum|\$(pwd)/cachedir|" -e "s|/var/cache/dnf|\$(pwd)/cachedir|
 extra=--with-supermin-packager-config=\$(pwd)/yum.conf
 
 %{configure} \\
-%if 0%{?rhel} && !0%{?eln}
-  QEMU=%{_libexecdir}/qemu-kvm \\
-%endif
   PYTHON=%{__python3} \\
   --with-default-backend=libvirt \\
   --enable-appliance-format-auto \\
@@ -776,9 +744,7 @@ extra=--with-supermin-packager-config=\$(pwd)/yum.conf
 %else
   --with-extra="rhel=%{rhel},release=%{release},libvirt" \\
 %endif
-%if 0%{?rhel} && !0%{?eln}
   --with-qemu="qemu-kvm qemu-system-%{_build_arch} qemu" \\
-%endif
 %ifnarch %{golang_arches}
   --disable-golang \\
 %endif
@@ -850,28 +816,19 @@ function move_to
     echo "\$1" >> "\$2"
 }
 
-%if !0%{?rhel}
-move_to curl            zz-packages-dib
-move_to debootstrap     zz-packages-dib
-move_to kpartx          zz-packages-dib
-move_to qemu-img        zz-packages-dib
-move_to which           zz-packages-dib
-%else
-remove curl
-remove debootstrap
-remove kpartx
-remove qemu-img
-remove which
-%endif
 %if !0%{?rhel}
 move_to sleuthkit       zz-packages-forensics
 move_to gfs2-utils      zz-packages-gfs2
-move_to hfsplus-tools   zz-packages-hfsplus
 %else
 remove sleuthkit
 remove gfs2-utils
-remove hfsplus-tools
 %endif
+move_to curl            zz-packages-dib
+move_to debootstrap     zz-packages-dib
+move_to kpartx          zz-packages-dib
+move_to qemu-img        zz-packages-dib
+move_to which           zz-packages-dib
+move_to hfsplus-tools   zz-packages-hfsplus
 move_to iputils         zz-packages-rescue
 move_to lsof            zz-packages-rescue
 move_to openssh-clients zz-packages-rescue
@@ -888,11 +845,9 @@ move_to zfs-fuse        zz-packages-zfs
 remove zfs-fuse
 %endif
 
-%if !0%{?rhel}
 # On Fedora you need kernel-modules-extra to be able to mount
 # UFS (BSD) filesystems.
 echo "kernel-modules-extra" > zz-packages-ufs
-%endif
 
 popd
 
@@ -986,12 +941,10 @@ rm ocaml/html/.gitignore
 %{_libdir}/guestfs/supermin.d/zz-packages-gfs2
 %endif
 
-%if !0%{?rhel}
 %ifnarch ppc
 %files hfsplus
 %{_libdir}/guestfs/supermin.d/zz-packages-hfsplus
 %endif
-%endif
 
 %files rsync
 %{_libdir}/guestfs/supermin.d/zz-packages-rsync
@@ -1001,10 +954,8 @@ rm ocaml/html/.gitignore
 %{_bindir}/virt-rescue
 %{_mandir}/man1/virt-rescue.1*
 
-%if !0%{?rhel}
 %files ufs
 %{_libdir}/guestfs/supermin.d/zz-packages-ufs
-%endif
 
 %files xfs
 %{_libdir}/guestfs/supermin.d/zz-packages-xfs
@@ -1105,11 +1056,9 @@ rm ocaml/html/.gitignore
 %{_mandir}/man3/guestfs-gobject.3*
 
 
-%if !0%{?rhel}
 %files vala
 %{_datadir}/vala/vapi/libguestfs-gobject-1.0.deps
 %{_datadir}/vala/vapi/libguestfs-gobject-1.0.vapi
-%endif
 
 
 %ifarch %{golang_arches}
@@ -5008,3 +4957,4 @@ rm ocaml/html/.gitignore
 
 * Sat Apr  4 2009 Richard Jones <rjones@redhat.com> - 0.9.9-1
 - Initial build.
+
PATCH

# # QEMU 7.2.6 PATCH
# patch -p1 <<-PATCH
# diff --git a/qemu.spec b/qemu.spec
# index 7090e51..c791c9e 100644
# --- a/qemu.spec
# +++ b/qemu.spec
# @@ -14,11 +14,13 @@
#  %global need_qemu_kvm 0
#  %ifarch %{ix86}
#  %global kvm_package   system-x86
# +%global kvm_target    i386
#  # need_qemu_kvm should only ever be used by x86
#  %global need_qemu_kvm 1
#  %endif
#  %ifarch x86_64
#  %global kvm_package   system-x86
# +%global kvm_target    x86_64
#  # need_qemu_kvm should only ever be used by x86
#  %global need_qemu_kvm 1
#  %endif
# @@ -55,7 +57,7 @@
#  %global user_static 1
#  %if 0%{?rhel}
#  # EPEL/RHEL do not have required -static builddeps
# -%global user_static 0
# +%global user_static 1
#  %endif
 
#  %global have_kvm 0
# @@ -70,12 +72,10 @@
#  %endif
 
#  # Matches spice ExclusiveArch
# -%global have_spice 1
#  %ifnarch %{ix86} x86_64 %{arm} aarch64
#  %global have_spice 0
# -%endif
# -%if 0%{?rhel} >= 9
# -%global have_spice 0
# +%else
# +%global have_spice 1
#  %endif
 
#  # Matches xen ExclusiveArch
# @@ -87,14 +87,14 @@
#  %endif
 
#  %global have_liburing 0
# -%if 0%{?fedora}
# +%if 0%{?rhel}
#  %ifnarch %{arm}
#  %global have_liburing 1
#  %endif
#  %endif
 
#  %global have_virgl 0
# -%if 0%{?fedora}
# +%if 0%{?rhel}
#  %global have_virgl 1
#  %endif
 
# @@ -114,12 +114,10 @@
#  %global have_dbus_display 0
#  %endif
 
# -%global have_libblkio 0
# -%if 0%{?fedora} >= 37
#  %global have_libblkio 1
# -%endif
 
# -%global have_sdl_image %{defined fedora}
# +%global have_gvnc_devel 1
# +%global have_sdl_image 1
#  %global have_fdt 1
#  %global have_opengl 1
#  %global have_usbredir 1
# @@ -156,7 +154,7 @@
 
#  %define have_libcacard 1
#  %if 0%{?rhel} >= 9
# -%define have_libcacard 0
# +%define have_libcacard 1
#  %endif
 
#  # LTO still has issues with qemu on armv7hl and aarch64
# @@ -509,12 +507,8 @@ BuildRequires: SDL2_image-devel
 
#  %if %{user_static}
#  BuildRequires: glibc-static glib2-static zlib-static
# -%if 0%{?fedora} >= 37
# -BuildRequires: pcre2-static
# -%else
#  BuildRequires: pcre-static
#  %endif
# -%endif
 
 
#  # Requires for the Fedora 'qemu' metapackage
# @@ -749,9 +743,8 @@ This package provides the additional OSS audio driver for QEMU.
 
#  %package  audio-pa
#  Summary: QEMU PulseAudio audio driver
# -Requires: %{name}-common%{?_isa} = %{epoch}:%{version}-%{release}
#  %description audio-pa
# -This package provides the additional PulseAudi audio driver for QEMU.
# +This package provides the additional PulseAudio audio driver for QEMU.
 
#  %package  audio-sdl
#  Summary: QEMU SDL audio driver
# @@ -1499,7 +1492,6 @@ mkdir -p %{static_builddir}
#    --disable-linux-user             \\\\\\
#    --disable-live-block-migration   \\\\\\
#    --disable-lto                    \\\\\\
# -  --disable-lzfse                  \\\\\\
#    --disable-lzo                    \\\\\\
#    --disable-malloc-trim            \\\\\\
#    --disable-membarrier             \\\\\\
# @@ -1719,6 +1711,7 @@ run_configure \\
#    --enable-curses \\
#    --enable-dmg \\
#    --enable-fuse \\
# +  --enable-fuse-lseek \\
#    --enable-gio \\
#  %if %{have_block_gluster}
#    --enable-glusterfs \\
# @@ -1733,7 +1726,6 @@ run_configure \\
#    --enable-linux-io-uring \\
#  %endif
#    --enable-linux-user \\
# -  --enable-live-block-migration \\
#    --enable-multiprocess \\
#    --enable-vnc-jpeg \\
#    --enable-parallels \\
# @@ -1743,7 +1735,6 @@ run_configure \\
#    --enable-qcow1 \\
#    --enable-qed \\
#    --enable-qom-cast-debug \\
# -  --enable-replication \\
#    --enable-sdl \\
#  %if %{have_sdl_image}
#    --enable-sdl-image \\
# @@ -1751,6 +1742,7 @@ run_configure \\
#  %if %{have_libcacard}
#    --enable-smartcard \\
#  %endif
# +  --enable-sparse \\
#  %if %{have_spice}
#    --enable-spice \\
#    --enable-spice-protocol \\
# @@ -1790,8 +1782,12 @@ run_configure \\
 
#  %if !%{tools_only}
#  %make_build
# +
# +cp -a %{kvm_target}-softmmu/qemu-system-%{kvm_target} qemu-kvm
# +
#  popd
 
# +
#  # Fedora build for qemu-user-static
#  %if %{user_static}
#  pushd %{static_builddir}
# @@ -1863,6 +1859,8 @@ install -D -p -m 644 %{_sourcedir}/95-kvm-memlock.conf %{buildroot}%{_sysconfdir
#  %if %{have_kvm}
#  install -D -p -m 0644 %{_sourcedir}/vhost.conf %{buildroot}%{_sysconfdir}/modprobe.d/vhost.conf
#  install -D -p -m 0644 %{modprobe_kvm_conf} %{buildroot}%{_sysconfdir}/modprobe.d/kvm.conf
# +install -D -p -m 0755 %{qemu_kvm_build}/%{kvm_target}-softmmu/qemu-system-%{kvm_target} %{buildroot}%{_libexecdir}/qemu-kvm
# +
#  %endif
 
#  # Copy some static data into place
# @@ -2011,7 +2009,7 @@ pushd %{qemu_kvm_build}
#  echo "Testing %{name}-build"
#  # 2022-06: ppc64le random qtest segfaults with no discernable pattern
#  %ifnarch %{power64}
# -%make_build check
# +# %make_build check
#  %endif
 
#  popd
# @@ -2266,6 +2264,7 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 
#  %files block-dmg
#  %{_libdir}/%{name}/block-dmg-bz2.so
# +%{_libdir}/%{name}/block-dmg-lzfse.so
#  %if %{have_block_gluster}
#  %files block-gluster
#  %{_libdir}/%{name}/block-gluster.so
# @@ -2359,7 +2358,12 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
#  # Deliberately empty
 
#  %files kvm-core
# -# Deliberately empty
# +%{_libexecdir}/qemu-kvm
# +
# +%ifarch x86_64
# +    %{_libdir}/%{name}/accel-tcg-%{kvm_target}.so
# +%endif
# +
#  %endif
 
patch -p1 <<-PATCH
diff --git a/xorg-x11-drv-qxl.spec b/xorg-x11-drv-qxl.spec
index 009e71d..5c9f95c 100644
--- a/xorg-x11-drv-qxl.spec
+++ b/xorg-x11-drv-qxl.spec
@@ -31,6 +31,8 @@ Source0:  http://xorg.freedesktop.org/releases/individual/driver/%{tarball}-%{ve
 Patch1: 0001-worst-hack-of-all-time-to-qxl-driver.patch
 # This shebang patch is currently downstream-only
 Patch5: 0005-Xspice-Adjust-shebang-to-explicitly-mention-python3.patch
+Patch9: 0009-qxl-drmmode-header.patch
+
 
 License:   MIT
 
PATCH

cat <<-PATCH > ../SOURCES/0009-qxl-drmmode-header.patch
From: Ladar <ladar@lavabit.local>
Date: Tue, 17 Oct 2023 12:28:26 +0000
Subject: Fix qxl_drmmode.h compile error.

diff --git a/src/qxl_drmmode.h b/src/qxl_drmmode.h
index 392b1e2..32cfd0a 100644
--- a/src/qxl_drmmode.h
+++ b/src/qxl_drmmode.h
@@ -29,11 +29,11 @@
 
 #ifdef XF86DRM_MODE
 
-#include "xf86drm.h"
-#include "xf86drmMode.h"
 #include "xf86str.h"
 #include "randrstr.h"
 #include "xf86Crtc.h"
+#include "xf86drm.h"
+#include "xf86drmMode.h"
 #ifdef HAVE_LIBUDEV
 #include "libudev.h"
 #endif
PATCH



# QEMU 8.1.2 PATCHs
patch -p1 <<-PATCH

diff --git a/qemu.spec b/qemu.spec
index 5fc5886..0a01592 100644
--- a/qemu.spec
+++ b/qemu.spec
@@ -14,11 +14,13 @@
 %global need_qemu_kvm 0
 %ifarch %{ix86}
 %global kvm_package   system-x86
+%global kvm_target    i386
 # need_qemu_kvm should only ever be used by x86
 %global need_qemu_kvm 1
 %endif
 %ifarch x86_64
 %global kvm_package   system-x86
+%global kvm_target    x86_64
 # need_qemu_kvm should only ever be used by x86
 %global need_qemu_kvm 1
 %endif
@@ -55,7 +57,7 @@
 %global user_static 1
 %if 0%{?rhel}
 # EPEL/RHEL do not have required -static builddeps
-%global user_static 0
+%global user_static 1
 %endif
 
 %global have_kvm 0
@@ -70,12 +72,10 @@
 %endif
 
 # Matches spice ExclusiveArch
-%global have_spice 1
 %ifnarch %{ix86} x86_64 %{arm} aarch64
 %global have_spice 0
-%endif
-%if 0%{?rhel} >= 9
-%global have_spice 0
+%else
+%global have_spice 1
 %endif
 
 # Matches xen ExclusiveArch
@@ -87,14 +87,14 @@
 %endif
 
 %global have_liburing 0
-%if 0%{?fedora}
+%if 0%{?rhel}
 %ifnarch %{arm}
 %global have_liburing 1
 %endif
 %endif
 
 %global have_virgl 0
-%if 0%{?fedora}
+%if 0%{?rhel}
 %global have_virgl 1
 %endif
 
@@ -114,13 +114,10 @@
 %global have_dbus_display 0
 %endif
 
-%global have_libblkio 0
-%if 0%{?fedora} >= 37
 %global have_libblkio 1
-%endif
 
-%global have_gvnc_devel %{defined fedora}
-%global have_sdl_image %{defined fedora}
+%global have_gvnc_devel 1
+%global have_sdl_image 1
 %global have_fdt 1
 %global have_opengl 1
 %global have_usbredir 1
@@ -157,7 +154,7 @@
 
 %define have_libcacard 1
 %if 0%{?rhel} >= 9
-%define have_libcacard 0
+%define have_libcacard 1
 %endif
 
 # LTO still has issues with qemu on armv7hl and aarch64
@@ -202,7 +199,6 @@
 %define requires_audio_alsa Requires: %{name}-audio-alsa = %{evr}
 %define requires_audio_oss Requires: %{name}-audio-oss = %{evr}
 %define requires_audio_pa Requires: %{name}-audio-pa = %{evr}
-%define requires_audio_pipewire Requires: %{name}-audio-pipewire = %{evr}
 %define requires_audio_sdl Requires: %{name}-audio-sdl = %{evr}
 %define requires_char_baum Requires: %{name}-char-baum = %{evr}
 %define requires_device_usb_host Requires: %{name}-device-usb-host = %{evr}
@@ -288,7 +284,6 @@
 %{requires_audio_dbus} \\
 %{requires_audio_oss} \\
 %{requires_audio_pa} \\
-%{requires_audio_pipewire} \\
 %{requires_audio_sdl} \\
 %{requires_audio_jack} \\
 %{requires_audio_spice} \\
@@ -360,6 +355,16 @@ Source30: kvm-s390x.conf
 Source31: kvm-x86.conf
 Source36: README.tests
 
+
+#Patch0004: 0004-Initial-redhat-build.patch
+#Patch0005: 0005-Enable-disable-devices-for-RHEL.patch
+#Patch0006: 0006-Machine-type-related-general-changes.patch
+#Patch0010: 0010-Add-x86_64-machine-types.patch
+#Patch0018: 0018-Addd-7.2-compat-bits-for-RHEL-9.1-machine-type.patch
+#Patch0022: 0022-x86-rhel-9.2.0-machine-type.patch
+#Patch23: kvm-redhat-fix-virt-rhel9.2.0-compat-props.patch
+
+
 BuildRequires: meson >= %{meson_version}
 BuildRequires: bison
 BuildRequires: flex
@@ -513,16 +518,11 @@ BuildRequires: SDL2_image-devel
 # Used by vnc-display-test
 BuildRequires: pkgconfig(gvnc-1.0)
 %endif
-BuildRequires: pipewire-devel
 
 %if %{user_static}
 BuildRequires: glibc-static glib2-static zlib-static
-%if 0%{?fedora} >= 37
-BuildRequires: pcre2-static
-%else
 BuildRequires: pcre-static
 %endif
-%endif
 
 
 # Requires for the Fedora 'qemu' metapackage
@@ -753,12 +753,6 @@ Requires: %{name}-common%{?_isa} = %{epoch}:%{version}-%{release}
 %description audio-pa
 This package provides the additional PulseAudio audio driver for QEMU.
 
-%package  audio-pipewire
-Summary: QEMU Pipewire audio driver
-Requires: %{name}-common%{?_isa} = %{epoch}:%{version}-%{release}
-%description audio-pipewire
-This package provides the additional Pipewire audio driver for QEMU.
-
 %package  audio-sdl
 Summary: QEMU SDL audio driver
 Requires: %{name}-common%{?_isa} = %{epoch}:%{version}-%{release}
@@ -956,6 +950,12 @@ Requires: %{name}-common = %{epoch}:%{version}-%{release}
 %description user
 This package provides the user mode emulation of qemu targets
 
+%package user-vfio
+Summary: QEMU user vfio server
+Requires: %{name}-common = %{epoch}:%{version}-%{release}
+%description user-vfio
+This package provides a user mode vfio daemon which can broker
+access to vfio devices
 
 %package user-binfmt
 Summary: QEMU user mode emulation of qemu targets
@@ -1512,7 +1512,6 @@ mkdir -p %{static_builddir}
   --disable-linux-user             \\\\\\
   --disable-live-block-migration   \\\\\\
   --disable-lto                    \\\\\\
-  --disable-lzfse                  \\\\\\
   --disable-lzo                    \\\\\\
   --disable-malloc-trim            \\\\\\
   --disable-membarrier             \\\\\\
@@ -1691,7 +1690,6 @@ run_configure \\
   --enable-oss \\
   --enable-pa \\
   --enable-pie \\
-  --enable-pipewire \\
 %if %{have_block_rbd}
   --enable-rbd \\
 %endif
@@ -1724,7 +1722,7 @@ run_configure \\
   --enable-xkbcommon \\
   \\
   \\
-  --audio-drv-list=pipewire,pa,sdl,alsa,%{?jack_drv}oss \\
+  --audio-drv-list=pa,sdl,alsa,%{?jack_drv}oss \\
   --target-list-exclude=moxie-softmmu \\
   --with-default-devices \\
   --enable-auth-pam \\
@@ -1735,6 +1733,7 @@ run_configure \\
   --enable-curses \\
   --enable-dmg \\
   --enable-fuse \\
+  --enable-fuse-lseek \\
   --enable-gio \\
 %if %{have_block_gluster}
   --enable-glusterfs \\
@@ -1749,7 +1748,6 @@ run_configure \\
   --enable-linux-io-uring \\
 %endif
   --enable-linux-user \\
-  --enable-live-block-migration \\
   --enable-multiprocess \\
   --enable-parallels \\
 %if %{have_librdma}
@@ -1758,7 +1756,6 @@ run_configure \\
   --enable-qcow1 \\
   --enable-qed \\
   --enable-qom-cast-debug \\
-  --enable-replication \\
   --enable-sdl \\
 %if %{have_sdl_image}
   --enable-sdl-image \\
@@ -1766,11 +1763,13 @@ run_configure \\
 %if %{have_libcacard}
   --enable-smartcard \\
 %endif
+  --enable-sparse \\
 %if %{have_spice}
   --enable-spice \\
   --enable-spice-protocol \\
 %endif
   --enable-vdi \\
+  --enable-vfio-user-server \\
   --enable-vhost-crypto \\
 %if %{have_virgl}
   --enable-virglrenderer \\
@@ -1809,8 +1808,12 @@ run_configure \\
 
 %if !%{tools_only}
 %make_build
+
+cp -a %{kvm_target}-softmmu/qemu-system-%{kvm_target} qemu-kvm
+
 popd
 
+
 # Fedora build for qemu-user-static
 %if %{user_static}
 pushd %{static_builddir}
@@ -1882,6 +1885,8 @@ install -D -p -m 644 %{_sourcedir}/95-kvm-memlock.conf %{buildroot}%{_sysconfdir
 %if %{have_kvm}
 install -D -p -m 0644 %{_sourcedir}/vhost.conf %{buildroot}%{_sysconfdir}/modprobe.d/vhost.conf
 install -D -p -m 0644 %{modprobe_kvm_conf} %{buildroot}%{_sysconfdir}/modprobe.d/kvm.conf
+install -D -p -m 0755 %{qemu_kvm_build}/%{kvm_target}-softmmu/qemu-system-%{kvm_target} %{buildroot}%{_libexecdir}/qemu-kvm
+
 %endif
 
 # Copy some static data into place
@@ -2285,6 +2290,7 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 
 %files block-dmg
 %{_libdir}/%{name}/block-dmg-bz2.so
+%{_libdir}/%{name}/block-dmg-lzfse.so
 %if %{have_block_gluster}
 %files block-gluster
 %{_libdir}/%{name}/block-gluster.so
@@ -2304,8 +2310,6 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 %{_libdir}/%{name}/audio-oss.so
 %files audio-pa
 %{_libdir}/%{name}/audio-pa.so
-%files audio-pipewire
-%{_libdir}/%{name}/audio-pipewire.so
 %files audio-sdl
 %{_libdir}/%{name}/audio-sdl.so
 %if %{have_jack}
@@ -2384,7 +2388,12 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 # Deliberately empty
 
 %files kvm-core
-# Deliberately empty
+%{_libexecdir}/qemu-kvm
+
+%ifarch x86_64
+    %{_libdir}/%{name}/accel-tcg-%{kvm_target}.so
+%endif
+
 %endif
 
 
@@ -2446,6 +2455,19 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 %{_datadir}/systemtap/tapset/qemu-sparc*.stp
 %{_datadir}/systemtap/tapset/qemu-xtensa*.stp
 
+%files user-vfio
+/usr/include/vfio-user/libvfio-user.h
+/usr/include/vfio-user/pci_caps/common.h
+/usr/include/vfio-user/pci_caps/dsn.h
+/usr/include/vfio-user/pci_caps/msi.h
+/usr/include/vfio-user/pci_caps/msix.h
+/usr/include/vfio-user/pci_caps/pm.h
+/usr/include/vfio-user/pci_caps/px.h
+/usr/include/vfio-user/pci_defs.h
+/usr/include/vfio-user/vfio-user.h
+%{_libdir}/libvfio-user.so
+%{_libdir}/libvfio-user.so.0
+%{_libdir}/libvfio-user.so.0.0.1
 
 %files user-binfmt
 %{_exec_prefix}/lib/binfmt.d/qemu-*-dynamic.conf
PATCH


cat <<-PATCH > ../SOURCES/0004-Initial-redhat-build.patch
From ccc4a5bdc8c2f27678312364a7c12aeafd009bb6 Mon Sep 17 00:00:00 2001
From: Miroslav Rezanina <mrezanin@redhat.com>
Date: Wed, 26 May 2021 10:56:02 +0200
Subject: Initial redhat build

This patch introduces redhat build structure in redhat subdirectory. In addition,
several issues are fixed in QEMU tree:

- Change of app name for sasl_server_init in VNC code from qemu to qemu-kvm
 - As we use qemu-kvm as name in all places, this is updated to be consistent
- Man page renamed from qemu to qemu-kvm
 - man page is installed using make install so we have to fix it in qemu tree

We disable make check due to issues with some of the tests.

This rebase is based on qemu-kvm-7.1.0-7.el9

Signed-off-by: Miroslav Rezanina <mrezanin@redhat.com>
--
Rebase changes (6.1.0):
- Move build to .distro
- Move changes for support file to related commit
- Added dependency for python3-sphinx-rtd_theme
- Removed --disable-sheepdog configure option
- Added new hw-display modules
- SASL initialization moved to ui/vnc-auth-sasl.c
- Add accel-qtest-<arch> and accel-tcg-x86_64 libraries
- Added hw-usb-host module
- Disable new configure options (bpf, nvmm, slirp-smbd)
- Use -pie for ksmctl build (annocheck complain fix)

Rebase changes (6.2.0):
- removed --disable-jemalloc and --disable-tcmalloc configure options
- added audio-oss.so
- added fdt requirement for x86_64
- tests/acceptance renamed to tests/avocado
- added multiboot_dma.bin
- Add -Wno-string-plus-int to extra flags
- Updated configure options

Rebase changes (7.0.0):
- Do not use -mlittle CFLAG on ppc64le
- Used upstream handling issue with ui/clipboard.c
- Use -mlittle-endian on ppc64le instead of deleteing it in configure
- Drop --disable-libxml2 option for configure (upstream)
- Remove vof roms
- Disable AVX2 support
- Use internal meson
- Disable new configure options (dbus-display and qga-vss)
- Change permissions on installing tests/Makefile.include
- Remove ssh block driver

Rebase changes (7.1.0 rc0):
- --disable-vnc-png renamed to --disable-png (upstream)
- removed --disable-vhost-vsock and --disable-vhost-scsi
- capstone submodule removed
- Temporary include capstone build

Rebase changes (7.2.0 rc0):
- Switch --enable-slirp=system to --enable-slirp

Rebaes changes (7.2.0 rc2):
- Added new configure options (blkio and sndio, both disabled)

Rebase changes (7.2.0):
- Fix SRPM name generation to work on Fedora 37
- Switch back to system meson

Merged patches (6.0.0):
 - 605758c902 Limit build on Power to qemu-img and qemu-ga only

Merged patches (6.1.0):
- f04f91751f Use cached tarballs
- 6581165c65 Remove message with running VM count
- 03c3cac9fc spec-file: build qemu-kvm without SPICE and QXL
- e0ae6c1f6c spec-file: Obsolete qemu-kvm-ui-spice
- 9d2e9f9ecf spec: Do not build qemu-kvm-block-gluster
- cf470b4234 spec: Do not link pcnet and ne2k_pci roms
- e981284a6b redhat: Install the s390-netboot.img that we've built
- 24ef557f33 spec: Remove usage of Group: tag
- c40d69b4f4 spec: Drop %defattr usage
- f8e98798ce spec: Clean up BuildRequires
- 47246b43ee spec: Remove iasl BuildRequires
- 170dc1cbe0 spec: Remove redundant 0 in conditionals
- 8718f6fa11 spec: Add more have_XXX conditionals
- a001269ce9 spec: Remove binutils versioned Requires
- 34545ee641 spec: Remove diffutils BuildRequires
- c2c82beac9 spec: Remove redundant Requires:
- 9314c231f4 spec: Add XXX_version macros
- c43db0bf0f spec: Add have_block_rbd
- 3ecb0c0319 qga: drop StandardError=syslog
- 018049dc80 Remove iscsi support
- a2edf18777 redhat: Replace the kvm-setup.service with a /etc/modules-load.d config file
- 387b5fbcfe redhat: Move qemu-kvm-docs dependency to qemu-kvm
- 4ead693178 redhat: introducting qemu-kvm-hw-usbredir
- 4dc6fc3035 redhat: use the standard vhost-user JSON path
- 84757178b4 Fix local build
- 8c394227dd spec: Restrict block drivers in tools
- b6aa7c1fae Move tools to separate package
- eafd82e509 Split qemu-pr-helper to separate package
- 2c0182e2aa spec: RPM_BUILD_ROOT -> %{buildroot}
- 91bd55ca13 spec: More use of %{name} instead of 'qemu-kvm'
- 50ba299c61 spec: Use qemu-pr-helper.service from qemu.git (partial)
- ee08d4e0a3 spec: Use %{_sourcedir} for referencing sources
- 039e7f7d02 spec: Add tools_only
- 884ba71617 spec: %build: Add run_configure helper
- 8ebd864d65 spec: %build: Disable more bits with %{disable_everything} (partial)
- f23fdb53f5 spec: %build: Add macros for some 'configure' parameters
- fe951a8bd8 spec: %files: Move qemu-guest-agent and qemu-img earlier
- 353b632e37 spec: %install: Remove redundant bits
- 9d2015b752 spec: %install: Add %{modprobe_kvm_conf} macro
- 6d05134e8c spec: %install: Remove qemu-guest-agent /etc/qemu-kvm usage
- 985b226467 spec: %install: clean up qemu-ga section
- dfaf9c600d spec: %install: Use a single %{tools_only} section
- f6978ddb46 spec: Make tools_only not cross spec sections
- 071c211098 spec: %install: Limit time spent in %{qemu_kvm_build}
- 1b65c674be spec: misc syntactic merges with Fedora
- 4da16294cf spec: Use Fedora's pattern for specifying rc version
- d7ee259a79 spec: %files: don't use fine grained -docs file list
- 64cad0c60f spec: %files: Add licenses to qemu-common too
- c3de4f080a spec: %install: Drop python3 shebang fixup
- 46fc216115 Update local build to work with spec file improvements
- bab9531548 spec: Remove buildldflags
- c8360ab6a9 spec: Use %make_build macro
- f6966c66e9 spec: Drop make install sharedir and datadir usage
- 86982421bc spec: use %make_install macro
- 191c405d22 spec: parallelize \`make check\`
- 251a1fb958 spec: Drop explicit --build-id
- 44c7dda6c3 spec: use %{build_ldflags}
- 0009a34354 Move virtiofsd to separate package
-  34d1b200b3 Utilize --firmware configure option
- 2800e1dd03 spec: Switch toolchain to Clang/LLVM (except process-patches.sh)
- e8a70f500f spec: Use safe-stack for x86_64
- e29445d50d spec: Reenable write support for VMDK etc. in tools
- a4fe2a3e16 redhat: Disable LTO on non-x86 architectures

Merged patches (6.2.0):
- 333452440b remove sgabios dependency
- 7d3633f184 enable pulseaudio
- bd898709b0 spec: disable use of gcrypt for crypto backends in favour of gnutls
- e4f0c6dee6 spec: Remove block-curl and block-ssh dependency
- 4dc13bfe63 spec: Build the VDI block driver
- d2f2ff3c74 spec: Explicitly include compress filter
- a7d047f9c2 Move ksmtuned files to separate package

Merged patches (7.0.0):
- 098d4d08d0 spec: Rename qemu-kvm-hw-usbredir to qemu-kvm-device-usb-redirect
- c2bd0d6834 spec: Split qemu-kvm-ui-opengl
- 2c9cda805d spec: Introduce packages for virtio-gpu-* modules (changed as rhel device tree not set)
- d0414a3e0b spec: Introduce device-display-virtio-vga* packages
- 3534ec46d4 spec: Move usb-host module to separate package
- ddc14d4737 spec: Move qtest accel module to tests package
- 6f2c4befa6 spec: Extend qemu-kvm-core description
- 6f11866e4e (rhel/rhel-9.0.0) Update to qemu-kvm-6.2.0-6.el9
- da0a28758f ui/clipboard: fix use-after-free regression
- 895d4d52eb spec: Remove qemu-virtiofsd
- c8c8c8bd84 spec: Fix obsolete for spice subpackages
- d46d2710b2 spec: Obsolete old usb redir subpackage
- 6f52a50b68 spec: Obsolete ssh driver

Merged patches (7.2.0 rc4):
- 8c6834feb6 Remove opengl display device subpackages (C9S MR 124)
- 0ecc97f29e spec: Add requires for packages with additional virtio-gpu variants (C9S MR 124)

Signed-off-by: Miroslav Rezanina <mrezanin@redhat.com>

fix
---
 .distro/Makefile                        |  100 +
 .distro/Makefile.common                 |   41 +
 .distro/README.tests                    |   39 +
 .distro/modules-load.conf               |    4 +
 .distro/qemu-guest-agent.service        |    1 -
 .distro/qemu-kvm.spec.template          | 4315 +++++++++++++++++++++++
 .distro/rpminspect.yaml                 |    6 +-
 .distro/scripts/extract_build_cmd.py    |   12 +
 .distro/scripts/process-patches.sh      |    4 +
 .gitignore                              |    1 +
 README.systemtap                        |   43 +
 scripts/qemu-guest-agent/fsfreeze-hook  |    2 +-
 scripts/systemtap/conf.d/qemu_kvm.conf  |    4 +
 scripts/systemtap/script.d/qemu_kvm.stp |    1 +
 tests/check-block.sh                    |    2 +
 ui/vnc-auth-sasl.c                      |    2 +-
 16 files changed, 4573 insertions(+), 4 deletions(-)
 create mode 100644 .distro/Makefile
 create mode 100644 .distro/Makefile.common
 create mode 100644 .distro/README.tests
 create mode 100644 .distro/modules-load.conf
 create mode 100644 .distro/qemu-kvm.spec.template
 create mode 100644 README.systemtap
 create mode 100644 scripts/systemtap/conf.d/qemu_kvm.conf
 create mode 100644 scripts/systemtap/script.d/qemu_kvm.stp

diff --git a/README.systemtap b/README.systemtap
new file mode 100644
index 0000000000..ad913fc990
--- /dev/null
+++ b/README.systemtap
@@ -0,0 +1,43 @@
+QEMU tracing using systemtap-initscript
+---------------------------------------
+
+You can capture QEMU trace data all the time using systemtap-initscript.  This
+uses SystemTap's flight recorder mode to trace all running guests to a
+fixed-size buffer on the host.  Old trace entries are overwritten by new
+entries when the buffer size wraps.
+
+1. Install the systemtap-initscript package:
+  # yum install systemtap-initscript
+
+2. Install the systemtap scripts and the conf file:
+  # cp /usr/share/qemu-kvm/systemtap/script.d/qemu_kvm.stp /etc/systemtap/script.d/
+  # cp /usr/share/qemu-kvm/systemtap/conf.d/qemu_kvm.conf /etc/systemtap/conf.d/
+
+The set of trace events to enable is given in qemu_kvm.stp.  This SystemTap
+script can be customized to add or remove trace events provided in
+/usr/share/systemtap/tapset/qemu-kvm-simpletrace.stp.
+
+SystemTap customizations can be made to qemu_kvm.conf to control the flight
+recorder buffer size and whether to store traces in memory only or disk too.
+See stap(1) for option documentation.
+
+3. Start the systemtap service.
+　# service systemtap start qemu_kvm
+
+4. Make the service start at boot time.
+　# chkconfig systemtap on
+
+5. Confirm that the service works.
+  # service systemtap status qemu_kvm
+  qemu_kvm is running...
+
+When you want to inspect the trace buffer, perform the following steps:
+
+1. Dump the trace buffer.
+  # staprun -A qemu_kvm >/tmp/trace.log
+
+2. Start the systemtap service because the preceding step stops the service.
+  # service systemtap start qemu_kvm
+
+3. Translate the trace record to readable format.
+  # /usr/share/qemu-kvm/simpletrace.py --no-header /usr/share/qemu-kvm/trace-events /tmp/trace.log
diff --git a/scripts/qemu-guest-agent/fsfreeze-hook b/scripts/qemu-guest-agent/fsfreeze-hook
index 13aafd4845..e9b84ec028 100755
--- a/scripts/qemu-guest-agent/fsfreeze-hook
+++ b/scripts/qemu-guest-agent/fsfreeze-hook
@@ -8,7 +8,7 @@
 # request, it is issued with "thaw" argument after filesystem is thawed.
 
 LOGFILE=/var/log/qga-fsfreeze-hook.log
-FSFREEZE_D=\$(dirname -- "\$0")/fsfreeze-hook.d
+FSFREEZE_D=\$(dirname -- "\$(realpath \$0)")/fsfreeze-hook.d
 
 # Check whether file \$1 is a backup or rpm-generated file and should be ignored
 is_ignored_file() {
diff --git a/scripts/systemtap/conf.d/qemu_kvm.conf b/scripts/systemtap/conf.d/qemu_kvm.conf
new file mode 100644
index 0000000000..372d8160a4
--- /dev/null
+++ b/scripts/systemtap/conf.d/qemu_kvm.conf
@@ -0,0 +1,4 @@
+# Force load uprobes (see BZ#1118352)
+stap -e 'probe process("/usr/libexec/qemu-kvm").function("main") { printf("") }' -c true
+
+qemu_kvm_OPT="-s4" # per-CPU buffer size, in megabytes
diff --git a/scripts/systemtap/script.d/qemu_kvm.stp b/scripts/systemtap/script.d/qemu_kvm.stp
new file mode 100644
index 0000000000..c04abf9449
--- /dev/null
+++ b/scripts/systemtap/script.d/qemu_kvm.stp
@@ -0,0 +1 @@
+probe qemu.kvm.simpletrace.handle_qmp_command,qemu.kvm.simpletrace.monitor_protocol_*,qemu.kvm.simpletrace.migrate_set_state {}
diff --git a/tests/check-block.sh b/tests/check-block.sh
index 5de2c1ba0b..6af743f441 100755
--- a/tests/check-block.sh
+++ b/tests/check-block.sh
@@ -22,6 +22,8 @@ if [ -z "\$(find . -name 'qemu-system-*' -print)" ]; then
     skip "No qemu-system binary available ==> Not running the qemu-iotests."
 fi
 
+exit 0
+
 cd tests/qemu-iotests
 
 # QEMU_CHECK_BLOCK_AUTO is used to disable some unstable sub-tests
diff --git a/ui/vnc-auth-sasl.c b/ui/vnc-auth-sasl.c
index 47fdae5b21..2a950caa2a 100644
--- a/ui/vnc-auth-sasl.c
+++ b/ui/vnc-auth-sasl.c
@@ -42,7 +42,7 @@
 
 bool vnc_sasl_server_init(Error **errp)
 {
-    int saslErr = sasl_server_init(NULL, "qemu");
+    int saslErr = sasl_server_init(NULL, "qemu-kvm");
 
     if (saslErr != SASL_OK) {
         error_setg(errp, "Failed to initialize SASL auth: %s",
-- 
2.31.1

PATCH

cat <<-PATCH > ../SOURCES/0005-Enable-disable-devices-for-RHEL.patch
From: Miroslav Rezanina <mrezanin@redhat.com>
Date: Wed, 7 Dec 2022 03:05:48 -0500
Subject: Enable/disable devices for RHEL

This commit adds all changes related to changes in supported devices.

diff --git a/configs/devices/aarch64-softmmu/aarch64-rh-devices.mak b/configs/devices/aarch64-softmmu/aarch64-rh-devices.mak
new file mode 100644
index 0000000..720ec0c
--- /dev/null
+++ b/configs/devices/aarch64-softmmu/aarch64-rh-devices.mak
@@ -0,0 +1,41 @@
+include ../rh-virtio.mak
+
+CONFIG_ARM_GIC_KVM=y
+CONFIG_ARM_GICV3_TCG=y
+CONFIG_ARM_GIC=y
+CONFIG_ARM_SMMUV3=y
+CONFIG_ARM_V7M=y
+CONFIG_ARM_VIRT=y
+CONFIG_CXL=y
+CONFIG_CXL_MEM_DEVICE=y
+CONFIG_EDID=y
+CONFIG_PCIE_PORT=y
+CONFIG_PCI_DEVICES=y
+CONFIG_PCI_TESTDEV=y
+CONFIG_PFLASH_CFI01=y
+CONFIG_SCSI=y
+CONFIG_SEMIHOSTING=y
+CONFIG_USB=y
+CONFIG_USB_XHCI=y
+CONFIG_USB_XHCI_PCI=y
+CONFIG_USB_STORAGE_CORE=y
+CONFIG_USB_STORAGE_CLASSIC=y
+CONFIG_VFIO=y
+CONFIG_VFIO_PCI=y
+CONFIG_VIRTIO_MMIO=y
+CONFIG_VIRTIO_PCI=y
+CONFIG_VIRTIO_MEM=y
+CONFIG_VIRTIO_IOMMU=y
+CONFIG_XIO3130=y
+CONFIG_NVDIMM=y
+CONFIG_ACPI_APEI=y
+CONFIG_TPM=y
+CONFIG_TPM_EMULATOR=y
+CONFIG_TPM_TIS_SYSBUS=y
+CONFIG_PTIMER=y
+CONFIG_ARM_COMPATIBLE_SEMIHOSTING=y
+CONFIG_PVPANIC_PCI=y
+CONFIG_PXB=y
+CONFIG_VHOST_VSOCK=y
+CONFIG_VHOST_USER_VSOCK=y
+CONFIG_VHOST_USER_FS=y
diff --git a/configs/devices/ppc64-softmmu/ppc64-rh-devices.mak b/configs/devices/ppc64-softmmu/ppc64-rh-devices.mak
new file mode 100644
index 0000000..dbb7d30
--- /dev/null
+++ b/configs/devices/ppc64-softmmu/ppc64-rh-devices.mak
@@ -0,0 +1,37 @@
+include ../rh-virtio.mak
+
+CONFIG_DIMM=y
+CONFIG_MEM_DEVICE=y
+CONFIG_NVDIMM=y
+CONFIG_PCI=y
+CONFIG_PCI_DEVICES=y
+CONFIG_PCI_TESTDEV=y
+CONFIG_PCI_EXPRESS=y
+CONFIG_PSERIES=y
+CONFIG_SCSI=y
+CONFIG_SPAPR_VSCSI=y
+CONFIG_TEST_DEVICES=y
+CONFIG_USB=y
+CONFIG_USB_OHCI=y
+CONFIG_USB_OHCI_PCI=y
+CONFIG_USB_SMARTCARD=y
+CONFIG_USB_STORAGE_CORE=y
+CONFIG_USB_STORAGE_CLASSIC=y
+CONFIG_USB_XHCI=y
+CONFIG_USB_XHCI_NEC=y
+CONFIG_USB_XHCI_PCI=y
+CONFIG_VFIO=y
+CONFIG_VFIO_PCI=y
+CONFIG_VGA=y
+CONFIG_VGA_PCI=y
+CONFIG_VHOST_USER=y
+CONFIG_VIRTIO_PCI=y
+CONFIG_VIRTIO_VGA=y
+CONFIG_WDT_IB6300ESB=y
+CONFIG_XICS=y
+CONFIG_XIVE=y
+CONFIG_TPM=y
+CONFIG_TPM_SPAPR=y
+CONFIG_TPM_EMULATOR=y
+CONFIG_VHOST_VSOCK=y
+CONFIG_VHOST_USER_VSOCK=y
diff --git a/configs/devices/rh-virtio.mak b/configs/devices/rh-virtio.mak
new file mode 100644
index 0000000..94ede1b
--- /dev/null
+++ b/configs/devices/rh-virtio.mak
@@ -0,0 +1,10 @@
+CONFIG_VIRTIO=y
+CONFIG_VIRTIO_BALLOON=y
+CONFIG_VIRTIO_BLK=y
+CONFIG_VIRTIO_GPU=y
+CONFIG_VIRTIO_INPUT=y
+CONFIG_VIRTIO_INPUT_HOST=y
+CONFIG_VIRTIO_NET=y
+CONFIG_VIRTIO_RNG=y
+CONFIG_VIRTIO_SCSI=y
+CONFIG_VIRTIO_SERIAL=y
diff --git a/configs/devices/s390x-softmmu/s390x-rh-devices.mak b/configs/devices/s390x-softmmu/s390x-rh-devices.mak
new file mode 100644
index 0000000..69a799a
--- /dev/null
+++ b/configs/devices/s390x-softmmu/s390x-rh-devices.mak
@@ -0,0 +1,18 @@
+include ../rh-virtio.mak
+
+CONFIG_PCI=y
+CONFIG_S390_CCW_VIRTIO=y
+CONFIG_S390_FLIC=y
+CONFIG_S390_FLIC_KVM=y
+CONFIG_SCLPCONSOLE=y
+CONFIG_SCSI=y
+CONFIG_VFIO=y
+CONFIG_VFIO_AP=y
+CONFIG_VFIO_CCW=y
+CONFIG_VFIO_PCI=y
+CONFIG_VHOST_USER=y
+CONFIG_VIRTIO_CCW=y
+CONFIG_WDT_DIAG288=y
+CONFIG_VHOST_VSOCK=y
+CONFIG_VHOST_USER_VSOCK=y
+CONFIG_VHOST_USER_FS=y
diff --git a/configs/devices/x86_64-softmmu/x86_64-rh-devices.mak b/configs/devices/x86_64-softmmu/x86_64-rh-devices.mak
new file mode 100644
index 0000000..10cb0a1
--- /dev/null
+++ b/configs/devices/x86_64-softmmu/x86_64-rh-devices.mak
@@ -0,0 +1,109 @@
+include ../rh-virtio.mak
+
+CONFIG_ACPI=y
+CONFIG_ACPI_PCI=y
+CONFIG_ACPI_CPU_HOTPLUG=y
+CONFIG_ACPI_MEMORY_HOTPLUG=y
+CONFIG_ACPI_NVDIMM=y
+CONFIG_ACPI_SMBUS=y
+CONFIG_ACPI_VMGENID=y
+CONFIG_ACPI_X86=y
+CONFIG_ACPI_X86_ICH=y
+CONFIG_AHCI=y
+CONFIG_APIC=y
+CONFIG_APM=y
+CONFIG_BOCHS_DISPLAY=y
+CONFIG_CXL=y
+CONFIG_CXL_MEM_DEVICE=y
+CONFIG_DIMM=y
+CONFIG_E1000E_PCI_EXPRESS=y
+CONFIG_E1000_PCI=y
+CONFIG_EDU=y
+CONFIG_FDC=y
+CONFIG_FDC_SYSBUS=y
+CONFIG_FDC_ISA=y
+CONFIG_FW_CFG_DMA=y
+CONFIG_HDA=y
+CONFIG_HYPERV=y
+CONFIG_HYPERV_TESTDEV=y
+CONFIG_I2C=y
+CONFIG_I440FX=y
+CONFIG_I8254=y
+CONFIG_I8257=y
+CONFIG_I8259=y
+CONFIG_I82801B11=y
+CONFIG_IDE_CORE=y
+CONFIG_IDE_PCI=y
+CONFIG_IDE_PIIX=y
+CONFIG_IDE_QDEV=y
+CONFIG_IOAPIC=y
+CONFIG_IOH3420=y
+CONFIG_ISA_BUS=y
+CONFIG_ISA_DEBUG=y
+CONFIG_ISA_TESTDEV=y
+CONFIG_LPC_ICH9=y
+CONFIG_MC146818RTC=y
+CONFIG_MEM_DEVICE=y
+CONFIG_NVDIMM=y
+CONFIG_OPENGL=y
+CONFIG_PAM=y
+CONFIG_PC=y
+CONFIG_PCI=y
+CONFIG_PCIE_PORT=y
+CONFIG_PCI_DEVICES=y
+CONFIG_PCI_EXPRESS=y
+CONFIG_PCI_EXPRESS_Q35=y
+CONFIG_PCI_I440FX=y
+CONFIG_PCI_TESTDEV=y
+CONFIG_PCKBD=y
+CONFIG_PCSPK=y
+CONFIG_PC_ACPI=y
+CONFIG_PC_PCI=y
+CONFIG_PFLASH_CFI01=y
+CONFIG_PVPANIC_ISA=y
+CONFIG_PXB=y
+CONFIG_Q35=y
+CONFIG_RTL8139_PCI=y
+CONFIG_SCSI=y
+CONFIG_SERIAL=y
+CONFIG_SERIAL_ISA=y
+CONFIG_SERIAL_PCI=y
+CONFIG_SEV=y
+CONFIG_SMBIOS=y
+CONFIG_SMBUS_EEPROM=y
+CONFIG_TEST_DEVICES=y
+CONFIG_USB=y
+CONFIG_USB_EHCI=y
+CONFIG_USB_EHCI_PCI=y
+CONFIG_USB_SMARTCARD=y
+CONFIG_USB_STORAGE_CORE=y
+CONFIG_USB_STORAGE_CLASSIC=y
+CONFIG_USB_UHCI=y
+CONFIG_USB_XHCI=y
+CONFIG_USB_XHCI_NEC=y
+CONFIG_USB_XHCI_PCI=y
+CONFIG_VFIO=y
+CONFIG_VFIO_PCI=y
+CONFIG_VGA=y
+CONFIG_VGA_CIRRUS=y
+CONFIG_VGA_PCI=y
+CONFIG_VHOST_USER=y
+CONFIG_VHOST_USER_BLK=y
+CONFIG_VIRTIO_MEM=y
+CONFIG_VIRTIO_PCI=y
+CONFIG_VIRTIO_VGA=y
+CONFIG_VIRTIO_IOMMU=y
+CONFIG_VMMOUSE=y
+CONFIG_VMPORT=y
+CONFIG_VTD=y
+CONFIG_WDT_IB6300ESB=y
+CONFIG_WDT_IB700=y
+CONFIG_XIO3130=y
+CONFIG_TPM=y
+CONFIG_TPM_CRB=y
+CONFIG_TPM_TIS_ISA=y
+CONFIG_TPM_EMULATOR=y
+CONFIG_SGX=y
+CONFIG_VHOST_VSOCK=y
+CONFIG_VHOST_USER_VSOCK=y
+CONFIG_VHOST_USER_FS=y
diff --git a/hw/arm/meson.build b/hw/arm/meson.build
index 11eb911..97658e3 100644
--- a/hw/arm/meson.build
+++ b/hw/arm/meson.build
@@ -29,7 +29,7 @@ arm_ss.add(when: 'CONFIG_VEXPRESS', if_true: files('vexpress.c'))
 arm_ss.add(when: 'CONFIG_ZYNQ', if_true: files('xilinx_zynq.c'))
 arm_ss.add(when: 'CONFIG_SABRELITE', if_true: files('sabrelite.c'))
 
-arm_ss.add(when: 'CONFIG_ARM_V7M', if_true: files('armv7m.c'))
+#arm_ss.add(when: 'CONFIG_ARM_V7M', if_true: files('armv7m.c'))
 arm_ss.add(when: 'CONFIG_EXYNOS4', if_true: files('exynos4210.c'))
 arm_ss.add(when: 'CONFIG_PXA2XX', if_true: files('pxa2xx.c', 'pxa2xx_gpio.c', 'pxa2xx_pic.c'))
 arm_ss.add(when: 'CONFIG_DIGIC', if_true: files('digic.c'))
diff --git a/hw/block/fdc.c b/hw/block/fdc.c
index d7cc4d3..12d0a60 100644
--- a/hw/block/fdc.c
+++ b/hw/block/fdc.c
@@ -49,6 +49,8 @@
 #include "qom/object.h"
 #include "fdc-internal.h"
 
+#include "hw/boards.h"
+
 /********************************************************/
 /* debug Floppy devices */
 
@@ -2346,6 +2348,14 @@ void fdctrl_realize_common(DeviceState *dev, FDCtrl *fdctrl, Error **errp)
     FDrive *drive;
     static int command_tables_inited = 0;
 
+    /* Restricted for Red Hat Enterprise Linux: */
+    MachineClass *mc = MACHINE_GET_CLASS(qdev_get_machine());
+    if (!strstr(mc->name, "-rhel7.")) {
+        error_setg(errp, "Device %s is not supported with machine type %s",
+                   object_get_typename(OBJECT(dev)), mc->name);
+        return;
+    }
+
     if (fdctrl->fallback == FLOPPY_DRIVE_TYPE_AUTO) {
         error_setg(errp, "Cannot choose a fallback FDrive type of 'auto'");
         return;
diff --git a/hw/display/cirrus_vga.c b/hw/display/cirrus_vga.c
index b80f98b..b149d35 100644
--- a/hw/display/cirrus_vga.c
+++ b/hw/display/cirrus_vga.c
@@ -2946,7 +2946,10 @@ static void pci_cirrus_vga_realize(PCIDevice *dev, Error **errp)
     PCIDeviceClass *pc = PCI_DEVICE_GET_CLASS(dev);
     int16_t device_id = pc->device_id;
 
-    /*
+     warn_report("'cirrus-vga' is deprecated, "
+                 "please use a different VGA card instead");
+
+     /*
      * Follow real hardware, cirrus card emulated has 4 MB video memory.
      * Also accept 8 MB/16 MB for backward compatibility.
      */
diff --git a/hw/ide/piix.c b/hw/ide/piix.c
index 4e5e129..03ca06b 100644
--- a/hw/ide/piix.c
+++ b/hw/ide/piix.c
@@ -190,7 +190,8 @@ static void piix3_ide_class_init(ObjectClass *klass, void *data)
     k->device_id = PCI_DEVICE_ID_INTEL_82371SB_1;
     k->class_id = PCI_CLASS_STORAGE_IDE;
     set_bit(DEVICE_CATEGORY_STORAGE, dc->categories);
-    dc->hotpluggable = false;
+    /* Disabled for Red Hat Enterprise Linux: */
+    dc->user_creatable = false;
 }
 
 static const TypeInfo piix3_ide_info = {
@@ -214,6 +215,8 @@ static void piix4_ide_class_init(ObjectClass *klass, void *data)
     k->class_id = PCI_CLASS_STORAGE_IDE;
     set_bit(DEVICE_CATEGORY_STORAGE, dc->categories);
     dc->hotpluggable = false;
+    /* Disabled for Red Hat Enterprise Linux: */
+    dc->user_creatable = false;
 }
 
 static const TypeInfo piix4_ide_info = {
diff --git a/hw/input/pckbd.c b/hw/input/pckbd.c
index b92b63b..3b6235d 100644
--- a/hw/input/pckbd.c
+++ b/hw/input/pckbd.c
@@ -957,6 +957,8 @@ static void i8042_class_initfn(ObjectClass *klass, void *data)
     dc->vmsd = &vmstate_kbd_isa;
     adevc->build_dev_aml = i8042_build_aml;
     set_bit(DEVICE_CATEGORY_INPUT, dc->categories);
+    /* Disabled for Red Hat Enterprise Linux: */
+    dc->user_creatable = false;
 }
 
 static const TypeInfo i8042_info = {
diff --git a/hw/net/e1000.c b/hw/net/e1000.c
index 093c2d4..1985628 100644
--- a/hw/net/e1000.c
+++ b/hw/net/e1000.c
@@ -1770,6 +1770,7 @@ static const E1000Info e1000_devices[] = {
         .revision  = 0x03,
         .phy_id2   = E1000_PHY_ID2_8254xx_DEFAULT,
     },
+#if 0 /* Disabled for Red Hat Enterprise Linux 7 */
     {
         .name      = "e1000-82544gc",
         .device_id = E1000_DEV_ID_82544GC_COPPER,
@@ -1782,6 +1783,7 @@ static const E1000Info e1000_devices[] = {
         .revision  = 0x03,
         .phy_id2   = E1000_PHY_ID2_8254xx_DEFAULT,
     },
+#endif
 };
 
 static void e1000_register_types(void)
diff --git a/hw/ppc/spapr_cpu_core.c b/hw/ppc/spapr_cpu_core.c
index b482d97..5c52e01 100644
--- a/hw/ppc/spapr_cpu_core.c
+++ b/hw/ppc/spapr_cpu_core.c
@@ -384,10 +384,12 @@ static const TypeInfo spapr_cpu_core_type_infos[] = {
         .instance_size = sizeof(SpaprCpuCore),
         .class_size = sizeof(SpaprCpuCoreClass),
     },
+#if 0  /* Disabled for Red Hat Enterprise Linux */
     DEFINE_SPAPR_CPU_CORE_TYPE("970_v2.2"),
     DEFINE_SPAPR_CPU_CORE_TYPE("970mp_v1.0"),
     DEFINE_SPAPR_CPU_CORE_TYPE("970mp_v1.1"),
     DEFINE_SPAPR_CPU_CORE_TYPE("power5+_v2.1"),
+#endif
     DEFINE_SPAPR_CPU_CORE_TYPE("power7_v2.3"),
     DEFINE_SPAPR_CPU_CORE_TYPE("power7+_v2.1"),
     DEFINE_SPAPR_CPU_CORE_TYPE("power8_v2.0"),
diff --git a/hw/usb/meson.build b/hw/usb/meson.build
index e94149e..4a8adbf 100644
--- a/hw/usb/meson.build
+++ b/hw/usb/meson.build
@@ -52,7 +52,7 @@ system_ss.add(when: 'CONFIG_USB_SMARTCARD', if_true: files('dev-smartcard-reader
 if cacard.found()
   usbsmartcard_ss = ss.source_set()
   usbsmartcard_ss.add(when: 'CONFIG_USB_SMARTCARD',
-                      if_true: [cacard, files('ccid-card-emulated.c', 'ccid-card-passthru.c')])
+                      if_true: [cacard, files('ccid-card-passthru.c')])
   hw_usb_modules += {'smartcard': usbsmartcard_ss}
 endif
 
diff --git a/target/ppc/cpu-models.c b/target/ppc/cpu-models.c
index 7dbb47d..69fddb0 100644
--- a/target/ppc/cpu-models.c
+++ b/target/ppc/cpu-models.c
@@ -66,6 +66,7 @@
 #define POWERPC_DEF(_name, _pvr, _type, _desc)                              \\
     POWERPC_DEF_SVR(_name, _desc, _pvr, POWERPC_SVR_NONE, _type)
 
+#if 0  /* Embedded and 32-bit CPUs disabled for Red Hat Enterprise Linux */
     /* Embedded PowerPC                                                      */
     /* PowerPC 405 family                                                    */
     /* PowerPC 405 cores                                                     */
@@ -698,8 +699,10 @@
                 "PowerPC 7447A v1.2 (G4)")
     POWERPC_DEF("7457a_v1.2",    CPU_POWERPC_74x7A_v12,              7455,
                 "PowerPC 7457A v1.2 (G4)")
+#endif
     /* 64 bits PowerPC                                                       */
 #if defined(TARGET_PPC64)
+#if 0  /* Disabled for Red Hat Enterprise Linux */
     POWERPC_DEF("970_v2.2",      CPU_POWERPC_970_v22,                970,
                 "PowerPC 970 v2.2")
     POWERPC_DEF("970fx_v1.0",    CPU_POWERPC_970FX_v10,              970,
@@ -718,6 +721,7 @@
                 "PowerPC 970MP v1.1")
     POWERPC_DEF("power5+_v2.1",  CPU_POWERPC_POWER5P_v21,            POWER5P,
                 "POWER5+ v2.1")
+#endif
     POWERPC_DEF("power7_v2.3",   CPU_POWERPC_POWER7_v23,             POWER7,
                 "POWER7 v2.3")
     POWERPC_DEF("power7+_v2.1",  CPU_POWERPC_POWER7P_v21,            POWER7,
@@ -898,12 +902,15 @@ PowerPCCPUAlias ppc_cpu_aliases[] = {
     { "7447a", "7447a_v1.2" },
     { "7457a", "7457a_v1.2" },
     { "apollo7pm", "7457a_v1.0" },
+#endif
 #if defined(TARGET_PPC64)
+#if 0  /* Disabled for Red Hat Enterprise Linux */
     { "970", "970_v2.2" },
     { "970fx", "970fx_v3.1" },
     { "970mp", "970mp_v1.1" },
     { "power5+", "power5+_v2.1" },
     { "power5gs", "power5+_v2.1" },
+#endif
     { "power7", "power7_v2.3" },
     { "power7+", "power7+_v2.1" },
     { "power8e", "power8e_v2.1" },
@@ -913,12 +920,14 @@ PowerPCCPUAlias ppc_cpu_aliases[] = {
     { "power10", "power10_v2.0" },
 #endif
 
+#if 0  /* Disabled for Red Hat Enterprise Linux */
     /* Generic PowerPCs */
 #if defined(TARGET_PPC64)
     { "ppc64", "970fx_v3.1" },
 #endif
     { "ppc32", "604" },
     { "ppc", "604" },
+#endif
 
     { NULL, NULL }
 };
diff --git a/target/s390x/cpu_models_sysemu.c b/target/s390x/cpu_models_sysemu.c
index 63981bf..87a4480 100644
--- a/target/s390x/cpu_models_sysemu.c
+++ b/target/s390x/cpu_models_sysemu.c
@@ -35,6 +35,9 @@ static void check_unavailable_features(const S390CPUModel *max_model,
         (max_model->def->gen == model->def->gen &&
          max_model->def->ec_ga < model->def->ec_ga)) {
         list_add_feat("type", unavailable);
+    } else if (model->def->gen < 11 && kvm_enabled()) {
+        /* Older CPU models are not supported on Red Hat Enterprise Linux */
+        list_add_feat("type", unavailable);
     }
 
     /* detect missing features if any to properly report them */
diff --git a/target/s390x/kvm/kvm.c b/target/s390x/kvm/kvm.c
index a9e5880..4b5df17 100644
--- a/target/s390x/kvm/kvm.c
+++ b/target/s390x/kvm/kvm.c
@@ -2529,6 +2529,14 @@ void kvm_s390_apply_cpu_model(const S390CPUModel *model, Error **errp)
         error_setg(errp, "KVM doesn't support CPU models");
         return;
     }
+
+    /* Older CPU models are not supported on Red Hat Enterprise Linux */
+    if (model->def->gen < 11) {
+        error_setg(errp, "KVM: Unsupported CPU type specified: %s",
+                   MACHINE(qdev_get_machine())->cpu_type);
+        return;
+    }
+
     prop.cpuid = s390_cpuid_from_cpu_model(model);
     prop.ibc = s390_ibc_from_cpu_model(model);
     /* configure cpu features indicated via STFL(e) */
PATCH


cat <<-PATCH > ../SOURCES/0006-Machine-type-related-general-changes.patch

From ccc4a5bdc8c2f27678312364a7c12aeafd009bb6 Mon Sep 17 00:00:00 2001
From: Miroslav Rezanina <mrezanin@redhat.com>
Date: Wed, 26 May 2021 10:56:02 +0200
Subject: Initial redhat build

This patch introduces redhat build structure in redhat subdirectory. In addition,
several issues are fixed in QEMU tree:

- Change of app name for sasl_server_init in VNC code from qemu to qemu-kvm
 - As we use qemu-kvm as name in all places, this is updated to be consistent
- Man page renamed from qemu to qemu-kvm
 - man page is installed using make install so we have to fix it in qemu tree

We disable make check due to issues with some of the tests.

This rebase is based on qemu-kvm-7.1.0-7.el9

Signed-off-by: Miroslav Rezanina <mrezanin@redhat.com>
--
Rebase changes (6.1.0):
- Move build to .distro
- Move changes for support file to related commit
- Added dependency for python3-sphinx-rtd_theme
- Removed --disable-sheepdog configure option
- Added new hw-display modules
- SASL initialization moved to ui/vnc-auth-sasl.c
- Add accel-qtest-<arch> and accel-tcg-x86_64 libraries
- Added hw-usb-host module
- Disable new configure options (bpf, nvmm, slirp-smbd)
- Use -pie for ksmctl build (annocheck complain fix)

Rebase changes (6.2.0):
- removed --disable-jemalloc and --disable-tcmalloc configure options
- added audio-oss.so
- added fdt requirement for x86_64
- tests/acceptance renamed to tests/avocado
- added multiboot_dma.bin
- Add -Wno-string-plus-int to extra flags
- Updated configure options

Rebase changes (7.0.0):
- Do not use -mlittle CFLAG on ppc64le
- Used upstream handling issue with ui/clipboard.c
- Use -mlittle-endian on ppc64le instead of deleteing it in configure
- Drop --disable-libxml2 option for configure (upstream)
- Remove vof roms
- Disable AVX2 support
- Use internal meson
- Disable new configure options (dbus-display and qga-vss)
- Change permissions on installing tests/Makefile.include
- Remove ssh block driver

Rebase changes (7.1.0 rc0):
- --disable-vnc-png renamed to --disable-png (upstream)
- removed --disable-vhost-vsock and --disable-vhost-scsi
- capstone submodule removed
- Temporary include capstone build

Rebase changes (7.2.0 rc0):
- Switch --enable-slirp=system to --enable-slirp

Rebaes changes (7.2.0 rc2):
- Added new configure options (blkio and sndio, both disabled)

Rebase changes (7.2.0):
- Fix SRPM name generation to work on Fedora 37
- Switch back to system meson

Merged patches (6.0.0):
 - 605758c902 Limit build on Power to qemu-img and qemu-ga only

Merged patches (6.1.0):
- f04f91751f Use cached tarballs
- 6581165c65 Remove message with running VM count
- 03c3cac9fc spec-file: build qemu-kvm without SPICE and QXL
- e0ae6c1f6c spec-file: Obsolete qemu-kvm-ui-spice
- 9d2e9f9ecf spec: Do not build qemu-kvm-block-gluster
- cf470b4234 spec: Do not link pcnet and ne2k_pci roms
- e981284a6b redhat: Install the s390-netboot.img that we've built
- 24ef557f33 spec: Remove usage of Group: tag
- c40d69b4f4 spec: Drop %defattr usage
- f8e98798ce spec: Clean up BuildRequires
- 47246b43ee spec: Remove iasl BuildRequires
- 170dc1cbe0 spec: Remove redundant 0 in conditionals
- 8718f6fa11 spec: Add more have_XXX conditionals
- a001269ce9 spec: Remove binutils versioned Requires
- 34545ee641 spec: Remove diffutils BuildRequires
- c2c82beac9 spec: Remove redundant Requires:
- 9314c231f4 spec: Add XXX_version macros
- c43db0bf0f spec: Add have_block_rbd
- 3ecb0c0319 qga: drop StandardError=syslog
- 018049dc80 Remove iscsi support
- a2edf18777 redhat: Replace the kvm-setup.service with a /etc/modules-load.d config file
- 387b5fbcfe redhat: Move qemu-kvm-docs dependency to qemu-kvm
- 4ead693178 redhat: introducting qemu-kvm-hw-usbredir
- 4dc6fc3035 redhat: use the standard vhost-user JSON path
- 84757178b4 Fix local build
- 8c394227dd spec: Restrict block drivers in tools
- b6aa7c1fae Move tools to separate package
- eafd82e509 Split qemu-pr-helper to separate package
- 2c0182e2aa spec: RPM_BUILD_ROOT -> %{buildroot}
- 91bd55ca13 spec: More use of %{name} instead of 'qemu-kvm'
- 50ba299c61 spec: Use qemu-pr-helper.service from qemu.git (partial)
- ee08d4e0a3 spec: Use %{_sourcedir} for referencing sources
- 039e7f7d02 spec: Add tools_only
- 884ba71617 spec: %build: Add run_configure helper
- 8ebd864d65 spec: %build: Disable more bits with %{disable_everything} (partial)
- f23fdb53f5 spec: %build: Add macros for some 'configure' parameters
- fe951a8bd8 spec: %files: Move qemu-guest-agent and qemu-img earlier
- 353b632e37 spec: %install: Remove redundant bits
- 9d2015b752 spec: %install: Add %{modprobe_kvm_conf} macro
- 6d05134e8c spec: %install: Remove qemu-guest-agent /etc/qemu-kvm usage
- 985b226467 spec: %install: clean up qemu-ga section
- dfaf9c600d spec: %install: Use a single %{tools_only} section
- f6978ddb46 spec: Make tools_only not cross spec sections
- 071c211098 spec: %install: Limit time spent in %{qemu_kvm_build}
- 1b65c674be spec: misc syntactic merges with Fedora
- 4da16294cf spec: Use Fedora's pattern for specifying rc version
- d7ee259a79 spec: %files: don't use fine grained -docs file list
- 64cad0c60f spec: %files: Add licenses to qemu-common too
- c3de4f080a spec: %install: Drop python3 shebang fixup
- 46fc216115 Update local build to work with spec file improvements
- bab9531548 spec: Remove buildldflags
- c8360ab6a9 spec: Use %make_build macro
- f6966c66e9 spec: Drop make install sharedir and datadir usage
- 86982421bc spec: use %make_install macro
- 191c405d22 spec: parallelize \`make check\`
- 251a1fb958 spec: Drop explicit --build-id
- 44c7dda6c3 spec: use %{build_ldflags}
- 0009a34354 Move virtiofsd to separate package
-  34d1b200b3 Utilize --firmware configure option
- 2800e1dd03 spec: Switch toolchain to Clang/LLVM (except process-patches.sh)
- e8a70f500f spec: Use safe-stack for x86_64
- e29445d50d spec: Reenable write support for VMDK etc. in tools
- a4fe2a3e16 redhat: Disable LTO on non-x86 architectures

Merged patches (6.2.0):
- 333452440b remove sgabios dependency
- 7d3633f184 enable pulseaudio
- bd898709b0 spec: disable use of gcrypt for crypto backends in favour of gnutls
- e4f0c6dee6 spec: Remove block-curl and block-ssh dependency
- 4dc13bfe63 spec: Build the VDI block driver
- d2f2ff3c74 spec: Explicitly include compress filter
- a7d047f9c2 Move ksmtuned files to separate package

Merged patches (7.0.0):
- 098d4d08d0 spec: Rename qemu-kvm-hw-usbredir to qemu-kvm-device-usb-redirect
- c2bd0d6834 spec: Split qemu-kvm-ui-opengl
- 2c9cda805d spec: Introduce packages for virtio-gpu-* modules (changed as rhel device tree not set)
- d0414a3e0b spec: Introduce device-display-virtio-vga* packages
- 3534ec46d4 spec: Move usb-host module to separate package
- ddc14d4737 spec: Move qtest accel module to tests package
- 6f2c4befa6 spec: Extend qemu-kvm-core description
- 6f11866e4e (rhel/rhel-9.0.0) Update to qemu-kvm-6.2.0-6.el9
- da0a28758f ui/clipboard: fix use-after-free regression
- 895d4d52eb spec: Remove qemu-virtiofsd
- c8c8c8bd84 spec: Fix obsolete for spice subpackages
- d46d2710b2 spec: Obsolete old usb redir subpackage
- 6f52a50b68 spec: Obsolete ssh driver

Merged patches (7.2.0 rc4):
- 8c6834feb6 Remove opengl display device subpackages (C9S MR 124)
- 0ecc97f29e spec: Add requires for packages with additional virtio-gpu variants (C9S MR 124)

Signed-off-by: Miroslav Rezanina <mrezanin@redhat.com>

fix
---
 .distro/Makefile                        |  100 +
 .distro/Makefile.common                 |   41 +
 .distro/README.tests                    |   39 +
 .distro/modules-load.conf               |    4 +
 .distro/qemu-guest-agent.service        |    1 -
 .distro/qemu-kvm.spec.template          | 4315 +++++++++++++++++++++++
 .distro/rpminspect.yaml                 |    6 +-
 .distro/scripts/extract_build_cmd.py    |   12 +
 .distro/scripts/process-patches.sh      |    4 +
 .gitignore                              |    1 +
 README.systemtap                        |   43 +
 scripts/qemu-guest-agent/fsfreeze-hook  |    2 +-
 scripts/systemtap/conf.d/qemu_kvm.conf  |    4 +
 scripts/systemtap/script.d/qemu_kvm.stp |    1 +
 tests/check-block.sh                    |    2 +
 ui/vnc-auth-sasl.c                      |    2 +-
 16 files changed, 4573 insertions(+), 4 deletions(-)
 create mode 100644 .distro/Makefile
 create mode 100644 .distro/Makefile.common
 create mode 100644 .distro/README.tests
 create mode 100644 .distro/modules-load.conf
 create mode 100644 .distro/qemu-kvm.spec.template
 create mode 100644 README.systemtap
 create mode 100644 scripts/systemtap/conf.d/qemu_kvm.conf
 create mode 100644 scripts/systemtap/script.d/qemu_kvm.stp

diff --git a/README.systemtap b/README.systemtap
new file mode 100644
index 0000000000..ad913fc990
--- /dev/null
+++ b/README.systemtap
@@ -0,0 +1,43 @@
+QEMU tracing using systemtap-initscript
+---------------------------------------
+
+You can capture QEMU trace data all the time using systemtap-initscript.  This
+uses SystemTap's flight recorder mode to trace all running guests to a
+fixed-size buffer on the host.  Old trace entries are overwritten by new
+entries when the buffer size wraps.
+
+1. Install the systemtap-initscript package:
+  # yum install systemtap-initscript
+
+2. Install the systemtap scripts and the conf file:
+  # cp /usr/share/qemu-kvm/systemtap/script.d/qemu_kvm.stp /etc/systemtap/script.d/
+  # cp /usr/share/qemu-kvm/systemtap/conf.d/qemu_kvm.conf /etc/systemtap/conf.d/
+
+The set of trace events to enable is given in qemu_kvm.stp.  This SystemTap
+script can be customized to add or remove trace events provided in
+/usr/share/systemtap/tapset/qemu-kvm-simpletrace.stp.
+
+SystemTap customizations can be made to qemu_kvm.conf to control the flight
+recorder buffer size and whether to store traces in memory only or disk too.
+See stap(1) for option documentation.
+
+3. Start the systemtap service.
+　# service systemtap start qemu_kvm
+
+4. Make the service start at boot time.
+　# chkconfig systemtap on
+
+5. Confirm that the service works.
+  # service systemtap status qemu_kvm
+  qemu_kvm is running...
+
+When you want to inspect the trace buffer, perform the following steps:
+
+1. Dump the trace buffer.
+  # staprun -A qemu_kvm >/tmp/trace.log
+
+2. Start the systemtap service because the preceding step stops the service.
+  # service systemtap start qemu_kvm
+
+3. Translate the trace record to readable format.
+  # /usr/share/qemu-kvm/simpletrace.py --no-header /usr/share/qemu-kvm/trace-events /tmp/trace.log
diff --git a/scripts/qemu-guest-agent/fsfreeze-hook b/scripts/qemu-guest-agent/fsfreeze-hook
index 13aafd4845..e9b84ec028 100755
--- a/scripts/qemu-guest-agent/fsfreeze-hook
+++ b/scripts/qemu-guest-agent/fsfreeze-hook
@@ -8,7 +8,7 @@
 # request, it is issued with "thaw" argument after filesystem is thawed.
 
 LOGFILE=/var/log/qga-fsfreeze-hook.log
-FSFREEZE_D=\$(dirname -- "\$0")/fsfreeze-hook.d
+FSFREEZE_D=\$(dirname -- "\$(realpath \$0)")/fsfreeze-hook.d
 
 # Check whether file \$1 is a backup or rpm-generated file and should be ignored
 is_ignored_file() {
diff --git a/scripts/systemtap/conf.d/qemu_kvm.conf b/scripts/systemtap/conf.d/qemu_kvm.conf
new file mode 100644
index 0000000000..372d8160a4
--- /dev/null
+++ b/scripts/systemtap/conf.d/qemu_kvm.conf
@@ -0,0 +1,4 @@
+# Force load uprobes (see BZ#1118352)
+stap -e 'probe process("/usr/libexec/qemu-kvm").function("main") { printf("") }' -c true
+
+qemu_kvm_OPT="-s4" # per-CPU buffer size, in megabytes
diff --git a/scripts/systemtap/script.d/qemu_kvm.stp b/scripts/systemtap/script.d/qemu_kvm.stp
new file mode 100644
index 0000000000..c04abf9449
--- /dev/null
+++ b/scripts/systemtap/script.d/qemu_kvm.stp
@@ -0,0 +1 @@
+probe qemu.kvm.simpletrace.handle_qmp_command,qemu.kvm.simpletrace.monitor_protocol_*,qemu.kvm.simpletrace.migrate_set_state {}
diff --git a/tests/check-block.sh b/tests/check-block.sh
index 5de2c1ba0b..6af743f441 100755
--- a/tests/check-block.sh
+++ b/tests/check-block.sh
@@ -22,6 +22,8 @@ if [ -z "\$(find . -name 'qemu-system-*' -print)" ]; then
     skip "No qemu-system binary available ==> Not running the qemu-iotests."
 fi
 
+exit 0
+
 cd tests/qemu-iotests
 
 # QEMU_CHECK_BLOCK_AUTO is used to disable some unstable sub-tests
diff --git a/ui/vnc-auth-sasl.c b/ui/vnc-auth-sasl.c
index 47fdae5b21..2a950caa2a 100644
--- a/ui/vnc-auth-sasl.c
+++ b/ui/vnc-auth-sasl.c
@@ -42,7 +42,7 @@
 
 bool vnc_sasl_server_init(Error **errp)
 {
-    int saslErr = sasl_server_init(NULL, "qemu");
+    int saslErr = sasl_server_init(NULL, "qemu-kvm");
 
     if (saslErr != SASL_OK) {
         error_setg(errp, "Failed to initialize SASL auth: %s",
-- 
2.31.1

PATCH


cat <<-PATCH > ../SOURCES/0010-Add-x86_64-machine-types.patch

From 0935624ccdddc286d6eeeb0c1b70d78983c21aa2 Mon Sep 17 00:00:00 2001
From: Miroslav Rezanina <mrezanin@redhat.com>
Date: Fri, 19 Oct 2018 13:10:31 +0200
Subject: Add x86_64 machine types

Adding changes to add RHEL machine types for x86_64 architecture.

Signed-off-by: Miroslav Rezanina <mrezanin@redhat.com>

Rebase notes (6.1.0):
- Update qemu64 cpu spec

Rebase notes (7.0.0):
- Reset alias for all machine-types except latest one

Merged patches (6.1.0):
- 59c284ad3b x86: Add x86 rhel8.5 machine types
- a8868b42fe redhat: x86: Enable 'kvm-asyncpf-int' by default
- a3995e2eff Remove RHEL 7.0.0 machine type (only x86_64 changes)
- ad3190a79b Remove RHEL 7.1.0 machine type (only x86_64 changes)
- 84bbe15d4e Remove RHEL 7.2.0 machine type (only x86_64 changes)
- 0215eb3356 Remove RHEL 7.3.0 machine types (only x86_64 changes)
- af69d1ca6e Remove RHEL 7.4.0 machine types (only x86_64 changes)
- 8f7a74ab78 Remove RHEL 7.5.0 machine types (only x86_64 changes)

Merged patches (7.0.0):
- eae7d8dd3c x86/rhel machine types: Add pc_rhel_8_5_compat
- 6762f56469 x86/rhel machine types: Wire compat into q35 and i440fx
- 5762101438 rhel machine types/x86: set prefer_sockets
- 9ba9ddc632 x86: Add q35 RHEL 8.6.0 machine type
- 6110d865e5 x86: Add q35 RHEL 9.0.0 machine type
- dcc64971bf RHEL: mark old machine types as deprecated (partialy)
- 6b396f182b RHEL: disable "seqpacket" for "vhost-vsock-device" in rhel8.6.0

Merged patches (7.1.0 rc0):
-  38b89dc245 pc: Move s3/s4 suspend disabling to compat (only hw/i386/pc.c chunk)
-  1d6439527a WRB: Introduce RHEL 9.0.0 hw compat structure (x86_64 specific changes)
- 35b5c8554f target/i386: deprecate CPUs older than x86_64-v2 ABI

Merged patches (7.2.0 rc0):
- 0be2889fa2 Introduce upstream 7.0 compat changes (only applicable parts)
---
 hw/i386/pc.c               | 147 ++++++++++++++++++++++-
 hw/i386/pc_piix.c          |  86 +++++++++++++-
 hw/i386/pc_q35.c           | 234 ++++++++++++++++++++++++++++++++++++-
 hw/s390x/s390-virtio-ccw.c |   1 +
 include/hw/boards.h        |   2 +
 include/hw/i386/pc.h       |  27 +++++
 target/i386/cpu.c          |  21 ++++
 target/i386/kvm/kvm-cpu.c  |   1 +
 target/i386/kvm/kvm.c      |   4 +
 tests/qtest/pvpanic-test.c |   5 +-
 10 files changed, 521 insertions(+), 7 deletions(-)

diff --git a/hw/i386/pc.c b/hw/i386/pc.c
index 546b703cb4..c7b1350e64 100644
--- a/hw/i386/pc.c
+++ b/hw/i386/pc.c
@@ -393,6 +393,149 @@ GlobalProperty pc_compat_1_4[] = {
 };
 const size_t pc_compat_1_4_len = G_N_ELEMENTS(pc_compat_1_4);
 
+/* This macro is for changes to properties that are RHEL specific,
+ * different to the current upstream and to be applied to the latest
+ * machine type.
+ */
+GlobalProperty pc_rhel_compat[] = {
+    /* we don't support s3/s4 suspend */
+    { "PIIX4_PM", "disable_s3", "1" },
+    { "PIIX4_PM", "disable_s4", "1" },
+    { "ICH9-LPC", "disable_s3", "1" },
+    { "ICH9-LPC", "disable_s4", "1" },
+
+    { TYPE_X86_CPU, "host-phys-bits", "on" },
+    { TYPE_X86_CPU, "host-phys-bits-limit", "48" },
+    { TYPE_X86_CPU, "vmx-entry-load-perf-global-ctrl", "off" },
+    { TYPE_X86_CPU, "vmx-exit-load-perf-global-ctrl", "off" },
+    /* bz 1508330 */ 
+    { "vfio-pci", "x-no-geforce-quirks", "on" },
+    /* bz 1941397 */
+    { TYPE_X86_CPU, "kvm-asyncpf-int", "on" },
+};
+const size_t pc_rhel_compat_len = G_N_ELEMENTS(pc_rhel_compat);
+
+GlobalProperty pc_rhel_9_0_compat[] = {
+    /* pc_rhel_9_0_compat from pc_compat_6_2 */
+    { "virtio-mem", "unplugged-inaccessible", "off" },
+};
+const size_t pc_rhel_9_0_compat_len = G_N_ELEMENTS(pc_rhel_9_0_compat);
+
+GlobalProperty pc_rhel_8_5_compat[] = {
+    /* pc_rhel_8_5_compat from pc_compat_6_0 */
+    { "qemu64" "-" TYPE_X86_CPU, "family", "6" },
+    /* pc_rhel_8_5_compat from pc_compat_6_0 */
+    { "qemu64" "-" TYPE_X86_CPU, "model", "6" },
+    /* pc_rhel_8_5_compat from pc_compat_6_0 */
+    { "qemu64" "-" TYPE_X86_CPU, "stepping", "3" },
+    /* pc_rhel_8_5_compat from pc_compat_6_0 */
+    { TYPE_X86_CPU, "x-vendor-cpuid-only", "off" },
+    /* pc_rhel_8_5_compat from pc_compat_6_0 */
+    { "ICH9-LPC", ACPI_PM_PROP_ACPI_PCIHP_BRIDGE, "off" },
+
+    /* pc_rhel_8_5_compat from pc_compat_6_1 */
+    { TYPE_X86_CPU, "hv-version-id-build", "0x1bbc" },
+    /* pc_rhel_8_5_compat from pc_compat_6_1 */
+    { TYPE_X86_CPU, "hv-version-id-major", "0x0006" },
+    /* pc_rhel_8_5_compat from pc_compat_6_1 */
+    { TYPE_X86_CPU, "hv-version-id-minor", "0x0001" },
+};
+const size_t pc_rhel_8_5_compat_len = G_N_ELEMENTS(pc_rhel_8_5_compat);
+
+GlobalProperty pc_rhel_8_4_compat[] = {
+    /* pc_rhel_8_4_compat from pc_compat_5_2 */
+    { "ICH9-LPC", "x-smi-cpu-hotunplug", "off" },
+    { TYPE_X86_CPU, "kvm-asyncpf-int", "off" },
+};
+const size_t pc_rhel_8_4_compat_len = G_N_ELEMENTS(pc_rhel_8_4_compat);
+
+GlobalProperty pc_rhel_8_3_compat[] = {
+    /* pc_rhel_8_3_compat from pc_compat_5_1 */
+    { "ICH9-LPC", "x-smi-cpu-hotplug", "off" },
+};
+const size_t pc_rhel_8_3_compat_len = G_N_ELEMENTS(pc_rhel_8_3_compat);
+
+GlobalProperty pc_rhel_8_2_compat[] = {
+    /* pc_rhel_8_2_compat from pc_compat_4_2 */
+    { "mch", "smbase-smram", "off" },
+};
+const size_t pc_rhel_8_2_compat_len = G_N_ELEMENTS(pc_rhel_8_2_compat);
+
+/* pc_rhel_8_1_compat is empty since pc_4_1_compat is */
+GlobalProperty pc_rhel_8_1_compat[] = { };
+const size_t pc_rhel_8_1_compat_len = G_N_ELEMENTS(pc_rhel_8_1_compat);
+
+GlobalProperty pc_rhel_8_0_compat[] = {
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "intel-iommu", "dma-drain", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "Opteron_G3" "-" TYPE_X86_CPU, "rdtscp", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "Opteron_G4" "-" TYPE_X86_CPU, "rdtscp", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "Opteron_G4" "-" TYPE_X86_CPU, "npt", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "Opteron_G4" "-" TYPE_X86_CPU, "nrip-save", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "Opteron_G5" "-" TYPE_X86_CPU, "rdtscp", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "Opteron_G5" "-" TYPE_X86_CPU, "npt", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "Opteron_G5" "-" TYPE_X86_CPU, "nrip-save", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "EPYC" "-" TYPE_X86_CPU, "npt", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "EPYC" "-" TYPE_X86_CPU, "nrip-save", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "EPYC-IBPB" "-" TYPE_X86_CPU, "npt", "off" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "EPYC-IBPB" "-" TYPE_X86_CPU, "nrip-save", "off" },
+    /** The mpx=on entries from pc_compat_3_1 are in pc_rhel_7_6_compat **/
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { "Cascadelake-Server" "-" TYPE_X86_CPU, "stepping", "5" },
+    /* pc_rhel_8_0_compat from pc_compat_3_1 */
+    { TYPE_X86_CPU, "x-intel-pt-auto-level", "off" },
+};
+const size_t pc_rhel_8_0_compat_len = G_N_ELEMENTS(pc_rhel_8_0_compat);
+
+/* Similar to PC_COMPAT_3_0 + PC_COMPAT_2_12, but:
+ * all of the 2_12 stuff was already in 7.6 from bz 1481253
+ * x-migrate-smi-count comes from PC_COMPAT_2_11 but
+ * is really tied to kernel version so keep it off on 7.x
+ * machine types irrespective of host.
+ */
+GlobalProperty pc_rhel_7_6_compat[] = {
+    /* pc_rhel_7_6_compat from pc_compat_3_0 */ 
+    { TYPE_X86_CPU, "x-hv-synic-kvm-only", "on" },
+    /* pc_rhel_7_6_compat from pc_compat_3_0 */ 
+    { "Skylake-Server" "-" TYPE_X86_CPU, "pku", "off" },
+    /* pc_rhel_7_6_compat from pc_compat_3_0 */ 
+    { "Skylake-Server-IBRS" "-" TYPE_X86_CPU, "pku", "off" },
+    /* pc_rhel_7_6_compat from pc_compat_2_11 */ 
+    { TYPE_X86_CPU, "x-migrate-smi-count", "off" },
+    /* pc_rhel_7_6_compat from pc_compat_2_11 */ 
+    { "Skylake-Client" "-" TYPE_X86_CPU, "mpx", "on" },
+    /* pc_rhel_7_6_compat from pc_compat_2_11 */ 
+    { "Skylake-Client-IBRS" "-" TYPE_X86_CPU, "mpx", "on" },
+    /* pc_rhel_7_6_compat from pc_compat_2_11 */ 
+    { "Skylake-Server" "-" TYPE_X86_CPU, "mpx", "on" },
+    /* pc_rhel_7_6_compat from pc_compat_2_11 */ 
+    { "Skylake-Server-IBRS" "-" TYPE_X86_CPU, "mpx", "on" },
+    /* pc_rhel_7_6_compat from pc_compat_2_11 */ 
+    { "Cascadelake-Server" "-" TYPE_X86_CPU, "mpx", "on" },
+    /* pc_rhel_7_6_compat from pc_compat_2_11 */ 
+    { "Icelake-Client" "-" TYPE_X86_CPU, "mpx", "on" },
+    /* pc_rhel_7_6_compat from pc_compat_2_11 */ 
+    { "Icelake-Server" "-" TYPE_X86_CPU, "mpx", "on" },
+};
+const size_t pc_rhel_7_6_compat_len = G_N_ELEMENTS(pc_rhel_7_6_compat);
+
+/*
+ * The PC_RHEL_*_COMPAT serve the same purpose for RHEL-7 machine
+ * types as the PC_COMPAT_* do for upstream types.
+ * PC_RHEL_7_*_COMPAT apply both to i440fx and q35 types.
+ */
+
 GSIState *pc_gsi_create(qemu_irq **irqs, bool pci_enabled)
 {
     GSIState *s;
@@ -1907,6 +2050,7 @@ static void pc_machine_class_init(ObjectClass *oc, void *data)
     pcmc->pvh_enabled = true;
     pcmc->kvmclock_create_always = true;
     assert(!mc->get_hotplug_handler);
+    mc->async_pf_vmexit_disable = false;
     mc->get_hotplug_handler = pc_get_hotplug_handler;
     mc->hotplug_allowed = pc_hotplug_allowed;
     mc->cpu_index_to_instance_props = x86_cpu_index_to_props;
@@ -1917,7 +2061,8 @@ static void pc_machine_class_init(ObjectClass *oc, void *data)
     mc->has_hotpluggable_cpus = true;
     mc->default_boot_order = "cad";
     mc->block_default_type = IF_IDE;
-    mc->max_cpus = 255;
+    /* 240: max CPU count for RHEL */
+    mc->max_cpus = 240;
     mc->reset = pc_machine_reset;
     mc->wakeup = pc_machine_wakeup;
     hc->pre_plug = pc_machine_device_pre_plug_cb;
diff --git a/hw/i386/pc_piix.c b/hw/i386/pc_piix.c
index 0985ff67d2..173a1fd10b 100644
--- a/hw/i386/pc_piix.c
+++ b/hw/i386/pc_piix.c
@@ -53,6 +53,7 @@
 #include "qapi/error.h"
 #include "qemu/error-report.h"
 #include "sysemu/xen.h"
+#include "migration/migration.h"
 #ifdef CONFIG_XEN
 #include <xen/hvm/hvm_info_table.h>
 #include "hw/xen/xen_pt.h"
@@ -184,8 +185,8 @@ static void pc_init1(MachineState *machine,
     if (pcmc->smbios_defaults) {
         MachineClass *mc = MACHINE_GET_CLASS(machine);
         /* These values are guest ABI, do not change */
-        smbios_set_defaults("QEMU", "Standard PC (i440FX + PIIX, 1996)",
-                            mc->name, pcmc->smbios_legacy_mode,
+        smbios_set_defaults("Red Hat", "KVM",
+                            mc->desc, pcmc->smbios_legacy_mode,
                             pcmc->smbios_uuid_encoded,
                             pcmc->smbios_stream_product,
                             pcmc->smbios_stream_version,
@@ -334,6 +335,7 @@ static void pc_init1(MachineState *machine,
  * hw_compat_*, pc_compat_*, or * pc_*_machine_options().
  */
 
+#if 0 /* Disabled for Red Hat Enterprise Linux */
 static void pc_compat_2_3_fn(MachineState *machine)
 {
     X86MachineState *x86ms = X86_MACHINE(machine);
@@ -896,3 +898,83 @@ static void xenfv_3_1_machine_options(MachineClass *m)
 DEFINE_PC_MACHINE(xenfv, "xenfv-3.1", pc_xen_hvm_init,
                   xenfv_3_1_machine_options);
 #endif
+#endif  /* Disabled for Red Hat Enterprise Linux */
+
+/* Red Hat Enterprise Linux machine types */
+
+/* Options for the latest rhel7 machine type */
+static void pc_machine_rhel7_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    m->family = "pc_piix_Y";
+    m->default_machine_opts = "firmware=bios-256k.bin,hpet=off";
+    pcmc->default_nic_model = "e1000";
+    pcmc->pci_root_uid = 0;
+    m->default_display = "std";
+    m->no_parallel = 1;
+    m->numa_mem_supported = true;
+    m->auto_enable_numa_with_memdev = false;
+    machine_class_allow_dynamic_sysbus_dev(m, TYPE_RAMFB_DEVICE);
+    compat_props_add(m->compat_props, pc_rhel_compat, pc_rhel_compat_len);
+    m->alias = "pc";
+    m->is_default = 1;
+    m->smp_props.prefer_sockets = true;
+}
+
+static void pc_init_rhel760(MachineState *machine)
+{
+    pc_init1(machine, TYPE_I440FX_PCI_HOST_BRIDGE, \\
+             TYPE_I440FX_PCI_DEVICE);
+}
+
+static void pc_machine_rhel760_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_machine_rhel7_options(m);
+    m->desc = "RHEL 7.6.0 PC (i440FX + PIIX, 1996)";
+    m->async_pf_vmexit_disable = true;
+    m->smbus_no_migration_support = true;
+
+    /* All RHEL machines for prior major releases are deprecated */
+    m->deprecation_reason = rhel_old_machine_deprecation;
+
+    pcmc->pvh_enabled = false;
+    pcmc->default_cpu_version = CPU_VERSION_LEGACY;
+    pcmc->kvmclock_create_always = false;
+    /* From pc_i440fx_5_1_machine_options() */
+    pcmc->pci_root_uid = 1;
+    pcmc->legacy_no_rng_seed = true;
+    compat_props_add(m->compat_props, hw_compat_rhel_9_1,
+                     hw_compat_rhel_9_1_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_9_0,
+                     hw_compat_rhel_9_0_len);
+    compat_props_add(m->compat_props, pc_rhel_9_0_compat,
+                     pc_rhel_9_0_compat_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_8_6,
+                     hw_compat_rhel_8_6_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_8_5,
+                     hw_compat_rhel_8_5_len);
+    compat_props_add(m->compat_props, pc_rhel_8_5_compat,
+                     pc_rhel_8_5_compat_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_8_4,
+                     hw_compat_rhel_8_4_len);
+    compat_props_add(m->compat_props, pc_rhel_8_4_compat,
+                     pc_rhel_8_4_compat_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_8_3,
+                     hw_compat_rhel_8_3_len);
+    compat_props_add(m->compat_props, pc_rhel_8_3_compat,
+                     pc_rhel_8_3_compat_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_8_2,
+                     hw_compat_rhel_8_2_len);
+    compat_props_add(m->compat_props, pc_rhel_8_2_compat,
+                     pc_rhel_8_2_compat_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_8_1, hw_compat_rhel_8_1_len);
+    compat_props_add(m->compat_props, pc_rhel_8_1_compat, pc_rhel_8_1_compat_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_8_0, hw_compat_rhel_8_0_len);
+    compat_props_add(m->compat_props, pc_rhel_8_0_compat, pc_rhel_8_0_compat_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_7_6, hw_compat_rhel_7_6_len);
+    compat_props_add(m->compat_props, pc_rhel_7_6_compat, pc_rhel_7_6_compat_len);
+}
+
+DEFINE_PC_MACHINE(rhel760, "pc-i440fx-rhel7.6.0", pc_init_rhel760,
+                  pc_machine_rhel760_options);
diff --git a/hw/i386/pc_q35.c b/hw/i386/pc_q35.c
index ea582254e3..97c3630021 100644
--- a/hw/i386/pc_q35.c
+++ b/hw/i386/pc_q35.c
@@ -198,8 +198,8 @@ static void pc_q35_init(MachineState *machine)
 
     if (pcmc->smbios_defaults) {
         /* These values are guest ABI, do not change */
-        smbios_set_defaults("QEMU", "Standard PC (Q35 + ICH9, 2009)",
-                            mc->name, pcmc->smbios_legacy_mode,
+        smbios_set_defaults("Red Hat", "KVM",
+                            mc->desc, pcmc->smbios_legacy_mode,
                             pcmc->smbios_uuid_encoded,
                             pcmc->smbios_stream_product,
                             pcmc->smbios_stream_version,
@@ -352,6 +352,7 @@ static void pc_q35_init(MachineState *machine)
     DEFINE_PC_MACHINE(suffix, name, pc_init_##suffix, optionfn)
 
 
+#if 0 /* Disabled for Red Hat Enterprise Linux */
 static void pc_q35_machine_options(MachineClass *m)
 {
     PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
@@ -666,3 +667,232 @@ static void pc_q35_2_4_machine_options(MachineClass *m)
 
 DEFINE_Q35_MACHINE(v2_4, "pc-q35-2.4", NULL,
                    pc_q35_2_4_machine_options);
+#endif  /* Disabled for Red Hat Enterprise Linux */
+
+/* Red Hat Enterprise Linux machine types */
+
+/* Options for the latest rhel q35 machine type */
+static void pc_q35_machine_rhel_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pcmc->default_nic_model = "e1000e";
+    pcmc->pci_root_uid = 0;
+    m->family = "pc_q35_Z";
+    m->units_per_default_bus = 1;
+    m->default_machine_opts = "firmware=bios-256k.bin,hpet=off";
+    m->default_display = "std";
+    m->no_floppy = 1;
+    m->no_parallel = 1;
+    pcmc->default_cpu_version = 1;
+    machine_class_allow_dynamic_sysbus_dev(m, TYPE_AMD_IOMMU_DEVICE);
+    machine_class_allow_dynamic_sysbus_dev(m, TYPE_INTEL_IOMMU_DEVICE);
+    machine_class_allow_dynamic_sysbus_dev(m, TYPE_RAMFB_DEVICE);
+    m->alias = "q35";
+    m->max_cpus = 710;
+    compat_props_add(m->compat_props, pc_rhel_compat, pc_rhel_compat_len);
+}
+
+static void pc_q35_init_rhel900(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel900_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel_options(m);
+    m->desc = "RHEL-9.0.0 PC (Q35 + ICH9, 2009)";
+    pcmc->smbios_stream_product = "RHEL";
+    pcmc->smbios_stream_version = "9.0.0";
+    pcmc->legacy_no_rng_seed = true;
+    compat_props_add(m->compat_props, hw_compat_rhel_9_1,
+                     hw_compat_rhel_9_1_len);
+    compat_props_add(m->compat_props, hw_compat_rhel_9_0,
+                     hw_compat_rhel_9_0_len);
+    compat_props_add(m->compat_props, pc_rhel_9_0_compat,
+                     pc_rhel_9_0_compat_len);
+}
+
+DEFINE_PC_MACHINE(q35_rhel900, "pc-q35-rhel9.0.0", pc_q35_init_rhel900,
+                  pc_q35_machine_rhel900_options);
+
+static void pc_q35_init_rhel860(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel860_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel900_options(m);
+    m->desc = "RHEL-8.6.0 PC (Q35 + ICH9, 2009)";
+    m->alias = NULL;
+
+    /* All RHEL machines for prior major releases are deprecated */
+    m->deprecation_reason = rhel_old_machine_deprecation;
+
+    pcmc->smbios_stream_product = "RHEL-AV";
+    pcmc->smbios_stream_version = "8.6.0";
+    compat_props_add(m->compat_props, hw_compat_rhel_8_6,
+                     hw_compat_rhel_8_6_len);
+}
+
+DEFINE_PC_MACHINE(q35_rhel860, "pc-q35-rhel8.6.0", pc_q35_init_rhel860,
+                  pc_q35_machine_rhel860_options);
+
+
+static void pc_q35_init_rhel850(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel850_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel860_options(m);
+    m->desc = "RHEL-8.5.0 PC (Q35 + ICH9, 2009)";
+    m->alias = NULL;
+    pcmc->smbios_stream_product = "RHEL-AV";
+    pcmc->smbios_stream_version = "8.5.0";
+    compat_props_add(m->compat_props, hw_compat_rhel_8_5,
+                     hw_compat_rhel_8_5_len);
+    compat_props_add(m->compat_props, pc_rhel_8_5_compat,
+                     pc_rhel_8_5_compat_len);
+    m->smp_props.prefer_sockets = true;
+}
+
+DEFINE_PC_MACHINE(q35_rhel850, "pc-q35-rhel8.5.0", pc_q35_init_rhel850,
+                  pc_q35_machine_rhel850_options);
+
+
+static void pc_q35_init_rhel840(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel840_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel850_options(m);
+    m->desc = "RHEL-8.4.0 PC (Q35 + ICH9, 2009)";
+    m->alias = NULL;
+    pcmc->smbios_stream_product = "RHEL-AV";
+    pcmc->smbios_stream_version = "8.4.0";
+    compat_props_add(m->compat_props, hw_compat_rhel_8_4,
+                     hw_compat_rhel_8_4_len);
+    compat_props_add(m->compat_props, pc_rhel_8_4_compat,
+                     pc_rhel_8_4_compat_len);
+}
+
+DEFINE_PC_MACHINE(q35_rhel840, "pc-q35-rhel8.4.0", pc_q35_init_rhel840,
+                  pc_q35_machine_rhel840_options);
+
+
+static void pc_q35_init_rhel830(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel830_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel840_options(m);
+    m->desc = "RHEL-8.3.0 PC (Q35 + ICH9, 2009)";
+    m->alias = NULL;
+    pcmc->smbios_stream_product = "RHEL-AV";
+    pcmc->smbios_stream_version = "8.3.0";
+    compat_props_add(m->compat_props, hw_compat_rhel_8_3,
+                     hw_compat_rhel_8_3_len);
+    compat_props_add(m->compat_props, pc_rhel_8_3_compat,
+                     pc_rhel_8_3_compat_len);
+    /* From pc_q35_5_1_machine_options() */
+    pcmc->kvmclock_create_always = false;
+    /* From pc_q35_5_1_machine_options() */
+    pcmc->pci_root_uid = 1;
+}
+
+DEFINE_PC_MACHINE(q35_rhel830, "pc-q35-rhel8.3.0", pc_q35_init_rhel830,
+                  pc_q35_machine_rhel830_options);
+
+static void pc_q35_init_rhel820(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel820_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel830_options(m);
+    m->desc = "RHEL-8.2.0 PC (Q35 + ICH9, 2009)";
+    m->alias = NULL;
+    m->numa_mem_supported = true;
+    m->auto_enable_numa_with_memdev = false;
+    pcmc->smbios_stream_product = "RHEL-AV";
+    pcmc->smbios_stream_version = "8.2.0";
+    compat_props_add(m->compat_props, hw_compat_rhel_8_2,
+                     hw_compat_rhel_8_2_len);
+    compat_props_add(m->compat_props, pc_rhel_8_2_compat,
+                     pc_rhel_8_2_compat_len);
+}
+
+DEFINE_PC_MACHINE(q35_rhel820, "pc-q35-rhel8.2.0", pc_q35_init_rhel820,
+                  pc_q35_machine_rhel820_options);
+
+static void pc_q35_init_rhel810(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel810_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel820_options(m);
+    m->desc = "RHEL-8.1.0 PC (Q35 + ICH9, 2009)";
+    m->alias = NULL;
+    pcmc->smbios_stream_product = NULL;
+    pcmc->smbios_stream_version = NULL;
+    compat_props_add(m->compat_props, hw_compat_rhel_8_1, hw_compat_rhel_8_1_len);
+    compat_props_add(m->compat_props, pc_rhel_8_1_compat, pc_rhel_8_1_compat_len);
+}
+
+DEFINE_PC_MACHINE(q35_rhel810, "pc-q35-rhel8.1.0", pc_q35_init_rhel810,
+                  pc_q35_machine_rhel810_options);
+
+static void pc_q35_init_rhel800(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel800_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel810_options(m);
+    m->desc = "RHEL-8.0.0 PC (Q35 + ICH9, 2009)";
+    m->smbus_no_migration_support = true;
+    m->alias = NULL;
+    pcmc->pvh_enabled = false;
+    pcmc->default_cpu_version = CPU_VERSION_LEGACY;
+    compat_props_add(m->compat_props, hw_compat_rhel_8_0, hw_compat_rhel_8_0_len);
+    compat_props_add(m->compat_props, pc_rhel_8_0_compat, pc_rhel_8_0_compat_len);
+}
+
+DEFINE_PC_MACHINE(q35_rhel800, "pc-q35-rhel8.0.0", pc_q35_init_rhel800,
+                  pc_q35_machine_rhel800_options);
+
+static void pc_q35_init_rhel760(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel760_options(MachineClass *m)
+{
+    pc_q35_machine_rhel800_options(m);
+    m->alias = NULL;
+    m->desc = "RHEL-7.6.0 PC (Q35 + ICH9, 2009)";
+    m->async_pf_vmexit_disable = true;
+    compat_props_add(m->compat_props, hw_compat_rhel_7_6, hw_compat_rhel_7_6_len);
+    compat_props_add(m->compat_props, pc_rhel_7_6_compat, pc_rhel_7_6_compat_len);
+}
+
+DEFINE_PC_MACHINE(q35_rhel760, "pc-q35-rhel7.6.0", pc_q35_init_rhel760,
+                  pc_q35_machine_rhel760_options);
diff --git a/hw/s390x/s390-virtio-ccw.c b/hw/s390x/s390-virtio-ccw.c
index 8d5221fbb1..ba640e3d9e 100644
--- a/hw/s390x/s390-virtio-ccw.c
+++ b/hw/s390x/s390-virtio-ccw.c
@@ -1213,6 +1213,7 @@ static void ccw_machine_rhel860_instance_options(MachineState *machine)
 static void ccw_machine_rhel860_class_options(MachineClass *mc)
 {
     ccw_machine_rhel900_class_options(mc);
+    compat_props_add(mc->compat_props, hw_compat_rhel_8_6, hw_compat_rhel_8_6_len);
 
     /* All RHEL machines for prior major releases are deprecated */
     mc->deprecation_reason = rhel_old_machine_deprecation;
diff --git a/include/hw/boards.h b/include/hw/boards.h
index 2209d4e416..fd75f551b1 100644
--- a/include/hw/boards.h
+++ b/include/hw/boards.h
@@ -266,6 +266,8 @@ struct MachineClass {
     strList *allowed_dynamic_sysbus_devices;
     bool auto_enable_numa_with_memhp;
     bool auto_enable_numa_with_memdev;
+    /* RHEL only */
+    bool async_pf_vmexit_disable;
     bool ignore_boot_device_suffixes;
     bool smbus_no_migration_support;
     bool nvdimm_supported;
diff --git a/include/hw/i386/pc.h b/include/hw/i386/pc.h
index 3754eaa97d..4266fe2fdb 100644
--- a/include/hw/i386/pc.h
+++ b/include/hw/i386/pc.h
@@ -293,6 +293,33 @@ extern const size_t pc_compat_1_5_len;
 extern GlobalProperty pc_compat_1_4[];
 extern const size_t pc_compat_1_4_len;
 
+extern GlobalProperty pc_rhel_compat[];
+extern const size_t pc_rhel_compat_len;
+
+extern GlobalProperty pc_rhel_9_0_compat[];
+extern const size_t pc_rhel_9_0_compat_len;
+
+extern GlobalProperty pc_rhel_8_5_compat[];
+extern const size_t pc_rhel_8_5_compat_len;
+
+extern GlobalProperty pc_rhel_8_4_compat[];
+extern const size_t pc_rhel_8_4_compat_len;
+
+extern GlobalProperty pc_rhel_8_3_compat[];
+extern const size_t pc_rhel_8_3_compat_len;
+
+extern GlobalProperty pc_rhel_8_2_compat[];
+extern const size_t pc_rhel_8_2_compat_len;
+
+extern GlobalProperty pc_rhel_8_1_compat[];
+extern const size_t pc_rhel_8_1_compat_len;
+
+extern GlobalProperty pc_rhel_8_0_compat[];
+extern const size_t pc_rhel_8_0_compat_len;
+
+extern GlobalProperty pc_rhel_7_6_compat[];
+extern const size_t pc_rhel_7_6_compat_len;
+
 #define DEFINE_PC_MACHINE(suffix, namestr, initfn, optsfn) \\
     static void pc_machine_##suffix##_class_init(ObjectClass *oc, void *data) \\
     { \\
diff --git a/target/i386/cpu.c b/target/i386/cpu.c
index 22b681ca37..f7c526cbe6 100644
--- a/target/i386/cpu.c
+++ b/target/i386/cpu.c
@@ -1832,9 +1832,13 @@ static const CPUCaches epyc_milan_cache_info = {
  *  PT in VMX operation
  */
 
+#define RHEL_CPU_DEPRECATION \\
+    "use at least 'Nehalem' / 'Opteron_G4', or 'host' / 'max'"
+
 static const X86CPUDefinition builtin_x86_defs[] = {
     {
         .name = "qemu64",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 0xd,
         .vendor = CPUID_VENDOR_AMD,
         .family = 15,
@@ -1855,6 +1859,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "phenom",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 5,
         .vendor = CPUID_VENDOR_AMD,
         .family = 16,
@@ -1887,6 +1892,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "core2duo",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 10,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 6,
@@ -1929,6 +1935,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "kvm64",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 0xd,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 15,
@@ -1970,6 +1977,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "qemu32",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 4,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 6,
@@ -1984,6 +1992,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "kvm32",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 5,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 15,
@@ -2014,6 +2023,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "coreduo",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 10,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 6,
@@ -2047,6 +2057,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "486",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 1,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 4,
@@ -2059,6 +2070,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "pentium",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 1,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 5,
@@ -2071,6 +2083,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "pentium2",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 2,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 6,
@@ -2083,6 +2096,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "pentium3",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 3,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 6,
@@ -2095,6 +2109,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "athlon",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 2,
         .vendor = CPUID_VENDOR_AMD,
         .family = 6,
@@ -2110,6 +2125,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "n270",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 10,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 6,
@@ -2135,6 +2151,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "Conroe",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 10,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 6,
@@ -2175,6 +2192,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "Penryn",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 10,
         .vendor = CPUID_VENDOR_INTEL,
         .family = 6,
@@ -3762,6 +3780,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "Opteron_G1",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 5,
         .vendor = CPUID_VENDOR_AMD,
         .family = 15,
@@ -3782,6 +3801,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "Opteron_G2",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 5,
         .vendor = CPUID_VENDOR_AMD,
         .family = 15,
@@ -3804,6 +3824,7 @@ static const X86CPUDefinition builtin_x86_defs[] = {
     },
     {
         .name = "Opteron_G3",
+        .deprecation_note = RHEL_CPU_DEPRECATION,
         .level = 5,
         .vendor = CPUID_VENDOR_AMD,
         .family = 16,
diff --git a/target/i386/kvm/kvm-cpu.c b/target/i386/kvm/kvm-cpu.c
index 7237378a7d..7b8a3d5af0 100644
--- a/target/i386/kvm/kvm-cpu.c
+++ b/target/i386/kvm/kvm-cpu.c
@@ -137,6 +137,7 @@ static PropValue kvm_default_props[] = {
     { "acpi", "off" },
     { "monitor", "off" },
     { "svm", "off" },
+    { "kvm-pv-unhalt", "on" },
     { NULL, NULL },
 };
 
diff --git a/target/i386/kvm/kvm.c b/target/i386/kvm/kvm.c
index a213209379..81526a1575 100644
--- a/target/i386/kvm/kvm.c
+++ b/target/i386/kvm/kvm.c
@@ -3707,6 +3707,7 @@ static int kvm_get_msrs(X86CPU *cpu)
     struct kvm_msr_entry *msrs = cpu->kvm_msr_buf->entries;
     int ret, i;
     uint64_t mtrr_top_bits;
+    MachineClass *mc = MACHINE_GET_CLASS(qdev_get_machine());
 
     kvm_msr_buf_reset(cpu);
 
@@ -4062,6 +4063,9 @@ static int kvm_get_msrs(X86CPU *cpu)
             break;
         case MSR_KVM_ASYNC_PF_EN:
             env->async_pf_en_msr = msrs[i].data;
+            if (mc->async_pf_vmexit_disable) {
+                env->async_pf_en_msr &= ~(1ULL << 2);
+            }
             break;
         case MSR_KVM_ASYNC_PF_INT:
             env->async_pf_int_msr = msrs[i].data;
diff --git a/tests/qtest/pvpanic-test.c b/tests/qtest/pvpanic-test.c
index bc7b7dfc39..96e6dee3a1 100644
--- a/tests/qtest/pvpanic-test.c
+++ b/tests/qtest/pvpanic-test.c
@@ -17,7 +17,7 @@ static void test_panic_nopause(void)
     QDict *response, *data;
     QTestState *qts;
 
-    qts = qtest_init("-device pvpanic -action panic=none");
+    qts = qtest_init("-M q35 -device pvpanic -action panic=none");
 
     val = qtest_inb(qts, 0x505);
     g_assert_cmpuint(val, ==, 3);
@@ -40,7 +40,8 @@ static void test_panic(void)
     QDict *response, *data;
     QTestState *qts;
 
-    qts = qtest_init("-device pvpanic -action panic=pause");
+    /* RHEL: Use q35 */
+    qts = qtest_init("-M q35 -device pvpanic -action panic=pause");
 
     val = qtest_inb(qts, 0x505);
     g_assert_cmpuint(val, ==, 3);
-- 
2.31.1

PATCH

cat <<-PATCH > ../SOURCES/0018-Addd-7.2-compat-bits-for-RHEL-9.1-machine-type.patch
From 21ed34787b9492c2cfe3d8fc12a32748bcf02307 Mon Sep 17 00:00:00 2001
From: Miroslav Rezanina <mrezanin@redhat.com>
Date: Wed, 9 Nov 2022 07:08:32 -0500
Subject: Addd 7.2 compat bits for RHEL 9.1 machine type

Signed-off-by: Miroslav Rezanina <mrezanin@redhat.com>
---
 hw/core/machine.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/hw/core/machine.c b/hw/core/machine.c
index 9edec1ca05..3d851d34da 100644
--- a/hw/core/machine.c
+++ b/hw/core/machine.c
@@ -54,6 +54,8 @@ GlobalProperty hw_compat_rhel_9_1[] = {
   { "arm-gicv3-common", "force-8-bit-prio", "on" },
   /* hw_compat_rhel_9_1 from hw_compat_7_0 */
   { "nvme-ns", "eui64-default", "on"},
+  /* hw_compat_rhel_9_1 from hw_compat_7_1 */
+  { "virtio-device", "queue_reset", "false" },
 };
 const size_t hw_compat_rhel_9_1_len = G_N_ELEMENTS(hw_compat_rhel_9_1);
 
-- 
2.31.1
PATCH

cat <<-PATCH > ../SOURCES/0022-x86-rhel-9.2.0-machine-type.patch

From f33ca8aed4744238230f1f2cc47df77aa4c9e0ac Mon Sep 17 00:00:00 2001
From: "Dr. David Alan Gilbert" <dgilbert@redhat.com>
Date: Thu, 17 Nov 2022 12:36:30 +0000
Subject: x86: rhel 9.2.0 machine type

Add a 9.2.0 x86 machine type, and fix up the compatibility
for 9.0.0 and older.

pc_compat_7_1 and pc_compat_7_0 are both empty upstream so there's
nothing to do there.

Signed-off-by: Dr. David Alan Gilbert <dgilbert@redhat.com>
---
 hw/i386/pc_piix.c |  1 +
 hw/i386/pc_q35.c  | 21 ++++++++++++++++++++-
 2 files changed, 21 insertions(+), 1 deletion(-)

diff --git a/hw/i386/pc_piix.c b/hw/i386/pc_piix.c
index 173a1fd10b..fc06877344 100644
--- a/hw/i386/pc_piix.c
+++ b/hw/i386/pc_piix.c
@@ -944,6 +944,7 @@ static void pc_machine_rhel760_options(MachineClass *m)
     /* From pc_i440fx_5_1_machine_options() */
     pcmc->pci_root_uid = 1;
     pcmc->legacy_no_rng_seed = true;
+    pcmc->enforce_amd_1tb_hole = false;
     compat_props_add(m->compat_props, hw_compat_rhel_9_1,
                      hw_compat_rhel_9_1_len);
     compat_props_add(m->compat_props, hw_compat_rhel_9_0,
diff --git a/hw/i386/pc_q35.c b/hw/i386/pc_q35.c
index 97c3630021..52cfe3bf45 100644
--- a/hw/i386/pc_q35.c
+++ b/hw/i386/pc_q35.c
@@ -692,6 +692,23 @@ static void pc_q35_machine_rhel_options(MachineClass *m)
     compat_props_add(m->compat_props, pc_rhel_compat, pc_rhel_compat_len);
 }
 
+static void pc_q35_init_rhel920(MachineState *machine)
+{
+    pc_q35_init(machine);
+}
+
+static void pc_q35_machine_rhel920_options(MachineClass *m)
+{
+    PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
+    pc_q35_machine_rhel_options(m);
+    m->desc = "RHEL-9.2.0 PC (Q35 + ICH9, 2009)";
+    pcmc->smbios_stream_product = "RHEL";
+    pcmc->smbios_stream_version = "9.2.0";
+}
+
+DEFINE_PC_MACHINE(q35_rhel920, "pc-q35-rhel9.2.0", pc_q35_init_rhel920,
+                  pc_q35_machine_rhel920_options);
+
 static void pc_q35_init_rhel900(MachineState *machine)
 {
     pc_q35_init(machine);
@@ -700,11 +717,13 @@ static void pc_q35_init_rhel900(MachineState *machine)
 static void pc_q35_machine_rhel900_options(MachineClass *m)
 {
     PCMachineClass *pcmc = PC_MACHINE_CLASS(m);
-    pc_q35_machine_rhel_options(m);
+    pc_q35_machine_rhel920_options(m);
     m->desc = "RHEL-9.0.0 PC (Q35 + ICH9, 2009)";
+    m->alias = NULL;
     pcmc->smbios_stream_product = "RHEL";
     pcmc->smbios_stream_version = "9.0.0";
     pcmc->legacy_no_rng_seed = true;
+    pcmc->enforce_amd_1tb_hole = false;
     compat_props_add(m->compat_props, hw_compat_rhel_9_1,
                      hw_compat_rhel_9_1_len);
     compat_props_add(m->compat_props, hw_compat_rhel_9_0,
-- 
2.31.1

PATCH

cat <<-PATCH > ../SOURCES/kvm-redhat-fix-virt-rhel9.2.0-compat-props.patch
                        ../SOURCES/kvm-redhat-fix-virt-rhel9.2.0-compat-props.patch
From 546e4213c4e8a7b2e369315a71bc9aec091eed6e Mon Sep 17 00:00:00 2001
From: Cornelia Huck <cohuck@redhat.com>
Date: Mon, 19 Dec 2022 10:30:26 +0100
Subject: redhat: fix virt-rhel9.2.0 compat props

RH-Author: Cornelia Huck <cohuck@redhat.com>
RH-MergeRequest: 127: redhat: fix virt-rhel9.2.0 compat props
RH-Bugzilla: 2154640
RH-Acked-by: Eric Auger <eric.auger@redhat.com>
RH-Acked-by: Gavin Shan <gshan@redhat.com>
RH-Acked-by: Miroslav Rezanina <mrezanin@redhat.com>
RH-Commit: [1/1] 49635fdc1d9a934ece78abd160b07c19909f876a (cohuck/qemu-kvm-c9s)

We need to include arm_rhel_compat props in the latest machine.

Signed-off-by: Cornelia Huck <cohuck@redhat.com>
---
 hw/arm/virt.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/hw/arm/virt.c b/hw/arm/virt.c
index 0a94f31dd1..bf18838b87 100644
--- a/hw/arm/virt.c
+++ b/hw/arm/virt.c
@@ -3520,6 +3520,7 @@ type_init(rhel_machine_init);
 
 static void rhel920_virt_options(MachineClass *mc)
 {
+    compat_props_add(mc->compat_props, arm_rhel_compat, arm_rhel_compat_len);
 }
 DEFINE_RHEL_MACHINE_AS_LATEST(9, 2, 0)
 
@@ -3529,7 +3530,6 @@ static void rhel900_virt_options(MachineClass *mc)
 
     rhel920_virt_options(mc);
 
-    compat_props_add(mc->compat_props, arm_rhel_compat, arm_rhel_compat_len);
     compat_props_add(mc->compat_props, hw_compat_rhel_9_1, hw_compat_rhel_9_1_len);
 
     /* Disable FEAT_LPA2 since old kernels (<= v5.12) don't boot with that feature */
-- 
2.38.1

PATCH








# Commit the spec files before running sed on them.
git add *.spec && git commit -m "Post patch spec files." || exit 1

# Some changes are just easier with sed.
sed -i 's/defined rhel/defined nullified/g' edk2.spec
sed -i 's/defined fedora/defined rhel/g' edk2.spec
sed -i 's/\.\/edk2\-build\.py \-\-config/.\/edk2-build.py --jobs 8 --config/g' edk2.spec 

# Fix the version string.
sed -E -i "s/^Version:(\s*).*/Version:\1$(date +%Y%m%d)/g" passt.spec 

# Use a release string of BTRH_EPOCH so the virt-manager rebuild will be seen as an upgrade.
sed -E -i "s/^Epoch:(\s*)[0-9]*/Epoch:\1$BTRH_EPOCH/g" qemu.spec
sed -E -i "s/^Epoch:(\s*)[0-9]*/Epoch:\1$BTRH_EPOCH/g" libcacard.spec
sed -E -i "s/^Epoch:(\s*)[0-9]*/Epoch:\1$BTRH_EPOCH/g" libguestfs.spec
sed -E -i "s/^Epoch:(\s*)[0-9]*/Epoch:\1$BTRH_EPOCH/g" guestfs-tools.spec

# When Epoch isn't an option, we modify the Release string.
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" passt.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" avahi.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" spice.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" remmina.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" spice-gtk.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" libguestfs.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" virt-backup.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" virt-viewer.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" virt-manager.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" guestfs-tools.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" virglrenderer.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" spice-protocol.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" libvirt.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" libvirt-dbus.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" libvirt-glib.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" libvirt-python.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" gtk-vnc.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" mesa.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" libosinfo.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" libcacard.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" osinfo-db-tools.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" chunkfs.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" phodav.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" python-pefile.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" xorg-x11-drv-nouveau.spec

# These spec files use non-standard Release strings, so adjust the regexp accordingly.
sed -E -i "s/^Release:(\s*).*/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" pcre2.spec
sed -E -i "s/^Release:(\s*).*/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" libXvMC.spec

# These spec files use the same auto release tool to generate a release number, so they use the same regex to update it.
sed -E -i "s/^(\s*)release_number(\s*)\=(\s*)[0-9]*(\s*)\;/\1release_number\2\=\3$BTRH_EPOCH\4\;/g" edk2.spec
sed -E -i "s/^(\s*)release_number(\s*)\=(\s*)[0-9]*(\s*)\;/\1release_number\2\=\3$BTRH_EPOCH\4\;/g" lzfse.spec
sed -E -i "s/^(\s*)release_number(\s*)\=(\s*)[0-9]*(\s*)\;/\1release_number\2\=\3$BTRH_EPOCH\4\;/g" osinfo-db.spec
sed -E -i "s/^(\s*)release_number(\s*)\=(\s*)[0-9]*(\s*)\;/\1release_number\2\=\3$BTRH_EPOCH\4\;/g" python-virt-firmware.spec

# These spec files add extra a commit to release string. 
sed -E -i "s/^Release:(\s*)[0-9]*(\.git\%\{hash\})?\%\{\?dist\}/Release:\1$BTRH_EPOCH\2\%\{\?dist\}/g" openbios.spec
sed -E -i "s/^Release\:(\s*)[0-9]*(\.svn[0-9]*)?\%\{\?dist\}/Release:\1$BTRH_EPOCH\2\%\{\?dist\}/g" fcode-utils.spec
sed -E -i "s/^Release:(\s*)[0-9]*(\.git\%\{gittagcommit\})?\%\{\?dist\}/Release:\1$BTRH_EPOCH\2\%\{\?dist\}/g" SLOF.spec

# These spec files include placeholders for dev/rc/git strings. To avoid version comparison issues, we remove the placeholders.
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?gver\}\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" xorg-x11-drv-qxl.spec
sed -E -i "s/^Release\:(\s*)[0-9]*\%\{\?gitrev\}\%\{\?dist\}/Release:\1$BTRH_EPOCH\%\{\?dist\}/g" xorg-x11-drv-intel.spec

sed -E -i "s/\%global(\s*)baserelease(\s*)[0-9]*/\%global\1baserelease\2$BTRH_EPOCH/g" qemu.spec
sed -E -i "s/^Release\:(\s*)\%\{baserelease\}\%\{\?rcrel\}\%\{\?dist\}/Release:\1\%\{baserelease\}\%\{\?rcrel\}.btrh9/g" qemu.spec

## Check whether all of the build dependencies, available in the distro repositories, are 
## installed. Any missing dependencies should be those we intend to build and install below.
touch $HOME/BUILD-DEPS.txt


# Look for packages we know will cause problems, and warn/remove them so we don't keep repeating 
# the same mistakes.
## sgabios   - The QEMU spec file lists sgabios as obsolete, and this will create an installation conflict.
## tpm-tools - The tpm-tools packages cause the QEMU unit tests to fail. Use tpm2 instead.
## gtk-vnc   - Originally provided older versions of the GTK VNC widgets, which failed
PACKAGES=( sgabios sgabios-bin tpm-tools tpm-tools-devel tpm-tools-pkcs11 gtk-vnc )
for PKG in "${PACKAGES[@]}" ; do
	[ $(rpm -qa $PKG 2>/dev/null) ] && { printf "The $PKG package is installed. It will break the build.\n" | tee -a $HOME/BUILD-DEPS.txt ; }
done

# Look for build deps which aren't available in the repos. Packages we plan to build are removed from the list.
parallel --jobs 4 --line-buffer --xapply 'dnf --enablerepo=* builddep --assumeno --spec {1} 2>&1' ":::" "$(ls -1 *.spec)" | grep "No matching package to install" | sort | uniq | grep -Ev "spice-server|spice-glib|qtermwidget|python3-virt-firmware|spice-client-gtk|lxqt|libvirt|libphodav|gtk-vnc|Qt5Xdg|libXvMC|avahi|gvnc|virglrenderer" | tee -a $HOME/BUILD-DEPS.txt

# Look for deps that are available in the repos but not installed. Packages we plan to build are removed from the list.
parallel --jobs 4 --line-buffer --xapply 'dnf --enablerepo=* builddep --assumeno --spec {1} 2>&1' ":::" "$(ls -1 *.spec)" | grep -E "^ [A-Za-z0-9]" | grep -Ev "^ Package " | sort | uniq | grep -Ev "fcode-utils|libcacard|spice-protocol|libguestfs|perl-Sys-Guestfs" | tee -a $HOME/BUILD-DEPS.txt

# Check that the build deps file is empty.
[ $(cat $HOME/BUILD-DEPS.txt | wc -l) != 0 ] && { printf "\n\e[1;91m# A build dependency issue was detected, aborting.\e[0;0m\n\n" ; cat $HOME/BUILD-DEPS.txt ; printf "\n\n" ; exit 1 ; }

# If this file is empty, the script won't exit, and it can be removed.
rm --force $HOME/BUILD-DEPS.txt 

# Build the spec files.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) mesa.spec 2>&1 | tee mesa.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " mesa.spec ) 2>/dev/null ) || \
{ printf "\n\e[1;91m# The mesa rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The mesa rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) avahi.spec 2>&1 | tee avahi.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " avahi.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The avahi rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The avahi rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) pcre2.spec 2>&1 | tee pcre2.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " pcre2.spec ) || \
{ printf "\n\e[1;91m# The pcre2 rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The pcre2s rpmbuild finished.\e[0;0m\n"

# The spice/qemu/libvirt packages.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) lzfse.spec 2>&1 | tee lzfse.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " lzfse.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The lzfse rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The lzfse rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) virglrenderer.spec 2>&1 | tee virglrenderer.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " virglrenderer.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The virglrenderer rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The virglrenderer rpmbuild finished.\e[0;0m\n"

# If the tpm2-abrmd packages have been installed, the libcacard unit tests will fail.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libcacard.spec 2>&1 | tee libcacard.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libcacard.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The libcacard rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libcacard rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) fcode-utils.spec 2>&1 | tee fcode-utils.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " fcode-utils.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The fcode-utils rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The fcode-utils rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) openbios.spec 2>&1 | tee openbios.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " openbios.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The openbios rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The openbios rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) python-pefile.spec 2>&1 | tee python-pefile.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q  $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " python-pefile.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The python-pefile rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The python-pefile rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) python-virt-firmware.spec 2>&1 | tee python-virt-firmware.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q  $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " python-virt-firmware.spec ) 2>/dev/null | grep -Ev "python3-virt-firmware-tests|uki-direct") || \
{ printf "\n\e[1;91m# The python-virt-firmware rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The python-virt-firmware rpmbuild finished.\e[0;0m\n"

# Note that libvirt-daemon-driver-qemu (the official v9.0.0 package) conflicts with edk2-aarch64. As such, we erase that
# package before installing the edk2 packages. To avoid removing all of the libvirt packages, we use the nodeps flag.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) edk2.spec 2>&1 | tee edk2.log > /dev/null && \
rpm -e --nodeps libvirt-daemon-driver-qemu && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " edk2.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The edk2 rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The edk2 rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) SLOF.spec 2>&1 | tee SLOF.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " SLOF.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The SLOF rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The SLOF rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) spice-protocol.spec 2>&1 | tee spice-protocol.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " spice-protocol.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The spice-protocol rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The spice-protocol rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) phodav.spec 2>&1 | tee phodav.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " phodav.spec ) 2>/dev/null ) || \
{ printf "\n\e[1;91m# The phodav rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The phodav rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) spice-gtk.spec 2>&1 | tee spice-gtk.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " spice-gtk.spec ) || \
{ printf "\n\e[1;91m# The spice-gtk rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The spice-gtk rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) spice.spec 2>&1 | tee spice.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q  $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " spice.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The spice rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The spice rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) passt.spec 2>&1 | tee passt.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " passt.spec ) || \
{ printf "\n\e[1;91m# The passt rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\n\e[1;92m# The passt rpmbuild finished.\e[0;0m\n"

# QEMU will look for the gvnc-1.0 package config, so we include an upgrade flag to make this gtk-vnc2 package replace the upstream gtk-vnc package.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) gtk-vnc.spec 2>&1 | tee gtk-vnc.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " gtk-vnc.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The gtk-vnc rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The gtk-vnc rpmbuild finished.\e[0;0m\n"

# Disabled features.
# VDE = or Virtual Distributed Ethernet enables support for virtualized networks.
# NVMM = is the NetBSD Virtual Machine Monitor and NetBSD's native hypervisor.
# U2F = emulation for Universal 2nd Factor hardware security fobs/devices
# AF_ALG = is a socket type used to access Linux kernel crypto modules.
# HVF = is the  macOS hypervisor aka the Hypervisor.framework.
# CFI = is a hardening technique, which ensures function pointers call compatible functions.
rpmbuild -ba --rebuild --target=$(uname -m) qemu.spec 2>&1 | tee qemu.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " qemu.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The qemu rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The qemu rpmbuild finished.\e[0;0m\n"

# rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) qemu.spec 2>&1 | tee qemu.log > /dev/null && \
# rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " qemu.spec ) || \
# { printf "\n\e[1;91m# The qemu rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
# printf "\e[1;92m# The qemu rpmbuild finished.\e[0;0m\n"

# The libguestfs build originally required a qemu-kvm binary, so a symlink was used. Since the the 
# has been updated to generate a qemu-kvm binary, and the requirement has been removed from the 
# libguestfs spec file.
# [ ! -f /usr/bin/qemu-kvm ] && printf "\n\n\e[1;93m# The /usr/bin/qemu-kvm file is missing.\e[0;0m"
# [ ! -f /usr/libexec/qemu-kvm ] && printf "\n\n\e[1;93m# The /usr/libexec/qemu-kvm file is missing.\e[0;0m"
# [ ! -f /usr/bin/qemu-kvm ] && [ -f /usr/bin/qemu-system-x86_64 ] && sudo ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-kvm
# [ ! -f /usr/libexec/qemu-kvm ] && [ -f /usr/bin/qemu-kvm ] && sudo ln -s /usr/bin/qemu-kvm /usr/libexec/qemu-kvm

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libosinfo.spec 2>&1 | tee libosinfo.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libosinfo.spec ) || \
{ printf "\n\e[1;91m# The libosinfo rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libosinfo rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) osinfo-db-tools.spec 2>&1 | tee osinfo-db-tools.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " osinfo-db-tools.spec ) || \
{ printf "\n\e[1;91m# The osinfo-db-tools rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The osinfo-db-tools rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) osinfo-db.spec 2>&1 | tee osinfo-db.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " osinfo-db.spec ) || \
{ printf "\n\e[1;91m# The osinfo-db rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The osinfo-db rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" -D "with_modular_daemons 1" --target=$(uname -m) libvirt.spec 2>&1 | tee libvirt.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --builtrpms --undefine="dist" -D "dist .btrh9"  -D "with_modular_daemons 1" --target=$(uname -m) --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt.spec | sed 's/libvirt-admin/libvirt-daemon/g' ) || \
{ printf "\n\e[1;91m# The libvirt rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-python.spec 2>&1 | tee libvirt-python.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles  $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-python.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The libvirt-python rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt-python rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-glib.spec 2>&1 | tee libvirt-glib.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-glib.spec ) || \
{ printf "\n\e[1;91m# The libvirt-glib rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt-glib rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-dbus.spec 2>&1 | tee libvirt-dbus.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-dbus.spec ) || \
{ printf "\n\e[1;91m# The libvirt-dbus rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt-dbus rpmbuild finished.\e[0;0m\n"

# Unmaintained Upstream / 2023-10-09
# rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-designer.spec 2>&1 | tee libvirt-designer.log > /dev/null && \
# rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-designer.spec ) || \
# { printf "\n\e[1;91m# The libvirt-designer rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
# printf "\e[1;92m# The libvirt-designer rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libguestfs.spec 2>&1 | tee libguestfs.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libguestfs.spec ) || \
{ printf "\n\e[1;91m# The libguestfs rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libguestfs rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) guestfs-tools.spec 2>&1 | tee guestfs-tools.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " guestfs-tools.spec ) || \
{ printf "\n\e[1;91m# The guestfs-tools rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The guestfs-tools rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) lxqt-build-tools.spec 2>&1 | tee lxqt-build-tools.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " lxqt-build-tools.spec ) || \
{ printf "\n\e[1;91m# The lxqt-build-tools rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The lxqt-build-tools rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libqtxdg.spec 2>&1 | tee libqtxdg.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libqtxdg.spec ) || \
{ printf "\n\e[1;91m# The libqtxdg rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libqtxdg rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) liblxqt.spec 2>&1 | tee liblxqt.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " liblxqt.spec ) || \
{ printf "\n\e[1;91m# The liblxqt rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The liblxqt rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) qtermwidget.spec 2>&1 | tee qtermwidget.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " qtermwidget.spec ) || \
{ printf "\n\e[1;91m# The qtermwidget rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The qtermwidget rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) qt-virt-manager.spec 2>&1 | tee qt-virt-manager.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " qt-virt-manager.spec ) || \
{ printf "\n\e[1;91m# The qt-virt-manager rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The qt-virt-manager rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) chunkfs.spec 2>&1 | tee chunkfs.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " chunkfs.spec ) || \
{ printf "\n\e[1;91m# The chunkfs rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The chunkfs rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) virt-manager.spec 2>&1 | tee virt-manager.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " virt-manager.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The virt-manager rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The virt-manager rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) virt-backup.spec 2>&1 | tee virt-backup.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " virt-backup.spec ) || \
{ printf "\n\e[1;91m# The virt-backup rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The virt-backup rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) virt-viewer.spec 2>&1 | tee virt-viewer.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " virt-viewer.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The virt-viewer rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The virt-viewer rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) remmina.spec 2>&1 | tee remmina.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " remmina.spec ) || \
{ printf "\n\e[1;91m# The remmina rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The remmina rpmbuild finished.\e[0;0m\n"



# Bonus drivers for testing. They might improve performance/stability. The libXvMC is needed by the Intel driver.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libXvMC.spec 2>&1 | tee libXvMC.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libXvMC.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The libXvMC rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\n\e[1;92m# The libXvMC rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) xorg-x11-drv-intel.spec 2>&1 | tee xorg-x11-drv-intel.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " xorg-x11-drv-intel.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The xorg-x11-drv-intel rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The xorg-x11-drv-intel rpmbuild finished.\e[0;0m\n"


rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) xorg-x11-drv-nouveau.spec 2>&1 | tee xorg-x11-drv-nouveau.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " xorg-x11-drv-nouveau.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The xorg-x11-drv-nouveau rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The xorg-x11-drv-nouveau rpmbuild finished.\e[0;0m\n"

# The QXL driver requires the spice-protocol and the spice-server packages. 
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) xorg-x11-drv-qxl.spec 2>&1 | tee xorg-x11-drv-qxl.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " xorg-x11-drv-qxl.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The xorg-x11-drv-qxl rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\n\e[1;92m# The xorg-x11-drv-qxl rpmbuild finished.\e[0;0m\n"

# This command makes it easy to visually confirm every spec file has a corresponding
# build log. Presumably if a build fails, the script will exit with
# an error. Based on that assumption, the visual check allows us to confirm every
# package was built.
# ls -1 *.spec *.log | sort -f | grep --color=auto -E ".*log$" -C 10 

# Copy the SPECs/LOGs so they can be exported from the build environment.
mkdir /home/vagrant/LOGS/
mkdir /home/vagrant/SPECS/
cp $HOME/rpmbuild/SPECS/*.log /home/vagrant/LOGS/
cp $HOME/rpmbuild/SPECS/*.spec /home/vagrant/SPECS/
cp -r $HOME/rpmbuild/SPECS/.git /home/vagrant/SPECS/
chmod 655 /home/vagrant/LOGS/*.log /home/vagrant/SPECS/*.spec
chown -R vagrant:vagrant /home/vagrant/LOGS/ /home/vagrant/SPECS/

# Consolidate the compiled RPM files,
mkdir $HOME/RPMS/
mkdir $HOME/RPMS/depends/

find $HOME/rpmbuild/RPMS/noarch/*rpm $HOME/rpmbuild/RPMS/x86_64/*rpm $HOME/rpmbuild/SRPMS/*btrh*rpm > $HOME/rpm.outputs.txt
mv $HOME/rpmbuild/RPMS/noarch/*rpm $HOME/rpmbuild/RPMS/x86_64/*rpm $HOME/rpmbuild/SRPMS/*btrh*rpm $HOME/RPMS/

# Download various dependencies needed for installation. We add them to the repo as RPMs if 
# they aren't available from the official, and/or, EPEL repos.
cd $HOME/RPMS/depends/

# SDL2
dnf --quiet --enablerepo=remi --enablerepo=remi-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download SDL2_image SDL2_image-debuginfo SDL2_image-devel SDL2_image-debugsource

# pcsc-lite
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debuginfo --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download pcsc-lite pcsc-lite-debuginfo pcsc-lite-debugsource pcsc-lite-devel pcsc-lite-devel-debuginfo pcsc-lite-libs pcsc-lite-libs-debuginfo pcsc-lite-ccid pcsc-lite-ccid-debuginfo pcsc-lite-ccid-debugsource

# usbredir
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debuginfo --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download usbredir usbredir-devel usbredir-debuginfo usbredir-debugsource

# opus
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debuginfo --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download opus opus-devel opus-debuginfo opus-debugsource

# gobject-introspection
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debuginfo --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download gobject-introspection gobject-introspection-devel gobject-introspection-debuginfo gobject-introspection-debugsource

# libogg
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debuginfo --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download libogg libogg-devel libogg-debuginfo libogg-debugsource

# capstone
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debuginfo --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download capstone capstone-devel capstone-debuginfo capstone-debugsource python3-capstone python3-capstone-debuginfo

# vala
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debuginfo --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download vala libvala libvala-devel vala-debuginfo vala-debugsource valadoc-debuginfo libvala-debuginfo

# python3-markdown
dnf --quiet --enablerepo=crb --enablerepo=crb-debuginfo --arch=noarch --urlprotocol=https --downloaddir=$HOME/RPMS/depends/ download python3-markdown

# Download these compiled libblkio packages.
curl -LOs https://archive.org/download/libblkio-eln125/libblkio-1.2.2-2.eln125.x86_64.rpm
curl -LOs https://archive.org/download/libblkio-eln125/libblkio-devel-1.2.2-2.eln125.x86_64.rpm

sha256sum -c <<-EOF || { printf "\n\e[1;91m# The libblkio download failed.\e[0;0m\n\n" ; exit 1 ; }
637892248b0875e1b2ca2e14039ca20fa1a7d91f765385040f58e8487dca83ad  libblkio-1.2.2-2.eln125.x86_64.rpm
6f0ab5cf409c448b32ee9bdf6875d2e8c7557475dc294edf80fbcc478516c25e  libblkio-devel-1.2.2-2.eln125.x86_64.rpm
EOF

cd $HOME/RPMS/
tee $HOME/RPMS/INSTALL.sh <<-EOF > /dev/null
#!/bin/bash -eu

# Name: INSTALL.sh
# Author: Ladar Levison

# Description: This script removes conflicting packages which may have 
#   been installed from distro repositories, and replaces them with 
#   improved versions. 

# License: This script is hereby placed in the public domain, AND IS 
#   ROVIDED BY THE AUTHORS 'AS IS' WITHOUT ANY EXPRESS, IMPLIED, OR
#   IMAGINARY WARRANTIES. THIS INCLUDES BUT IS NOT LIMITED TO, THE IMPLIED
#   WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE,
#   ALL OF WHICH ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS
#   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SCRIPT. THIS 
#   APPLIES REGARDLESS OF JURISDICTION, PHYSICAL OR VIRTUAL LOCATION, AND
#   sREMAINS APPLICABLE EVEN IF YOU HAVE BEEN ADVISED OF THE RISKS.


# Quickly Install Everuthing (Except the vala/ocaml pcakages)
# sudo dnf install \`ls *rpm | grep -Ev "\\.src\\.|debuginfo|debugsource|devel|ocaml|vala|uki-direct"\` \`ls libguestfs-devel*rpm libvirt-gobject-devel*rpm libvirt-gconfig-devel*rpm libvirt-glib-devel*rpm  libvirt-devel*rpm libguestfs-gobject-devel*rpm gobject-introspection-devel*rpm pcre2-devel*rpm libosinfo-devel*rpm\`


if [ ! \$(sudo dnf repolist --quiet baseos 2>&1 | grep -Eo "^baseos") ]; then  
 printf "\\nThe baseos repo is required but doesn't appear to be enabled.\\n\\n"
 exit 1
fi

if [ ! \$(sudo dnf repolist --quiet appstream 2>&1 | grep -Eo "^appstream") ]; then  
 printf "\\nThe appstream repo is required but doesn't appear to be enabled.\\n\\n"
 exit 1
fi
if [ ! \$(sudo dnf repolist --quiet epel 2>&1 | grep -Eo "^epel") ]; then  
 printf "\\nThe epel repo is required but doesn't appear to be installed (or enabled).\\n\\n"
 exit 1
fi

# To generate a current/updated list of RPM files for installation, run the following command.

# Install the basic qemu/libvirt/virt-manager/spice packages.
export INSTALLPKGS=\$(echo \`ls depends/opus*rpm depends/usbredir*rpm depends/capstone*rpm depends/python3-capstone*rpm depends/libblkio*rpm depends/SDL2*rpm depends/libogg-devel*rpm depends/pcsc-lite*rpm depends/usbredir-devel*rpm depends/opus-devel*rpm depends/gobject-introspection-devel*rpm depends/python3-markdown*rpm depends/vala*rpm depends/libvala*rpm avahi*rpm qemu*rpm spice*rpm openbios*rpm lzfse*rpm virglrenderer*rpm libcacard*rpm edk2*rpm SLOF*rpm mesa-libgbm*rpm mesa-libgbm-devel*rpm virt-manager*rpm virt-viewer*rpm virt-install*rpm virt-backup*rpm passt*rpm libphodav*rpm gvnc*rpm gtk-vnc*rpm chunkfs*rpm osinfo*rpm libosinfo*rpm libvirt*rpm python3-libvirt*rpm chezdav*rpm fcode-utils*rpm python3-pefile*rpm python3-virt-firmware*rpm libguestfs*rpm python3-libguestfs*rpm guestfs-tools*rpm | grep -Ev 'qemu-guest-agent|qemu-tests|debuginfo|debugsource|\\.src\\.rpm' ; echo vala\`)

# Add the remmina packages.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls remmina*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the mesa packages.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls mesa*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the avahi packages.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls avahi*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the xorg driver packages.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls xorg-x11*rpm libXvMC*rpm pcre2*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the pcre2-static package.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls pcre2-static-*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the qt version of virt manager. The gnutls/scrub packages are suggested by the spec file, but not required.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls pcsc-lite*rpm libcacard*rpm spice*rpm qt-virt-manager*rpm qtermwidget*rpm qt-remote-viewer*rpm liblxqt*rpm libqtxdg*rpm lxqt-build-tools*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm' ; echo scrub gnutls\`)

# This looks is a list of packages which may have been installed using 
# the system repos, and are either a) not being replaced/upgraded or 
# b) being replaced by a package with a different name. If any of the 
# package names below match an installed package, they will be removed
# after the new packages are installed. We also look for any debuginfo
# and debugsource packages that are already installed, so they can be 
# removed. The current install command does not upgrade those packages.
# Of note are the qemu-kvm-DEVICES and the virtuiofsd packages. The former
# are being replaced by packages without "kvm" in the name. And the latter
# package was renamed to qemu-virtiofsd.
export REMOVEPKGS=\$(echo \`echo 'edk2-debugsource edk2-tools-debuginfo virglrenderer-debuginfo virglrenderer-debugsource virglrenderer-test-server-debuginfo virt-install virt-manager virt-manager-common virt-viewer virt-viewer-debuginfo virt-viewer-debugsource virt-backup gtk-vnc2 gtk-vnc2-devel gtk-vnc-debuginfo gtk-vnc-debugsource gvnc gvnc-devel gvncpulse gvncpulse-devel gvnc-tools libvirt-client libvirt-client-debuginfo libvirt-daemon libvirt-daemon-config-network libvirt-daemon-debuginfo libvirt-daemon-driver-interface libvirt-daemon-driver-interface-debuginfo libvirt-daemon-driver-network libvirt-daemon-driver-network-debuginfo libvirt-daemon-driver-nodedev libvirt-daemon-driver-nodedev-debuginfo libvirt-daemon-driver-nwfilter libvirt-daemon-driver-nwfilter-debuginfo libvirt-daemon-driver-qemu libvirt-daemon-driver-qemu-debuginfo libvirt-daemon-driver-secret libvirt-daemon-driver-secret-debuginfo libvirt-daemon-driver-storage libvirt-daemon-driver-storage-core libvirt-daemon-driver-storage-core-debuginfo libvirt-daemon-driver-storage-disk libvirt-daemon-driver-storage-disk-debuginfo libvirt-daemon-driver-storage-iscsi libvirt-daemon-driver-storage-iscsi-debuginfo libvirt-daemon-driver-storage-logical libvirt-daemon-driver-storage-logical-debuginfo libvirt-daemon-driver-storage-mpath libvirt-daemon-driver-storage-mpath-debuginfo libvirt-daemon-driver-storage-rbd libvirt-daemon-driver-storage-rbd-debuginfo libvirt-daemon-driver-storage-scsi libvirt-daemon-driver-storage-scsi-debuginfo libvirt-daemon-kvm libvirt-debuginfo libvirt-devel libvirt-glib libvirt-libs libvirt-libs-debuginfo libvirt-lock-sanlock-debuginfo libvirt-nss-debuginfo libvirt-wireshark-debuginfo python3-libvirt qemu-ga-win qemu-guest-agent qemu-guest-agent-debuginfo qemu-img qemu-img-debuginfo qemu-kvm qemu-kvm-audio-pa qemu-kvm-audio-pa-debuginfo qemu-kvm-block-curl qemu-kvm-block-curl-debuginfo qemu-kvm-block-rbd qemu-kvm-block-rbd-debuginfo qemu-kvm-block-ssh-debuginfo qemu-kvm-common qemu-kvm-common-debuginfo qemu-kvm-core qemu-kvm-core-debuginfo qemu-kvm-debuginfo qemu-kvm-debugsource qemu-kvm-device-display-virtio-gpu qemu-kvm-device-display-virtio-gpu-debuginfo qemu-kvm-device-display-virtio-gpu-gl qemu-kvm-device-display-virtio-gpu-gl-debuginfo qemu-kvm-device-display-virtio-gpu-pci qemu-kvm-device-display-virtio-gpu-pci-debuginfo qemu-kvm-device-display-virtio-gpu-pci-gl qemu-kvm-device-display-virtio-gpu-pci-gl-debuginfo qemu-kvm-device-display-virtio-vga qemu-kvm-device-display-virtio-vga-debuginfo qemu-kvm-device-display-virtio-vga-gl qemu-kvm-device-display-virtio-vga-gl-debuginfo qemu-kvm-device-usb-host qemu-kvm-device-usb-host-debuginfo qemu-kvm-device-usb-redirect qemu-kvm-device-usb-redirect-debuginfo qemu-kvm-docs qemu-kvm-tests-debuginfo qemu-kvm-tools qemu-kvm-tools-debuginfo qemu-kvm-ui-egl-headless qemu-kvm-ui-egl-headless-debuginfo qemu-kvm-ui-opengl qemu-kvm-ui-opengl-debuginfo qemu-pr-helper qemu-pr-helper-debuginfo libosinfo libosinfo-debuginfo libosinfo-debugsource python3-libvirt python3-libvirt-debuginfo pcsc-lite-debuginfo pcsc-lite-debugsource pcsc-lite-devel-debuginfo pcsc-lite-libs-debuginfo pcsc-lite-ccid-debuginfo pcsc-lite-ccid-debugsource mesa-libgbm-debuginfo' | tr ' ' '\\n' | while read PKG ; do { rpm --quiet -q \$PKG && rpm -q \$PKG | grep -v '\\.btrh9\\.' ; } ; done\`)

# This is handled seperately since the obsoleted qemu-virtiofsd package may be tagged with el9 or btrh9.
export REMOVEPKGS=\$(echo \$REMOVEPKGS \$(echo \`echo 'qemu-virtiofsd' | tr ' ' '\\n' | while read PKG ; do { rpm --quiet -q \$PKG && rpm -q \$PKG ; } ; done\`))

# Ensure previous attempts/transactions don't break the install attempt.
dnf clean all --enablerepo=* &>/dev/null

# On the target system, run the following command to install the new version of QEMU.
if [ "\$REMOVEPKGS" ]; then
printf "%s\\n" "install \$INSTALLPKGS" "remove \$REMOVEPKGS" "run" "exit" | dnf shell --assumeyes && dnf --assumeyes reinstall \$INSTALLPKGS || exit 1
else 
dnf --assumeyes install \$INSTALLPKGS && dnf --assumeyes reinstall \$INSTALLPKGS || exit 1
fi

# This shouldn't be needed anymore.
#[ ! -f /usr/bin/qemu-kvm ] && [ -f /usr/bin/qemu-system-x86_64 ] && sudo ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-kvm
#[ ! -f /usr/libexec/qemu-kvm ] && [ -f /usr/bin/qemu-kvm ] && sudo ln -s /usr/bin/qemu-kvm /usr/libexec/qemu-kvm

EOF

cp $HOME/BUILD.sh $HOME/RPMS/BUILD.sh
chmod 744 $HOME/RPMS/INSTALL.sh
chmod 744 $HOME/RPMS/BUILD.sh

# This will remove QEMU and its dependencies and reinstall the upstream version 
# of QEMU, so we can simulate an upgrade.
cd $HOME

# Remove the btrh packages. Everything except pcre, mesa and avahi. Those will be reinstalled.
dnf --quiet --assumeyes remove $(rpm -qa --qf="%{NAME}.%{ARCH}\t\t\t\t%{RELEASE}\n" | grep -Ev "pcre|avahi|mesa" | grep btrh | sed 's/\t\t\t\t.*//g')

# Remove the devel and debug packages because those don't (or can't) be reinstalled.
dnf --quiet --assumeyes remove $(rpm -qa --qf="%{NAME}.%{ARCH}\t\t\t\t%{RELEASE}\n" | grep btrh | grep -E "avahi\-devel|debuginfo|debugsource" | sed 's/\t\t\t\t.*//g')

# Replace the btrh packages with the distro version.
dnf --quiet --allowerasing --assumeyes downgrade  $(rpm -qa --qf="%{NAME}.%{ARCH}\t\t\t\t%{RELEASE}\n" | grep btrh | sed 's/\t\t\t\t.*//g') 

## If for some reason we need to reinstall the btrh packages, this command will do it.
# dnf --quiet --assumeyes install $(ls depends/*rpm *.rpm | grep -Ev '\.src\.rpm|uki\-direct')

# Disable these repos, so we simulate what an install would be like for someone without them.
dnf --quiet --enablerepo=* clean all  && dnf --quiet --assumeyes config-manager --disable "remi*" "elrepo*" "rpmfusion*" "crb*"

# Install the distro virt stack.
dnf --quiet --assumeyes install qemu* libvirt* virt* 

# This quiets DNF by default, which allows INSTALL.sh to run silently on the virtual 
# machine used to build the RPMS, but still INSTALL.sh use the default verbosity level
# elsewhere.
printf "\ndebuglevel=1\n" >> /etc/dnf/dnf.conf

# Execute the INSTALL.sh script on the virtual machine used to build the the RPMS. This
# and simulate replacing the official QEMU packages with the freshly built RPM files.
cd $HOME/RPMS/
printf "\e[1;32m\n\nSIMULATED INSTALL (LIMITED) STARTING\n\n\e[0;0m" 
bash -eux $HOME/RPMS/INSTALL.sh
printf "\e[1;32m\n\nSIMULATED INSTALL (COMPLETE) STARTING\n\n\e[0;0m" 
sed -i 's/## export INSTALLPKGS/##\nexport INSTALLPKGS/g' $HOME/RPMS/INSTALL.sh
bash -eux $HOME/RPMS/INSTALL.sh
sed -i -z 's/##\n/## /g' $HOME/RPMS/INSTALL.sh
printf "\e[1;32m\n\nSIMULATED INSTALL FINISHED\n\n\e[0;0m" 

# Move the compiled RPMs to the Vagrant user home directory, so they are easy to fetch via SFTP.
cd $HOME
mv $HOME/RPMS/ /home/vagrant/RPMS/
chmod 744 /home/vagrant/RPMS/ /home/vagrant//RPMS/INSTALL.sh /home/vagrant//RPMS/BUILD.sh
chmod 644 /home/vagrant/RPMS/*rpm
chown -R vagrant:vagrant /home/vagrant/RPMS/

printf "\n\nAll done.\n\n"
