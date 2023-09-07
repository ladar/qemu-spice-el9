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

sed -i -e "s/^[# ]*baseurl/baseurl/g" /etc/yum.repos.d/almalinux-*.repo
sed -i -e "s/^[# ]*mirrorlist/# mirrorlist/g" /etc/yum.repos.d/almalinux-*.repo

sed -i 's/&protocol\=https//g' /etc/yum.repos.d/epel.repo
sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/epel.repo
sed -i 's/&protocol\=https//g' /etc/yum.repos.d/epel-testing.repo
sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/epel-testing.repo

sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/elrepo.repo 
sed -i -e "s/^[# ]*mirrorlist/# mirrorlist/g" /etc/yum.repos.d/elrepo.repo 
sed -i '/mirrors.coreix.net/d' /etc/yum.repos.d/elrepo.repo

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

# As a final step we clean the cache, and reload it so the new GPG keys get approved.
dnf --enablerepo=* clean all && dnf --enablerepo=* --quiet --assumeyes makecache && \
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
 gnupg2 gnutls-devel gnutls-utils gstreamer1-devel gstreamer1-plugins-bad-free-devel rpm-build seabios \
 gstreamer1-plugins-base-devel gstreamer1-plugins-ugly gtk3-devel gzip help2man hmaccalc hostname iasl \
 intltool ipxe-roms-qemu java-devel jna kabi-dw libaio-devel libattr-devel libbpf-devel libcap-devel \
 libcap-ng-devel libcurl-devel libdbusmenu-devel libdbusmenu-gtk2-devel libdbusmenu-gtk3-devel \
 libdbusmenu-jsonloader-devel libdrm-devel libepoxy-devel libfdt-devel libiscsi-devel libjpeg-devel \
 libpmem-devel libpng-devel librbd-devel libseccomp-devel libselinux-devel libslirp-devel libssh-devel \
 libtasn1-devel libtool libudev-devel liburing-devel libusbx-devel libuuid-devel libxkbcommon-devel \
 libzstd-devel llvm-toolset ltrace lz4-devel lzo-devel m4 make mesa-libgbm-devel meson module-init-tools \
 mtools nasm ncurses-devel net-tools newt-devel numactl-devel opensc openssl openssl-devel opus-devel \
 orc-devel pam-devel patch patchutils pciutils-devel pcre-devel pcre-static pcre2-devel pcsc-lite-devel \
 perl perl-devel perl-ExtUtils-Embed perl-Fedora-VSP perl-generators perl-Test-Harness pesign \
 pipewire-jack-audio-connection-kit-devel pixman-devel pkgconf pkgconf-m4 pkgconf-pkg-config pkgconfig \
 pulseaudio-libs-devel python3-cryptography python3-devel python3-docutils python3-future python3-pytest \
 python3-sphinx python3-sphinx_rtd_theme python3-tomli rdma-core rdma-core-devel redhat-rpm-config \
 rpmconf rpmdevtools rpmlint rpmrebuild rsync SDL2-devel SDL2_image-devel seabios-bin seavgabios-bin \
 sgabios-bin snappy-devel softhsm source-highlight sparse sssd-dbus strace systemd-devel systemtap \
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
 llvm-devel libedit-devel libvdpau-trace llvm-static llvm-test doxygen doxygen-doxywizard \
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
 texlive-xltxtra texlive-xtab tpm2-pkcs11 tpm2-pkcs11-tools  \
 doxygen-latex json-c-devel libcmocka trousers trousers-devel \
 trousers-static python3-flake8 python3-mccabe gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu \
 python3-pycodestyle python3-pyflakes clang-devel clang-analyzer nfs-utils virtiofsd \
 iscsi-initiator-utils lzop swtpm-tools systemd-container mdevctl nethogs || exit 1

# Packages needed to enable X11 forwarding support.
dnf --quiet --assumeyes --enablerepo=epel --enablerepo=extras --enablerepo=plus --enablerepo=crb \
--exclude=minizip1.2 --exclude=minizip1.2-devel install \
 dbus-x11 xorg-x11-xauth xorg-x11-server-common xorg-x11-server-Xorg xorg-x11-server-Xwayland \
 libvala vala libvala-devel libssh2 libssh2-devel numactl numactl-devel augeas device-mapper-devel\
 libpcap-devel libarchive-devel libtirpc-devel parted-devel rpcgen sanlock-devel scrub \
 wireshark-devel yajl-devel libsmi sanlock-lib wireshark wireshark-cli sanlock \
 librados-devel librbd-devel mlocate cronie cronie-anacron || exit 1

# capstone / capstone-devel / python3-capstone will be available via the repos when 9.2 ships ...
curl -LOs https://archive.org/download/capstone-el9/capstone-4.0.2-9.el9.x86_64.rpm 
curl -LOs https://archive.org/download/capstone-el9/capstone-devel-4.0.2-9.el9.x86_64.rpm
curl -LOs https://archive.org/download/capstone-el9/python3-capstone-4.0.2-9.el9.x86_64.rpm
curl -LOs https://archive.org/download/libblkio-eln125/libblkio-1.2.2-2.eln125.x86_64.rpm
curl -LOs https://archive.org/download/libblkio-eln125/libblkio-devel-1.2.2-2.eln125.x86_64.rpm

