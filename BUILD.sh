#!/bin/bash -eu

# Name: BUILD.sh
# Author: Ladar Levison

# Description: This script installs all of the dependencies needed to 
#   to rebuild the QEMU/Virt/Spice packages for RHEL. It presumes the
#   system is a fresh, near minimal install. And freely makes changes
#   and/or installs packages that may not be needed. It should not be
#   run on a production system, but rather used inside a disposable
#   virtual machine, or container. 

# License: This scirpt is hereby placed in the public domain, AND IS 
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
# [ "$(basename $PWD)" == "qemu.builder" ] && { vagrant destroy -f && cd ../ && rm -rf qemu.builder/ ; } ; \
# mkdir qemu.builder && cd qemu.builder && vagrant init --minimal generic/alma9 && \
# sed -i "s/^end$/  config.vm.hostname = \"qemu.builder\"\n  config.ssh.forward_x11 = true\n  config.ssh.forward_agent = true\n  config.vm.provider :libvirt do \|v, override\|\n    v.cpus = 6\n    v.machine_type = 'q35'\n    v.nested = true\n    v.cpu_mode = 'host-passthrough'\n    v.memory = 8192\n    v.video_vram = 256\n  end\nend/g" Vagrantfile && \
# vagrant destroy -f && vagrant up --provider=libvirt && vagrant ssh-config > config && \
# vagrant upload /home/ladar/Documents/Configuration/workstation/alma-9-build-qemu.sh BUILD.sh && \
# vagrant ssh -c 'sudo mv BUILD.sh /root/' && \
# vagrant ssh -c "sudo su -l -c 'time bash -eu /root/BUILD.sh'" && \
# printf "get -r RPMS QEMU-v$(date +%Y%m%d)\n"| sftp -F config default

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

sudo dnf update --quiet --assumeyes && \
sudo dnf --enablerepo=extras --quiet --assumeyes install epel-release && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9 && \
sudo dnf --enablerepo=extras --quiet --assumeyes install elrepo-release && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org && \
sudo dnf install --quiet --assumeyes https://download1.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E "%{?fedora}%{?rhel}").noarch.rpm && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-el-9 && \
sudo dnf install --quiet --assumeyes https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E "%{?fedora}%{?rhel}").noarch.rpm && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-el-9 && \
sudo dnf install --quiet --assumeyes https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E "%{?rhel}").rpm && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi.el$(rpm -E '%{?rhel}')

sudo sed -i -e "s/^[# ]*baseurl/baseurl/g" /etc/yum.repos.d/almalinux-*.repo
sudo sed -i -e "s/^[# ]*mirrorlist/# mirrorlist/g" /etc/yum.repos.d/almalinux-*.repo

sudo sed -i 's/&protocol\=https//g' /etc/yum.repos.d/epel.repo
sudo sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/epel.repo
sudo sed -i 's/&protocol\=https//g' /etc/yum.repos.d/epel-testing.repo
sudo sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/epel-testing.repo

sudo sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/elrepo.repo 
sudo sed -i -e "s/^[# ]*mirrorlist/# mirrorlist/g" /etc/yum.repos.d/elrepo.repo 
sudo sed -i '/mirrors.coreix.net/d' /etc/yum.repos.d/elrepo.repo

sudo sed -i 's/baseurl\=http:/baseurl\=https:/g' /etc/yum.repos.d/rpmfusion-free-updates.repo
sudo sed -i 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/rpmfusion-free-updates.repo
sudo sed -i 's/&protocol\=https//g' /etc/yum.repos.d/rpmfusion-free-updates.repo
sudo sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/rpmfusion-free-updates.repo
sudo sed -i 's/baseurl\=http:/baseurl\=https:/g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
sudo sed -i 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
sudo sed -i 's/&protocol\=https//g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
sudo sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
sudo sed -i 's/baseurl\=http:/baseurl\=https:/g' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sudo sed -i 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sudo sed -i 's/&protocol\=https//g' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sudo sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sudo sed -i 's/baseurl\=http:/baseurl\=https:/g' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
sudo sed -i 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
sudo sed -i 's/&protocol\=https//g' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
sudo sed -i 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo

sudo sed -i 's/cdn.remirepo.net/rpms.remirepo.net/g' /etc/yum.repos.d/remi.repo
sudo sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/remi.repo 
sudo sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/remi-safe.repo 
sudo sed -i 's/cdn.remirepo.net/rpms.remirepo.net/g' /etc/yum.repos.d/remi-safe.repo
sudo sed -i 's/cdn.remirepo.net/rpms.remirepo.net/g' /etc/yum.repos.d/remi-modular.repo
sudo sed -i 's/http:\/\//https:\/\//g' /etc/yum.repos.d/remi-modular.repo 

# As a final step we clean the cache, and reload it so the new GPG keys get approved.
sudo dnf --enablerepo=* clean all && sudo dnf --enablerepo=* --quiet --assumeyes makecache && \
sudo dnf --quiet --assumeyes update && \
sudo dnf --quiet --assumeyes --with-optional \
--enablerepo=baseos --enablerepo=appstream --enablerepo=epel --enablerepo=extras --enablerepo=plus \
--enablerepo=crb --enablerepo=remi --enablerepo=remi-safe --enablerepo=remi-modular --enablerepo=elrepo \
--enablerepo=rpmfusion-free-updates --enablerepo=rpmfusion-nonfree-updates group install \
"Development Tools" "Additional Development" "Platform Development" "RPM Development Tools" "Debugging Tools" \
"Desktop Debugging and Performance Tools" && \
sudo dnf --quiet --assumeyes --allowerasing \
--enablerepo=baseos --enablerepo=appstream --enablerepo=epel --enablerepo=extras --enablerepo=plus \
--enablerepo=crb --enablerepo=remi --enablerepo=remi-safe --enablerepo=remi-modular --enablerepo=elrepo \
--enablerepo=rpmfusion-free-updates --enablerepo=rpmfusion-nonfree-updates install \
 acpica-tools alsa-lib-devel asciidoc audit-libs-devel autoconf automake bash bc binutils binutils-devel \
 bison brlapi-devel byacc bzip2-devel cmake ctags cyrus-sasl-devel daxctl-devel dbus-daemon \
 dbus-devel dbus-glib-devel dbus-libs dbus-x11 dbusmenu-qt5-devel device-mapper-multipath-devel diffstat \
 diffutils dosfstools dwarves epel-rpm-macros elfutils elfutils-devel elfutils-libelf-devel expect \
 findutils flex fuse-devel fuse-encfs fuse-overlayfs fuse-sshfs fuse3 fuse3-devel gawk gcc \
 gcc-aarch64-linux-gnu gcc-arm-linux-gnu gcc-c++ gcc-powerpc64-linux-gnu gcc-sparc64-linux-gnu \
 gcc-x86_64-linux-gnu gdb gettext git git-core glib2-devel glib2-static glibc-devel glibc-static gnupg2 \
 gnutls-devel gnutls-utils gstreamer1-devel gstreamer1-plugins-bad-free-devel \
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
 python3-sphinx python3-sphinx_rtd_theme python3-tomli rdma-core rdma-core-devel redhat-rpm-config rpm-build rpm-sign \
 rpmconf rpmdevtools rpmlint rpmrebuild rsync SDL2-devel SDL2_image-devel seabios seabios-bin seavgabios-bin \
 sgabios-bin snappy-devel softhsm source-highlight sparse sssd-dbus strace systemd-devel systemtap \
 systemtap-sdt-devel tar tcsh texinfo usbguard-dbus usbredir-devel valgrind valgrind-devel vte291-devel \
 x264-devel x265-devel xauth xdg-dbus-proxy xmlto xorg-x11-util-macros xorriso xz zlib-devel zlib-static \
 gobject-introspection-devel gtk-doc usbutils vala wayland-protocols-devel samba-winbind-clients \
 libnghttp2-devel latexmk python3-sphinx-latex redhat-display-fonts redhat-text-fonts fonts-rpm-macros \
 pyproject-rpm-macros python3-wheel virt-manager libvirt-devel libvirt-client || \
exit 1