sha256sum -c <<-EOF || { printf "\n\e[1;91m# The capstone/libblkio download failed.\e[0;0m\n\n" ; exit 1 ; }
c9bbc363427bb3b8b1f307dcc8c182a2ccf9b5e20bf82ff5f8b5d60fc29c0676  capstone-4.0.2-9.el9.x86_64.rpm
7a2e83c57b609ac6dd67f622eddcc62a209088b35b439951ddb5dad754e48538  capstone-devel-4.0.2-9.el9.x86_64.rpm
637892248b0875e1b2ca2e14039ca20fa1a7d91f765385040f58e8487dca83ad  libblkio-1.2.2-2.eln125.x86_64.rpm
6f0ab5cf409c448b32ee9bdf6875d2e8c7557475dc294edf80fbcc478516c25e  libblkio-devel-1.2.2-2.eln125.x86_64.rpm
8fa3fc7717fd5bf0e0fef87bc46baa52559338b031d92e0789391a0739d278ce  python3-capstone-4.0.2-9.el9.x86_64.rpm
EOF

dnf --quiet --assumeyes install libblkio-1.2.2-2.eln125.x86_64.rpm libblkio-devel-1.2.2-2.eln125.x86_64.rpm \
capstone-4.0.2-9.el9.x86_64.rpm capstone-devel-4.0.2-9.el9.x86_64.rpm python3-capstone-4.0.2-9.el9.x86_64.rpm || \
{ printf "\n\e[1;91m# The capstone/libblkio install failed.\e[0;0m\n\n" ; exit 1 ; }

rm --force libblkio-1.2.2-2.eln125.x86_64.rpm libblkio-devel-1.2.2-2.eln125.x86_64.rpm \
capstone-4.0.2-9.el9.x86_64.rpm capstone-devel-4.0.2-9.el9.x86_64.rpm python3-capstone-4.0.2-9.el9.x86_64.rpm




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

# Mock build user/group setup.
groupadd mock
useradd mockbuild 
usermod -aG mock mockbuild 

## Start the build phase.
mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Download the source package files. Note these URLs point to rawhide, and are transient.
cd ~/rpmbuild/SRPMS/

# fc37 repo
# dnf download --quiet --disablerepo=* --repofrompath="fc37,https://mirrors.kernel.org/fedora/releases/37/Everything/source/tree/" --source phodav libsoup3 

# Use the QXL driver source code from RHEL v8.
curl -fso xorg-x11-drv-qxl-0.1.5-11.el8.src.rpm https://mirrors.lavabit.com/alma-archive/8.7/AppStream/Source/Packages/xorg-x11-drv-qxl-0.1.5-11.el8.src.rpm
sha256sum -c <<-EOF || { printf "\n\e[1;91m# The xorg-x11-drv-qxl download failed.\e[0;0m\n\n" ; exit 1 ; }
1c7b841d20cc9da69c1ff9716d4a0231b3d35e3a88145786b3da892246f73e31  xorg-x11-drv-qxl-0.1.5-11.el8.src.rpm
EOF


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

dnf download --quiet --source mesa avahi pcre2 || exit 1
dnf download --quiet --disablerepo=* --repofrompath="fc36,https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/36/Everything/source/tree" --repofrompath="fc36-updates,https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/36/Everything/source/tree" --source phodav spice-gtk || exit 1
dnf download --quiet --disablerepo=* --repofrompath="fc38,https://mirrors.kernel.org/fedora/releases/38/Everything/source/tree" --repofrompath="fc38-updates,https://mirrors.kernel.org/fedora/updates/38/Everything/source/tree" --source libvirt-designer || exit 1
dnf download --quiet --disablerepo=* --repofrompath="rawhide,https://mirrors.kernel.org/fedora/development/rawhide/Everything/source/tree" --source edk2 fcode-utils libcacard lzfse openbios python-pefile python-virt-firmware qemu SLOF spice spice-protocol virglrenderer virt-manager virt-viewer virt-backup passt libvirt libvirt-glib libvirt-dbus libvirt-python osinfo-db-tools libosinfo qt-virt-manager qtermwidget lxqt-build-tools liblxqt libqtxdg chunkfs gtk-vnc remmina xorg-x11-drv-nouveau || exit 1
rpm -i *src.rpm || exit 1

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
patch -p1 <<-PATCH
diff --git a/avahi.spec b/avahi.spec
index fde84ff..463df9d 100644
--- a/avahi.spec
+++ b/avahi.spec
@@ -48,7 +48,7 @@
 
 Name:             avahi
 Version:          0.8
-Release:          12%{?dist}.1
+Release:          12%{?dist}.1024
 Summary:          Local network service discovery
 License:          LGPLv2+
 URL:              http://avahi.org
@@ -122,7 +122,7 @@ BuildRequires:    gcc-c++
 Source0:          https://github.com/lathiat/avahi/archive/%{version}-%{beta}.tar.gz#/%{name}-%{version}-%{beta}.tar.gz
 %else
 Source0:          https://github.com/lathiat/avahi/releases/download/v%{version}/avahi-%{version}.tar.gz