# Packages needed to enable X11 forwarding support.
sudo dnf --quiet --assumeyes --enablerepo=epel --enablerepo=extras --enablerepo=plus --enablerepo=crb \
--exclude=minizip1.2 --exclude=minizip1.2-devel install \
 dbus-x11 xorg-x11-xauth xorg-x11-server-common xorg-x11-server-Xorg xorg-x11-server-Xwayland \
 mlocate cronie cronie-anacron || \
exit 1


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
sudo sed -i 's/.*X11Forwarding.*/X11Forwarding yes/g' /etc/ssh/sshd_config
sudo sed -i 's/.*X11UseLocalhost.*/X11UseLocalhost no/g' /etc/ssh/sshd_config
sudo sed -i 's/.*X11DisplayOffset.*/X11DisplayOffset 10/g' /etc/ssh/sshd_config
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

dnf download --quiet --disablerepo=* --repofrompath="fc36,https://mirrors.kernel.org/fedora/releases/36/Everything/source/tree/" --source spice-gtk || exit 1
# dnf download --quiet --disablerepo=* --repofrompath="fc37,https://mirrors.kernel.org/fedora/releases/37/Everything/source/tree/" --source python-smartypants || exit 1
dnf download --quiet --disablerepo=* --repofrompath="rawhide,https://mirrors.kernel.org/fedora/development/rawhide/Everything/source/tree/" --source edk2 fcode-utils gi-docgen libcacard lzfse openbios python-pefile python-smartypants python-virt-firmware qemu SLOF spice spice-protocol virglrenderer virt-manager || exit 1
rpm -i *src.rpm || exit 1

# Patch the source/spec files.
cd ~/rpmbuild/SPECS/

git config --global init.defaultBranch master && git config --global user.name default && git config --global user.email default || exit 1
git init && git add *.spec && git commit -m "Default spec files." || exit 1

patch -p1 <<-EOF 
diff --git a/SLOF.spec b/SLOF.spec
index 638fd88..2341a15 100644
--- a/SLOF.spec
+++ b/SLOF.spec
@@ -6,13 +6,8 @@
 # Disable debuginfo because it is of no use to us.
 %global debug_package %{nil}
 
-%if 0%{?fedora:1}
 %define cross 1
 %define targetdir qemu
-%else
-%define targetdir qemu-kvm
-%endif
-
 %global gittag qemu-slof-%{gittagdate}
 
 Name:           SLOF
EOF

# # # Patch the EDK2 spec file.
# patch -p1 <<-EOF
# diff --git a/edk2.spec b/edk2.spec
# index bd358d1..f8376bd 100644
# --- a/edk2.spec
# +++ b/edk2.spec
# @@ -14,25 +14,12 @@ ExclusiveArch: x86_64 aarch64
#  %define TOOLCHAIN      GCC5
#  %define OPENSSL_VER    1.1.1k
 
# -%if %{defined rhel}
# -%define build_ovmf 0
# -%define build_aarch64 0
# -%ifarch x86_64
# -  %define build_ovmf 1
# -%endif
# -%ifarch aarch64
# -  %define build_aarch64 1
# -%endif
# -%else
#  %define build_ovmf 1
#  %define build_aarch64 1
# -%endif
# -
#  %global softfloat_version 20180726-gitb64af41
# -%define cross %{defined fedora}
# +%define cross 1
#  %define disable_werror %{defined fedora}
 
# -
#  Name:       edk2
#  Version:    %{GITDATE}git%{GITCOMMIT}
#  Release:    5%{?dist}
# @@ -187,7 +174,6 @@ environment for the UEFI and PI specifications. This package contains sample
#  64-bit UEFI firmware builds for QEMU and KVM.
 
 
# -%if %{defined fedora}
#  %package ovmf-ia32
#  Summary:        Open Virtual Machine Firmware
#  License:        BSD-2-Clause-Patent and OpenSSL
# @@ -223,8 +209,6 @@ BuildArch:      noarch
#  This package provides tools that are needed to build EFI executables
#  and ROMs using the GNU tools.  You do not need to install this package;
#  you probably want to install edk2-tools only.
# -# endif fedora
# -%endif
 
 
 
# @@ -543,7 +527,6 @@ done
#  %doc BaseTools/UserManuals/*.rtf
 
 
# -%if %{defined fedora}
#  %if %{build_ovmf}
#  %files ovmf-ia32
#  %common_files
# @@ -591,8 +574,6 @@ done
#  %dir %{_datadir}/%{name}
#  %{_datadir}/%{name}/Python
 