-#Source0:         http://avahi.org/download/avahi-%{version}.tar.gz
+#Source0:         http://avahi.org/download/avahi-% {version}.tar.gz
 %endif
 
 ## upstream patches
@@ -206,7 +206,7 @@ This library contains a GObject wrapper for the Avahi API
 Summary:          Libraries and header files for Avahi GObject development
 Requires:         %{name}-devel%{?_isa} = %{version}-%{release}
 Requires:         %{name}-gobject%{?_isa} = %{version}-%{release}
-#Requires:         %{name}-glib-devel = %{version}-%{release}
+#Requires:         % {name}-glib-devel = % {version}-% {release}
 
 %description gobject-devel
 The avahi-gobject-devel package contains the header files and libraries
@@ -236,7 +236,7 @@ Summary:          Libraries and header files for Avahi UI development
 Requires:         %{name}-devel%{?_isa} = %{version}-%{release}
 Requires:         %{name}-ui%{?_isa} = %{version}-%{release}
 Requires:         %{name}-ui-gtk3%{?_isa} = %{version}-%{release}
-#Requires:         %{name}-glib-devel = %{version}-%{release}
+#Requires:         % {name}-glib-devel = % {version}-% {release}
 
 %description ui-devel
 The avahi-ui-devel package contains the header files and libraries
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
diff --git a/qemu.spec b/qemu.spec
index 0472a1b..5f264f1 100644
--- a/qemu.spec
+++ b/qemu.spec
@@ -6,7 +6,7 @@
 %global libfdt_version 1.6.0
 %global libseccomp_version 2.4.0
 %global libusbx_version 1.0.23
-%global meson_version 0.61.3
+%global meson_version 0.58.2
 %global usbredir_version 0.7.1
 %global ipxe_version 20200823-5.git4bd064de
 
@@ -55,7 +55,7 @@
 %global user_static 1
 %if 0%{?rhel}
 # EPEL/RHEL do not have required -static builddeps
-%global user_static 0
+%global user_static 1
 %endif
 
 %global have_kvm 0
@@ -75,7 +75,7 @@
 %global have_spice 0
 %endif
 %if 0%{?rhel} >= 9
-%global have_spice 0
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
@@ -343,7 +338,7 @@ Summary: QEMU is a FAST! processor emulator
 Name: qemu
 Version: 8.1.0
 Release: %{baserelease}%{?rcrel}%{?dist}
-Epoch: 2
+Epoch: 1024
 License: Apache-2.0 AND BSD-2-Clause AND BSD-3-Clause AND FSFAP AND GPL-1.0-or-later AND GPL-2.0-only AND GPL-2.0-or-later AND GPL-2.0-or-later with GCC-exception-2.0 exception AND LGPL-2.0-only AND LGPL-2.0-or-later AND LGPL-2.1-only and LGPL-2.1-or-later AND MIT and public-domain and CC-BY-3.0
 URL: http://www.qemu.org/
 
@@ -515,16 +510,11 @@ BuildRequires: SDL2_image-devel
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
@@ -755,12 +745,6 @@ Requires: %{name}-common%{?_isa} = %{epoch}:%{version}-%{release}
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
@@ -1514,7 +1498,6 @@ mkdir -p %{static_builddir}
   --disable-linux-user             \\\\\\
   --disable-live-block-migration   \\\\\\
   --disable-lto                    \\\\\\
-  --disable-lzfse                  \\\\\\
   --disable-lzo                    \\\\\\
   --disable-malloc-trim            \\\\\\
   --disable-membarrier             \\\\\\
@@ -1693,7 +1676,6 @@ run_configure \\
   --enable-oss \\
   --enable-pa \\
   --enable-pie \\
-  --enable-pipewire \\
 %if %{have_block_rbd}
   --enable-rbd \\
 %endif
@@ -1726,7 +1708,7 @@ run_configure \\
   --enable-xkbcommon \\
   \\
   \\
-  --audio-drv-list=pipewire,pa,sdl,alsa,%{?jack_drv}oss \\
+  --audio-drv-list=pa,sdl,alsa,%{?jack_drv}oss \\
   --target-list-exclude=moxie-softmmu \\
   --with-default-devices \\
   --enable-auth-pam \\
@@ -1737,6 +1719,7 @@ run_configure \\
   --enable-curses \\
   --enable-dmg \\
   --enable-fuse \\
+  --enable-fuse-lseek \\
   --enable-gio \\
 %if %{have_block_gluster}
   --enable-glusterfs \\
@@ -1751,7 +1734,6 @@ run_configure \\
   --enable-linux-io-uring \\
 %endif
   --enable-linux-user \\
-  --enable-live-block-migration \\
   --enable-multiprocess \\
   --enable-parallels \\
 %if %{have_librdma}
@@ -1760,7 +1742,6 @@ run_configure \\
   --enable-qcow1 \\
   --enable-qed \\
   --enable-qom-cast-debug \\
-  --enable-replication \\
   --enable-sdl \\
 %if %{have_sdl_image}
   --enable-sdl-image \\
@@ -1768,6 +1749,7 @@ run_configure \\
 %if %{have_libcacard}
   --enable-smartcard \\
 %endif
+  --enable-sparse \\
 %if %{have_spice}
   --enable-spice \\
   --enable-spice-protocol \\
@@ -1793,24 +1775,24 @@ run_configure \\
   --enable-zstd
 
 %if %{tools_only}
-%make_build qemu-img
-%make_build qemu-io
-%make_build qemu-nbd
-%make_build storage-daemon/qemu-storage-daemon
-
-%make_build docs/qemu-img.1
-%make_build docs/qemu-nbd.8
-%make_build docs/qemu-storage-daemon.1
-%make_build docs/qemu-storage-daemon-qmp-ref.7
-
-%make_build qga/qemu-ga
-%make_build docs/qemu-ga.8
+%make_build -j14 qemu-img
+%make_build -j14 qemu-io
+%make_build -j14 qemu-nbd
+%make_build -j14 storage-daemon/qemu-storage-daemon
+
+%make_build -j14 docs/qemu-img.1
+%make_build -j14 docs/qemu-nbd.8
+%make_build -j14 docs/qemu-storage-daemon.1
+%make_build -j14 docs/qemu-storage-daemon-qmp-ref.7
+
+%make_build -j14 qga/qemu-ga
+%make_build -j14 docs/qemu-ga.8
 # endif tools_only
 %endif
 
 
 %if !%{tools_only}
-%make_build
+%make_build -j14
 popd
 
 # Fedora build for qemu-user-static
@@ -1824,7 +1806,7 @@ run_configure \\
   --disable-install-blobs \\
   --static
 
-%make_build
+%make_build -j14
 popd  # static
 %endif
 # endif !tools_only
@@ -2032,7 +2014,7 @@ pushd %{qemu_kvm_build}
 echo "Testing %{name}-build"
 # 2022-06: ppc64le random qtest segfaults with no discernable pattern
 %ifnarch %{power64}
-%make_build check
+%make_build -j14 check
 %endif
 
 popd
@@ -2278,9 +2260,9 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 %{_libdir}/%{name}/ui-opengl.so
 %endif
 
-
 %files block-dmg
 %{_libdir}/%{name}/block-dmg-bz2.so
+%{_libdir}/%{name}/block-dmg-lzfse.so
 %if %{have_block_gluster}
 %files block-gluster
 %{_libdir}/%{name}/block-gluster.so
@@ -2300,8 +2282,6 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 %{_libdir}/%{name}/audio-oss.so
 %files audio-pa
 %{_libdir}/%{name}/audio-pa.so
-%files audio-pipewire
-%{_libdir}/%{name}/audio-pipewire.so
 %files audio-sdl
 %{_libdir}/%{name}/audio-sdl.so
 %if %{have_jack}
PATCH


# patch -p1 <<-PATCH 
# diff --git a/qemu.spec b/qemu.spec
# index c55e6c4..a72ccab 100644
# --- a/qemu.spec
# +++ b/qemu.spec
# @@ -6,7 +6,7 @@
#  %global libfdt_version 1.6.0
#  %global libseccomp_version 2.4.0
#  %global libusbx_version 1.0.23
# -%global meson_version 0.61.3
# +%global meson_version 0.58.2
#  %global usbredir_version 0.7.1
#  %global ipxe_version 20200823-5.git4bd064de
 
# @@ -55,7 +55,7 @@
#  %global user_static 1
#  %if 0%{?rhel}
#  # EPEL/RHEL do not have required -static builddeps
# -%global user_static 0
# +%global user_static 1
#  %endif
 
#  %global have_kvm 0
# @@ -75,7 +75,7 @@
#  %global have_spice 0
#  %endif
#  %if 0%{?rhel} >= 9
# -%global have_spice 0
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
 
# @@ -114,12 +114,9 @@
#  %global have_dbus_display 0
#  %endif
 
# -%global have_libblkio 0
# -%if 0%{?fedora} >= 37
#  %global have_libblkio 1
# -%endif
 
# -%global have_sdl_image %{defined fedora}
# +%global have_sdl_image %{defined rhel}
#  %global have_fdt 1
#  %global have_opengl 1
#  %global have_usbredir 1
# @@ -156,7 +153,7 @@
 
#  %define have_libcacard 1
#  %if 0%{?rhel} >= 9
# -%define have_libcacard 0
# +%define have_libcacard 1
#  %endif
 
#  # LTO still has issues with qemu on armv7hl and aarch64
# @@ -327,7 +324,7 @@ Summary: QEMU is a FAST! processor emulator
#  Name: qemu
#  Version: 7.2.0
#  Release: %{baserelease}%{?rcrel}%{?dist}
# -Epoch: 2
# +Epoch: 1024
#  License: GPLv2 and BSD and MIT and CC-BY
#  URL: http://www.qemu.org/
 
# @@ -511,12 +508,8 @@ BuildRequires: SDL2_image-devel
 