# -# endif fedora
# -%endif
 
 
#  %changelog
# EOF

# Patch the QEMU spec file.
patch -p1 <<-EOF
diff --git a/qemu.spec b/qemu.spec
index 38b7b7f..05ad56f 100644
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
 
@@ -114,7 +114,7 @@
 %global have_dbus_display 0
 %endif
 
-%global have_sdl_image %{defined fedora}
+%global have_sdl_image %{defined rhel}
 %global have_fdt 1
 %global have_opengl 1
 %global have_usbredir 1
@@ -151,7 +151,7 @@
 
 %define have_libcacard 1
 %if 0%{?rhel} >= 9
-%define have_libcacard 0
+%define have_libcacard 1
 %endif
 
 # LTO still has issues with qemu on armv7hl and aarch64
@@ -316,7 +316,7 @@ Summary: QEMU is a FAST! processor emulator
 Name: qemu
 Version: 7.1.0
 Release: %{baserelease}%{?rcrel}%{?dist}
-Epoch: 2
+Epoch: 1024
 License: GPLv2 and BSD and MIT and CC-BY
 URL: http://www.qemu.org/
 
@@ -1462,7 +1462,6 @@ mkdir -p %{static_builddir}
   --disable-linux-user             \\\\\\
   --disable-live-block-migration   \\\\\\
   --disable-lto                    \\\\\\
-  --disable-lzfse                  \\\\\\
   --disable-lzo                    \\\\\\
   --disable-malloc-trim            \\\\\\
   --disable-membarrier             \\\\\\