#  %if %{user_static}
#  BuildRequires: glibc-static glib2-static zlib-static
# -%if 0%{?fedora} >= 37
# -BuildRequires: pcre2-static
# -%else
#  BuildRequires: pcre-static
#  %endif
# -%endif
 
 
#  # Requires for the Fedora 'qemu' metapackage
# @@ -1501,7 +1494,6 @@ mkdir -p %{static_builddir}
#    --disable-linux-user             \\\\\\
#    --disable-live-block-migration   \\\\\\
#    --disable-lto                    \\\\\\
# -  --disable-lzfse                  \\\\\\
#    --disable-lzo                    \\\\\\
#    --disable-malloc-trim            \\\\\\
#    --disable-membarrier             \\\\\\
# @@ -1596,7 +1588,7 @@ run_configure() {
#          --with-pkgversion="%{name}-%{version}-%{release}" \\
#          --with-suffix="%{name}" \\
#          --firmwarepath="%firmwaredirs" \\
# -        --meson="%{__meson}" \\
# +        --meson=internal \\
#          --enable-trace-backends=dtrace \\
#          --with-coroutine=ucontext \\
#          --with-git=git \\
# @@ -1721,6 +1713,7 @@ run_configure \\
#    --enable-curses \\
#    --enable-dmg \\
#    --enable-fuse \\
# +  --enable-fuse-lseek \\
#    --enable-gio \\
#  %if %{have_block_gluster}
#    --enable-glusterfs \\
# @@ -1735,7 +1728,6 @@ run_configure \\
#    --enable-linux-io-uring \\
#  %endif
#    --enable-linux-user \\
# -  --enable-live-block-migration \\
#    --enable-multiprocess \\
#    --enable-vnc-jpeg \\
#    --enable-parallels \\
# @@ -1745,7 +1737,6 @@ run_configure \\
#    --enable-qcow1 \\
#    --enable-qed \\
#    --enable-qom-cast-debug \\
# -  --enable-replication \\
#    --enable-sdl \\
#  %if %{have_sdl_image}
#    --enable-sdl-image \\
# @@ -1753,6 +1744,7 @@ run_configure \\
#  %if %{have_libcacard}
#    --enable-smartcard \\
#  %endif
# +  --enable-sparse \\
#  %if %{have_spice}
#    --enable-spice \\
#    --enable-spice-protocol \\
# @@ -2267,9 +2260,9 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
#  %{_libdir}/%{name}/ui-opengl.so
#  %endif
 
# -
#  %files block-dmg
#  %{_libdir}/%{name}/block-dmg-bz2.so
# +%{_libdir}/%{name}/block-dmg-lzfse.so
#  %if %{have_block_gluster}
#  %files block-gluster
#  %{_libdir}/%{name}/block-gluster.so
# PATCH

# Some changes are just easier with sed.
sed -i 's/defined rhel/defined nullified/g' edk2.spec
sed -i 's/defined fedora/defined rhel/g' edk2.spec
sed -i "s/^Version:\([\t ]*\).*/Version:\1$(date +%Y%m%d)/g" passt.spec 

# Increase the QEMU build jobs.
JOBS="$(($(lscpu -e=core | grep -v CORE | sort | uniq | wc -l)+2))"
sed -i "s/%make_build/%make_build -j$JOBS/g" qemu.spec
unset JOBS

# Use a release string of 1024 so the virt-manager rebuild will be seen as an upgrade.
sed -E -i 's/^Release\: .\%\{\?dist\}/Release: 1024\%\{\?dist\}/g' virt-manager.spec