@@ -1556,7 +1555,7 @@ run_configure() {
         --with-pkgversion="%{name}-%{version}-%{release}" \\
         --with-suffix="%{name}" \\
         --firmwarepath="%firmwaredirs" \\
-        --meson="%{__meson}" \\
+        --meson=internal \\
         --enable-trace-backends=dtrace \\
         --with-coroutine=ucontext \\
         --with-git=git \\
@@ -1678,6 +1677,7 @@ run_configure \\
   --enable-curses \\
   --enable-dmg \\
   --enable-fuse \\
+  --enable-fuse-lseek \\
   --enable-gio \\
 %if %{have_block_gluster}
   --enable-glusterfs \\
@@ -1692,7 +1692,6 @@ run_configure \\
   --enable-linux-io-uring \\
 %endif
   --enable-linux-user \\
-  --enable-live-block-migration \\
   --enable-multiprocess \\
   --enable-vnc-jpeg \\
   --enable-parallels \\
@@ -1702,7 +1701,6 @@ run_configure \\
   --enable-qcow1 \\
   --enable-qed \\
   --enable-qom-cast-debug \\
-  --enable-replication \\
   --enable-sdl \\
 %if %{have_sdl_image}
   --enable-sdl-image \\
@@ -2218,9 +2216,9 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 %{_libdir}/%{name}/ui-opengl.so
 %endif
 
-
 %files block-dmg
 %{_libdir}/%{name}/block-dmg-bz2.so
+%{_libdir}/%{name}/block-dmg-lzfse.so
 %if %{have_block_gluster}
 %files block-gluster
 %{_libdir}/%{name}/block-gluster.so
EOF

patch -p1 <<-EOF
diff --git a/spice-gtk.spec b/spice-gtk.spec
index 9bd79d1..29f332e 100644
--- a/spice-gtk.spec
+++ b/spice-gtk.spec
@@ -31,7 +31,9 @@ BuildRequires: gtk-doc
 BuildRequires: vala
 BuildRequires: usbutils
 BuildRequires: libsoup-devel >= 2.49.91
+%if 0%{?fedora}
 BuildRequires: libphodav-devel
+%endif
 BuildRequires: lz4-devel
 BuildRequires: gtk3-devel
 BuildRequires: json-glib-devel
@@ -120,6 +122,9 @@ gpgv2 --quiet --keyring %{SOURCE2} %{SOURCE1} %{SOURCE0}
 %ifarch s390x # https://gitlab.freedesktop.org/spice/spice-gtk/issues/120
   -Dusbredir=disabled \\
 %endif
+%if 0%{?rhel}
+  -Dwebdav=disabled \\
+%endif
 %if 0%{?flatpak}
   -Dpolkit=disabled
 %else
EOF

sed -i 's/defined rhel/defined nullified/g' edk2.spec
sed -i 's/defined fedora/defined rhel/g' edk2.spec

# Build the spec files.
rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) lzfse.spec 2>&1 | tee lzfse.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " lzfse.spec) || \
{ printf "\n\e[1;91m# The lzfse rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The lzfse rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) virglrenderer.spec 2>&1 | tee virglrenderer.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " virglrenderer.spec) || \
{ printf "\n\e[1;91m# The virglrenderer rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The virglrenderer rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libcacard.spec 2>&1 | tee libcacard.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libcacard.spec) || \
{ printf "\n\e[1;91m# The libcacard rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libcacard rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) fcode-utils.spec 2>&1 | tee fcode-utils.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " fcode-utils.spec) || \
{ printf "\n\e[1;91m# The fcode-utils rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The fcode-utils rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) openbios.spec 2>&1 | tee openbios.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " openbios.spec) || \
{ printf "\n\e[1;91m# The openbios rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The openbios rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) python-pefile.spec 2>&1 | tee python-pefile.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(ls -q  $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " python-pefile.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The python-pefile rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The python-pefile rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) python-virt-firmware.spec 2>&1 | tee python-virt-firmware.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(ls -q  $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " python-virt-firmware.spec ) 2>/dev/null | grep -v "python3-virt-firmware-tests") || \
{ printf "\n\e[1;91m# The python-virt-firmware rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The python-virt-firmware rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) edk2.spec 2>&1 | tee edk2.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " edk2.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The edk2 rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The edk2 rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) SLOF.spec 2>&1 | tee SLOF.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " SLOF.spec) || \
{ printf "\n\e[1;91m# The SLOF rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The SLOF rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) spice-protocol.spec 2>&1 | tee spice-protocol.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " spice-protocol.spec) || \
{ printf "\n\e[1;91m# The spice-protocol rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The spice-protocol rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) spice.spec 2>&1 | tee spice.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(ls -q  $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " spice.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The spice rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The spice rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) qemu.spec 2>&1 | tee qemu.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " qemu.spec ) || \
{ printf "\n\e[1;91m# The qemu rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The qemu rpmbuild finished.\e[0;0m\n"

# No longer needed.
# rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) adobe-source-code-pro-fonts.spec 2>&1 | tee adobe-source-code-pro-fonts.log > /dev/null && \
# rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " adobe-source-code-pro-fonts.spec ) || \
# { printf "\n\e[1;91m# The adobe-source-code-pro-fonts rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
# printf "\e[1;92m# The adobe-source-code-pro-fonts rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) python-smartypants.spec 2>&1 | tee python-smartypants.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " python-smartypants.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The python-smartypants rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The python-smartypants rpmbuild finished.\e[0;0m\n"

# An RPM is available for python3-typogrify but it requires smartypants which weas just installed.
dnf install --quiet --assumeyes --enablerepo=* python3-typogrify

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) gi-docgen.spec 2>&1 | tee gi-docgen.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " gi-docgen.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The gi-docgen rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The gi-docgen rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) spice-gtk.spec 2>&1 | tee spice-gtk.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " spice-gtk.spec ) || \
{ printf "\n\e[1;91m# The spice-gtk rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The spice-gtk rpmbuild finished.\e[0;0m\n"

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) virt-manager.spec 2>&1 | tee virt-manager.log > /dev/null && \
rpm -i --replacepkgs --replacefiles $(ls -q $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " virt-manager.spec ) 2>/dev/null) || \
{ printf "\n\e[1;91m# The virt-manager rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The virt-manager rpmbuild finished.\e[0;0m\n"

# Download the dependencies needed for installation, which aren't available from the official, 
# and/or, EPEL repos. They will be added to the collection of binary packages that were just 
# built.
dnf --quiet --enablerepo=remi --enablerepo=remi-debuginfo --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download SDL2_image SDL2_image-debuginfo SDL2_image-devel SDL2_image-debugsource
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debug --enablerepo=crb --enablerepo=crb-debug --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download pcsc-lite-devel pcsc-lite-libs pcsc-lite-libs-debuginfo pcsc-lite-devel-debuginfo
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debug --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download mesa-libgbm mesa-libgbm-devel mesa-libgbm-debuginfo
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debug --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download usbredir usbredir-devel usbredir-debuginfo usbredir-debugsource
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debug --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download opus opus-devel opus-debuginfo opus-debugsource
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debug --enablerepo=crb --enablerepo=crb-debug --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download gobject-introspection gobject-introspection-devel gobject-introspection-debuginfo gobject-introspection-debugsource
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debug --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download libogg libogg-devel libogg-debuginfo libogg-debugsource
dnf --quiet --enablerepo=crb --enablerepo=crb-debug --arch=noarch --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/noarch/ download python3-markdown

# Consolidate the RPMs.
mkdir $HOME/RPMS/
find $HOME/rpmbuild/RPMS/noarch/*rpm $HOME/rpmbuild/RPMS/x86_64/*rpm $HOME/rpmbuild/SRPMS/*btrh*rpm > $HOME/rpm.outputs.txt
mv $HOME/rpmbuild/RPMS/noarch/*rpm $HOME/rpmbuild/RPMS/x86_64/*rpm $HOME/rpmbuild/SRPMS/*btrh*rpm $HOME/RPMS/

cd  $HOME/RPMS/

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

tee $HOME/RPMS/INSTALL.sh <<-EOF > /dev/null
#!/bin/bash -eu

# Name: INSTALL.sh
# Author: Ladar Levison

# Description: This script removes conflicting packages which may have 
#   been installed from distro repositories, and replaces them with 
#   improved versions. 

# License: This scirpt is hereby placed in the public domain, AND IS 
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

# To generate a current/updated list of RPM files for installation, run the following command.
export INSTALLPKGS=\$(echo \`ls qemu*rpm spice*rpm opus*rpm usbredir*rpm openbios*rpm capstone*rpm libblkio*rpm lzfse*rpm virglrenderer*rpm libcacard*rpm edk2*rpm SLOF*rpm SDL2*rpm libogg-devel*rpm pcsc-lite-devel*rpm mesa-libgbm-devel*rpm usbredir-devel*rpm opus-devel*rpm gobject-introspection-devel*rpm python3-markdown*rpm virt-manager*rpm virt-install*rpm | grep -Ev 'debuginfo|debugsource|\\.src\\.rpm'\`)

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
export REMOVEPKGS=\$(echo \`echo 'edk2 edk2-aarch64 edk2-arm edk2-debugsource edk2-ext4 edk2-ovmf edk2-ovmf-experimental edk2-ovmf-ia32 edk2-tools edk2-tools-debuginfo edk2-tools-doc edk2-tools-python qemu-kvm-audio-pa qemu-kvm-block-curl qemu-kvm-block-rbd qemu-kvm-common qemu-kvm-debugsource qemu-kvm-device-display-virtio-gpu qemu-kvm-device-display-virtio-gpu-gl qemu-kvm-device-display-virtio-gpu-pci qemu-kvm-device-display-virtio-gpu-pci-gl qemu-kvm-device-display-virtio-vga qemu-kvm-device-display-virtio-vga-gl qemu-kvm-device-usb-host qemu-kvm-device-usb-redirect qemu-kvm-docs qemu-kvm-tools qemu-kvm-ui-egl-headless qemu-kvm-ui-opengl virtiofsd qemu-kvm-audio-pa-debuginfo qemu-kvm-block-curl-debuginfo qemu-kvm-block-rbd-debuginfo qemu-kvm-block-ssh-debuginfo qemu-kvm-common-debuginfo qemu-kvm-core-debuginfo qemu-kvm-debuginfo qemu-kvm-device-display-virtio-gpu-debuginfo qemu-kvm-device-display-virtio-gpu-gl-debuginfo qemu-kvm-device-display-virtio-gpu-pci-debuginfo qemu-kvm-device-display-virtio-gpu-pci-gl-debuginfo qemu-kvm-device-display-virtio-vga-debuginfo qemu-kvm-device-display-virtio-vga-gl-debuginfo qemu-kvm-device-usb-host-debuginfo qemu-kvm-device-usb-redirect-debuginfo qemu-kvm-tests-debuginfo qemu-kvm-tools-debuginfo qemu-kvm-ui-egl-headless-debuginfo qemu-kvm-ui-opengl-debuginfo qemu-guest-agent-debuginfo qemu-img-debuginfo qemu-pr-helper-debuginfo virtiofsd virtiofsd-debuginfo virtiofsd-debugsource virglrenderer virglrenderer-debuginfo virglrenderer-debugsource virglrenderer-devel virglrenderer-test-server virglrenderer-test-server-debuginfo virt-install virt-manager virt-manager-common' | tr ' ' '\\n' | while read PKG ; do { rpm --quiet -q \$PKG && echo \$PKG ; } ; done\`)

# The adobe-source-code-pro-fonts package might be required.
# On the target system, run the following command to install the new version of QEMU.
if [ "\$REMOVEPKGS" ]; then
printf "%s\\n" "install \$INSTALLPKGS" "remove \$REMOVEPKGS" "run" "clean all" "exit" | sudo dnf shell --assumeyes
else 
printf "%s\\n" "install \$INSTALLPKGS" "run" "clean all" "exit" | sudo dnf shell --assumeyes
fi

[ ! -f /usr/bin/qemu-kvm ] && [ -f /usr/bin/qemu-system-x86_64 ] && sudo ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-kvm
[ ! -f /usr/libexec/qemu-kvm ] && [ -f /usr/bin/qemu-kvm ] && sudo ln -s /usr/bin/qemu-kvm /usr/libexec/qemu-kvm

EOF

cp $HOME/BUILD.sh $HOME/RPMS/BUILD.sh
chmod 744 $HOME/RPMS/INSTALL.sh
chmod 744 $HOME/RPMS/BUILD.sh

# This will remove QEMU and its dependencies and then reinstall the distro version of QEMU. 
dnf --quiet --assumeyes remove edk2-aarch64 edk2-arm edk2-debugsource edk2-ovmf edk2-tools edk2-tools-doc edk2-tools-python lzfse lzfse-debugsource- lzfse-devel  lzfse-libs  mesa-libgbm-devel openbios pcsc-lite-devel  qemu qemu-audio-alsa qemu-audio-dbus qemu-audio-oss qemu-audio-pa qemu-audio-sdl qemu-audio-spice qemu-block-curl qemu-block-dmg qemu-block-iscsi qemu-block-rbd qemu-block-ssh qemu-char-baum qemu-char-spice qemu-common qemu-debugsource qemu-device-display-qxl qemu-device-display-vhost-user-gpu qemu-device-display-virtio-gpuqemu-device-display-virtio-gpu-ccw qemu-device-display-virtio-gpu-gl qemu-device-display-virtio-gpu-pci qemu-device-display-virtio-gpu-pci-gl qemu-device-display-virtio-vga qemu-device-display-virtio-vga-gl qemu-device-usb-host qemu-device-usb-redirect qemu-device-usb-smartcard qemu-docs qemu-guest-agent qemu-img qemu-kvm qemu-kvm-core qemu-pr-helper qemu-system-aarch64 qemu-system-aarch64-core qemu-system-alpha qemu-system-alpha-core qemu-system-arm qemu-system-arm-core qemu-system-avr qemu-system-avr-core qemu-system-cris qemu-system-cris-core qemu-system-hppa qemu-system-hppa-core qemu-system-loongarch64 qemu-system-loongarch64-core qemu-system-m68k qemu-system-m68k-core qemu-system-microblaze qemu-system-microblaze-core qemu-system-mips qemu-system-mips-core qemu-system-nios2 qemu-system-nios2-core qemu-system-or1k qemu-system-or1k-core qemu-system-ppc qemu-system-ppc-core qemu-system-riscv qemu-system-riscv-core qemu-system-rx qemu-system-rx-core qemu-system-s390x qemu-system-s390x-core qemu-system-sh4 qemu-system-sh4-core qemu-system-sparc qemu-system-sparc-core qemu-system-tricore qemu-system-tricore-core qemu-system-x86 qemu-system-x86-core qemu-system-xtensa qemu-system-xtensa-core qemu-tests qemu-tools qemu-ui-curses qemu-ui-dbus qemu-ui-egl-headless qemu-ui-gtk qemu-ui-opengl qemu-ui-sdl qemu-ui-spice-app qemu-ui-spice-core qemu-user qemu-user-binfmt qemu-user-static qemu-user-static-aarch64 qemu-user-static-alpha qemu-user-static-arm qemu-user-static-cris qemu-user-static-hexagon qemu-user-static-hppa qemu-user-static-loongarch64 qemu-user-static-m68k qemu-user-static-microblaze qemu-user-static-mips qemu-user-static-nios2 qemu-user-static-or1k qemu-user-static-ppc qemu-user-static-riscv qemu-user-static-s390x qemu-user-static-sh4 qemu-user-static-sparc qemu-user-static-x86 qemu-user-static-xtensa qemu-virtiofsd SDL2_image SDL2_image-debugsource SDL2_image-devel SLOF-20210217-5 spice-server spice-server-devel virglrenderer virglrenderer-debugsource virglrenderer-devel virglrenderer-test-server qemu-img qemu-kvm qemu-kvm-audio-pa qemu-kvm-block-curl qemu-kvm-block-rbd qemu-kvm-common qemu-kvm-core qemu-kvm-device-display-virtio-gpu qemu-kvm-device-display-virtio-gpu-gl qemu-kvm-device-display-virtio-gpu-pci qemu-kvm-device-display-virtio-gpu-pci-gl qemu-kvm-device-display-virtio-vga qemu-kvm-device-display-virtio-vga-gl qemu-kvm-device-usb-host qemu-kvm-device-usb-redirect qemu-kvm-docs qemu-kvm-tools qemu-kvm-ui-egl-headless qemu-kvm-ui-opengl qemu-pr-helper virtiofsd qemu* $(rpm -qa | grep btrh)
dnf --quiet --assumeyes config-manager --disable "remi*" "elrepo*" "rpmfusion*" "crb*"
dnf --quiet --enablerepo=* clean all
dnf --quiet --assumeyes install qemu-img qemu-kvm qemu-kvm-audio-pa qemu-kvm-block-curl qemu-kvm-block-rbd qemu-kvm-common qemu-kvm-core qemu-kvm-device-display-virtio-gpu qemu-kvm-device-display-virtio-gpu-gl qemu-kvm-device-display-virtio-gpu-pci qemu-kvm-device-display-virtio-gpu-pci-gl qemu-kvm-device-display-virtio-vga qemu-kvm-device-display-virtio-vga-gl qemu-kvm-device-usb-host qemu-kvm-device-usb-redirect qemu-kvm-docs qemu-kvm-tools qemu-kvm-ui-egl-headless qemu-kvm-ui-opengl qemu-pr-helper virtiofsd 

# This quiets DNF by default, which allows INSTALL.sh to run silently on the virtual 
# machine used to build the RPMS. When INSTALL.sh elsewhere, it will use the default
# verbosity setting, which usually means it will print a transaction summary.
printf "\ndebuglevel=0\n" >> /etc/dnf/dnf.conf

# Execute the INSTALL.sh script on the virtual machine used to build the the RPMS. This
# and simulate replacing the official QEMU packages with the freshly built RPM files.
bash -eu $HOME/RPMS/INSTALL.sh

# Move the compiled RPMs to the Vagrant user home directory, so they are easy to fetch via SFTP.
cd $HOME
mv $HOME/RPMS/ /home/vagrant/RPMS/
chmod 744 /home/vagrant/RPMS/ /home/vagrant//RPMS/INSTALL.sh /home/vagrant//RPMS/BUILD.sh
chmod 644 /home/vagrant/RPMS/*rpm
chown -R vagrant:vagrant /home/vagrant/RPMS/

source /etc/os-release
[ "$REDHAT_SUPPORT_PRODUCT_VERSION" == "9.1" ] && printf "\n\e[1;91m# It appears RHEL v9.2 has shipped. The capstone libs can probably be removed.\e[0;0m"

printf "\n\nAll done.\n\n"