# Build the spec files.
rpmbuild -ba --rebuild --target=$(uname -m) mesa.spec 2>&1 | tee mesa.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " mesa.spec ) 2>/dev/null ) || \
{ printf "\n\e[1;91m# The mesa rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The mesa rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --target=$(uname -m) avahi.spec 2>&1 | tee avahi.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " avahi.spec ) || \
{ printf "\n\e[1;91m# The avahi rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The avahi rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --target=$(uname -m) pcre2.spec 2>&1 | tee pcre2.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " pcre2.spec ) || \
{ printf "\n\e[1;91m# The pcre2 rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The pcre2s rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --target=$(uname -m) xorg-x11-drv-nouveau.spec 2>&1 | tee xorg-x11-drv-nouveau.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " xorg-x11-drv-nouveau.spec ) || \
{ printf "\n\e[1;91m# The xorg-x11-drv-nouveau rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The xorg-x11-drv-nouveau rpmbuild finished.\e[0;0m\n"

# The spice/qemu/libvirt packages.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) lzfse.spec 2>&1 | tee lzfse.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " lzfse.spec) || \
{ printf "\n\e[1;91m# The lzfse rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The lzfse rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) virglrenderer.spec 2>&1 | tee virglrenderer.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " virglrenderer.spec) || \
{ printf "\n\e[1;91m# The virglrenderer rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The virglrenderer rpmbuild finished.\e[0;0m\n"

# If the tpm2-abrmd packages have been installed, the libcacard unit tests will fail.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libcacard.spec 2>&1 | tee libcacard.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libcacard.spec) || \
{ printf "\n\e[1;91m# The libcacard rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libcacard rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) fcode-utils.spec 2>&1 | tee fcode-utils.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " fcode-utils.spec) || \
{ printf "\n\e[1;91m# The fcode-utils rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The fcode-utils rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) openbios.spec 2>&1 | tee openbios.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " openbios.spec) || \
{ printf "\n\e[1;91m# The openbios rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The openbios rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) python-pefile.spec 2>&1 | tee python-pefile.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q  $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " python-pefile.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The python-pefile rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The python-pefile rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) python-virt-firmware.spec 2>&1 | tee python-virt-firmware.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(ls -q  $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " python-virt-firmware.spec ) 2>/dev/null | grep -v "python3-virt-firmware-tests") || \
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
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " SLOF.spec) || \
{ printf "\n\e[1;91m# The SLOF rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The SLOF rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) spice-protocol.spec 2>&1 | tee spice-protocol.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " spice-protocol.spec) || \
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

# The QXL driver requires the spice-protocol and the spice-server packages.
rpmbuild -ba --rebuild --target=$(uname -m) xorg-x11-drv-qxl.spec 2>&1 | tee xorg-x11-drv-qxl.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " xorg-x11-drv-qxl.spec ) || \
{ printf "\n\e[1;91m# The xorg-x11-drv-qxl rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\n\e[1;92m# The xorg-x11-drv-qxl rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) passt.spec 2>&1 | tee passt.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " passt.spec ) || \
{ printf "\n\e[1;91m# The passt rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\n\e[1;92m# The passt rpmbuild finished.\e[0;0m\n"


# QEMU will look for the gvnc-1.0 package config. We include the upgrade flag so the upstream gtk-vnc2 package gets removed.
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

# If the tpm packages have been installed, the qemu unit tests will fail. Use the tpm2 packages instead.

# Summary of qemu failures with the gtk-vnc2 devel package installed.
# 233/714 qemu:qtest+qtest-aarch64 / qtest-aarch64/vnc-display-test                 ERROR          52.42s   killed by signal 6 SIGABRT
# 273/714 qemu:qtest+qtest-arm / qtest-arm/vnc-display-test                         ERROR          52.46s   killed by signal 6 SIGABRT
# 281/714 qemu:qtest+qtest-avr / qtest-avr/vnc-display-test                         ERROR          53.11s   killed by signal 6 SIGABRT
# 529/714 qemu:qtest+qtest-rx / qtest-rx/vnc-display-test                           ERROR          50.26s   killed by signal 6 SIGABRT
# 594/714 qemu:qtest+qtest-tricore / qtest-tricore/vnc-display-test                 ERROR          51.44s   killed by signal 6 SIGABRT

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) qemu.spec 2>&1 | tee qemu.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " qemu.spec ) || \
{ printf "\n\e[1;91m# The qemu rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The qemu rpmbuild finished.\e[0;0m\n"


# # QEMU will look for the gvnc-1.0 package config. We include the upgrade flag so the upstream gtk-vnc2 package gets removed.
# rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) gtk-vnc.spec 2>&1 | tee gtk-vnc.log > /dev/null && \
# rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " gtk-vnc.spec ) 2>/dev/null) || \
# { printf "\n\e[1;91m# The gtk-vnc rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
# printf "\e[1;92m# The gtk-vnc rpmbuild finished.\e[0;0m\n"




rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libosinfo.spec 2>&1 | tee libosinfo.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libosinfo.spec ) || \
{ printf "\n\e[1;91m# The libosinfo rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libosinfo rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) osinfo-db-tools.spec 2>&1 | tee osinfo-db-tools.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " osinfo-db-tools.spec ) || \
{ printf "\n\e[1;91m# The osinfo-db-tools rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The osinfo-db-tools rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-glib.spec 2>&1 | tee libvirt-glib.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-glib.spec ) || \
{ printf "\n\e[1;91m# The libvirt-glib rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt-glib rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-dbus.spec 2>&1 | tee libvirt-dbus.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-dbus.spec ) || \
{ printf "\n\e[1;91m# The libvirt-dbus rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt-dbus rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" -D "with_modular_daemons 1" --target=$(uname -m) libvirt.spec 2>&1 | tee libvirt.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --builtrpms --undefine="dist" -D "dist .btrh9"  -D "with_modular_daemons 1" --target=$(uname -m) --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt.spec | sed 's/libvirt-admin/libvirt-daemon/g' ) || \
{ printf "\n\e[1;91m# The libvirt rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-designer.spec 2>&1 | tee libvirt-designer.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-designer.spec ) || \
{ printf "\n\e[1;91m# The libvirt-designer rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt-designer rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-python.spec 2>&1 | tee libvirt-python.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles  $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-python.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The libvirt-python rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt-python rpmbuild finished.\e[0;0m\n"

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
rpm -i -U --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " virt-manager.spec ) 2>/dev/null) || \
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




# Download the dependencies needed for installation, which aren't available from the official, 
# and/or, EPEL repos. They will be added to the collection of binary packages that were just 
# built.
dnf --quiet --enablerepo=remi --enablerepo=remi-debuginfo --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download SDL2_image SDL2_image-debuginfo SDL2_image-devel SDL2_image-debugsource
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download pcsc-lite-devel pcsc-lite-libs pcsc-lite-libs-debuginfo pcsc-lite-devel-debuginfo
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download mesa-libgbm mesa-libgbm-devel mesa-libgbm-debuginfo
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download usbredir usbredir-devel usbredir-debuginfo usbredir-debugsource
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download opus opus-devel opus-debuginfo opus-debugsource
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download gobject-introspection gobject-introspection-devel gobject-introspection-debuginfo gobject-introspection-debugsource
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download libogg libogg-devel libogg-debuginfo libogg-debugsource
dnf --quiet --enablerepo=crb --enablerepo=crb-debuginfo --arch=noarch --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/noarch/ download python3-markdown

# Consolidate the RPMs.
mkdir $HOME/RPMS/
find $HOME/rpmbuild/RPMS/noarch/*rpm $HOME/rpmbuild/RPMS/x86_64/*rpm $HOME/rpmbuild/SRPMS/*btrh*rpm > $HOME/rpm.outputs.txt
mv $HOME/rpmbuild/RPMS/noarch/*rpm $HOME/rpmbuild/RPMS/x86_64/*rpm $HOME/rpmbuild/SRPMS/*btrh*rpm $HOME/RPMS/

cd $HOME/RPMS/
curl -LOs https://archive.org/download/capstone-el9/capstone-4.0.2-9.el9.x86_64.rpm 
curl -LOs https://archive.org/download/capstone-el9/capstone-devel-4.0.2-9.el9.x86_64.rpm
curl -LOs https://archive.org/download/capstone-el9/python3-capstone-4.0.2-9.el9.x86_64.rpm
curl -LOs https://archive.org/download/libblkio-eln125/libblkio-1.2.2-2.eln125.x86_64.rpm
curl -LOs https://archive.org/download/libblkio-eln125/libblkio-devel-1.2.2-2.eln125.x86_64.rpm

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

if [ ! \$(sudo dnf repolist --quiet baseos 2>&1 | grep -Eo "^baseos") ]; then  
 printf "\nThe baseos repo is required but doesn't appear to be enabled.\n\n"
 exit 1
fi

if [ ! \$(sudo dnf repolist --quiet appstream 2>&1 | grep -Eo "^appstream") ]; then  
 printf "\nThe appstream repo is required but doesn't appear to be enabled.\n\n"
 exit 1
fi
if [ ! \$(sudo dnf repolist --quiet epel 2>&1 | grep -Eo "^epel") ]; then  
 printf "\nThe epel repo is required but doesn't appear to be installed (or enabled).\n\n"
 exit 1
fi

# To generate a current/updated list of RPM files for installation, run the following command.
export INSTALLPKGS=\$(echo \`ls qemu*rpm spice*rpm opus*rpm usbredir*rpm openbios*rpm capstone*rpm libblkio*rpm lzfse*rpm virglrenderer*rpm libcacard*rpm edk2*rpm SLOF*rpm SDL2*rpm libogg-devel*rpm pcsc-lite-devel*rpm mesa-libgbm-devel*rpm usbredir-devel*rpm opus-devel*rpm gobject-introspection-devel*rpm python3-markdown*rpm virt-manager*rpm virt-viewer*rpm virt-install*rpm virt-backup*rpm passt*rpm libphodav*rpm gvnc*rpm gtk-vnc*rpm chunkfs*rpm osinfo*rpm libosinfo*rpm libvirt*rpm python3-libvirt*rpm | grep -Ev 'qemu-guest-agent|qemu-tests|debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the remmina packages.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls remmina*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the mesa packages.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls mesa*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the avahi packages.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls avahi*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the xorg driver packages.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls xorg-x11*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the pcre2-static package.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls pcre2-static-*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

# Add the qt version of virt manager.
## export INSTALLPKGS=\$(echo \$INSTALLPKGS \`ls qtermwidget*rpm liblxqt*rpm libqtxdg*rpm lxqt-build-tools*rpm qt-remote-viewer*rpm qt-virt-manager*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

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
export REMOVEPKGS=\$(echo \`echo 'edk2-debugsource edk2-tools-debuginfo virtiofsd virtiofsd-debuginfo virtiofsd-debugsource virglrenderer-debuginfo virglrenderer-debugsource virglrenderer-test-server-debuginfo virt-install virt-manager virt-manager-common virt-viewer virt-viewer-debuginfo virt-viewer-debugsource virt-backup gtk-vnc2 gtk-vnc2-devel gtk-vnc-debuginfo gtk-vnc-debugsource gvnc gvnc-devel gvncpulse gvncpulse-devel gvnc-tools libvirt-client libvirt-client-debuginfo libvirt-daemon libvirt-daemon-config-network libvirt-daemon-debuginfo libvirt-daemon-driver-interface libvirt-daemon-driver-interface-debuginfo libvirt-daemon-driver-network libvirt-daemon-driver-network-debuginfo libvirt-daemon-driver-nodedev libvirt-daemon-driver-nodedev-debuginfo libvirt-daemon-driver-nwfilter libvirt-daemon-driver-nwfilter-debuginfo libvirt-daemon-driver-qemu libvirt-daemon-driver-qemu-debuginfo libvirt-daemon-driver-secret libvirt-daemon-driver-secret-debuginfo libvirt-daemon-driver-storage libvirt-daemon-driver-storage-core libvirt-daemon-driver-storage-core-debuginfo libvirt-daemon-driver-storage-disk libvirt-daemon-driver-storage-disk-debuginfo libvirt-daemon-driver-storage-iscsi libvirt-daemon-driver-storage-iscsi-debuginfo libvirt-daemon-driver-storage-logical libvirt-daemon-driver-storage-logical-debuginfo libvirt-daemon-driver-storage-mpath libvirt-daemon-driver-storage-mpath-debuginfo libvirt-daemon-driver-storage-rbd libvirt-daemon-driver-storage-rbd-debuginfo libvirt-daemon-driver-storage-scsi libvirt-daemon-driver-storage-scsi-debuginfo libvirt-daemon-kvm libvirt-debuginfo libvirt-devel libvirt-glib libvirt-libs libvirt-libs-debuginfo libvirt-lock-sanlock-debuginfo libvirt-nss-debuginfo libvirt-wireshark-debuginfo python3-libvirt qemu-ga-win qemu-guest-agent qemu-guest-agent-debuginfo qemu-img qemu-img-debuginfo qemu-kvm qemu-kvm-audio-pa qemu-kvm-audio-pa-debuginfo qemu-kvm-block-curl qemu-kvm-block-curl-debuginfo qemu-kvm-block-rbd qemu-kvm-block-rbd-debuginfo qemu-kvm-block-ssh-debuginfo qemu-kvm-common qemu-kvm-common-debuginfo qemu-kvm-core qemu-kvm-core-debuginfo qemu-kvm-debuginfo qemu-kvm-debugsource qemu-kvm-device-display-virtio-gpu qemu-kvm-device-display-virtio-gpu-debuginfo qemu-kvm-device-display-virtio-gpu-gl qemu-kvm-device-display-virtio-gpu-gl-debuginfo qemu-kvm-device-display-virtio-gpu-pci qemu-kvm-device-display-virtio-gpu-pci-debuginfo qemu-kvm-device-display-virtio-gpu-pci-gl qemu-kvm-device-display-virtio-gpu-pci-gl-debuginfo qemu-kvm-device-display-virtio-vga qemu-kvm-device-display-virtio-vga-debuginfo qemu-kvm-device-display-virtio-vga-gl qemu-kvm-device-display-virtio-vga-gl-debuginfo qemu-kvm-device-usb-host qemu-kvm-device-usb-host-debuginfo qemu-kvm-device-usb-redirect qemu-kvm-device-usb-redirect-debuginfo qemu-kvm-docs qemu-kvm-tests-debuginfo qemu-kvm-tools qemu-kvm-tools-debuginfo qemu-kvm-ui-egl-headless qemu-kvm-ui-egl-headless-debuginfo qemu-kvm-ui-opengl qemu-kvm-ui-opengl-debuginfo qemu-pr-helper qemu-pr-helper-debuginfo virtiofsd libosinfo libosinfo-debuginfo libosinfo-debugsource python3-libvirt python3-libvirt-debuginfo' | tr ' ' '\\n' | while read PKG ; do { rpm --quiet -q \$PKG && rpm -q \$PKG | grep -v '\\.btrh9\\.' ; } ; done\`)

# Ensure previous attempts/transactions don't break the install attempt.
dnf clean all --enablerepo=* &>/dev/null

# The adobe-source-code-pro-fonts package might be required.
# On the target system, run the following command to install the new version of QEMU.
if [ "\$REMOVEPKGS" ]; then
printf "%s\\n" "install \$INSTALLPKGS" "remove \$REMOVEPKGS" "run" "clean all" "reinstall \$INSTALLPKGS" "exit" | dnf shell --assumeyes
else 
printf "%s\\n" "install \$INSTALLPKGS" "run" "clean all" "reinstall \$INSTALLPKGS" "exit" | dnf shell --assumeyes
fi

[ ! -f /usr/bin/qemu-kvm ] && [ -f /usr/bin/qemu-system-x86_64 ] && sudo ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-kvm
[ ! -f /usr/libexec/qemu-kvm ] && [ -f /usr/bin/qemu-kvm ] && sudo ln -s /usr/bin/qemu-kvm /usr/libexec/qemu-kvm

EOF

cp $HOME/BUILD.sh $HOME/RPMS/BUILD.sh
chmod 744 $HOME/RPMS/INSTALL.sh
chmod 744 $HOME/RPMS/BUILD.sh

# This will remove QEMU and its dependencies and reinstall the upstream version 
# of QEMU, so we can simulate an upgrade.
cd $HOME
dnf --quiet --assumeyes remove edk2* lzfse* mesa* openbios* pcsc* qemu* SDL2* SLOF* spice* virglrenderer* virtiofsd* $(rpm -qa | grep btrh)
dnf --quiet --enablerepo=* clean all
dnf --quiet --assumeyes install qemu* libvirt* virt* virtiofsd
dnf --quiet --assumeyes config-manager --disable "remi*" "elrepo*" "rpmfusion*" "crb*"

# This quiets DNF by default, which allows INSTALL.sh to run silently on the virtual 
# machine used to build the RPMS. When INSTALL.sh elsewhere, it will use the default
# verbosity setting, which usually means it will print a transaction summary.
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

source /etc/os-release
[ "$REDHAT_SUPPORT_PRODUCT_VERSION" == "9.2" ] && printf "\n\e[1;91m# It appears RHEL v9.2 has shipped. The capstone libs can probably be removed.\e[0;0m"

printf "\n\nAll done.\n\n"
