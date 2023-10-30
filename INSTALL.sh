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

# Quickly Install Everything (Except the vala/ocaml/qxl/xspice pcakages)
# sudo dnf install --enablerepo=baseos --enablerepo=appstream --enablerepo=epel --enablerepo=crb avahi-0.8-3072.btrh9.1.x86_64.rpm
avahi-autoipd-0.8-3072.btrh9.1.x86_64.rpm
avahi-compat-howl-0.8-3072.btrh9.1.x86_64.rpm
avahi-compat-howl-devel-0.8-3072.btrh9.1.x86_64.rpm
avahi-compat-libdns_sd-0.8-3072.btrh9.1.x86_64.rpm
avahi-compat-libdns_sd-devel-0.8-3072.btrh9.1.x86_64.rpm
avahi-devel-0.8-3072.btrh9.1.x86_64.rpm
avahi-dnsconfd-0.8-3072.btrh9.1.x86_64.rpm
avahi-glib-0.8-3072.btrh9.1.x86_64.rpm
avahi-glib-devel-0.8-3072.btrh9.1.x86_64.rpm
avahi-gobject-0.8-3072.btrh9.1.x86_64.rpm
avahi-gobject-devel-0.8-3072.btrh9.1.x86_64.rpm
avahi-libs-0.8-3072.btrh9.1.x86_64.rpm
avahi-tools-0.8-3072.btrh9.1.x86_64.rpm
avahi-ui-0.8-3072.btrh9.1.x86_64.rpm
avahi-ui-devel-0.8-3072.btrh9.1.x86_64.rpm
avahi-ui-gtk3-0.8-3072.btrh9.1.x86_64.rpm
avahi-ui-tools-0.8-3072.btrh9.1.x86_64.rpm
chezdav-2.5-3072.btrh9.x86_64.rpm
chunkfs-0.8-3072.btrh9.x86_64.rpm
depends/libblkio-1.2.2-2.eln125.x86_64.rpm
depends/libblkio-devel-1.2.2-2.eln125.x86_64.rpm
edk2-aarch64-20230825-3072.btrh9.noarch.rpm
edk2-arm-20230825-3072.btrh9.noarch.rpm
edk2-experimental-20230825-3072.btrh9.noarch.rpm
edk2-ext4-20230825-3072.btrh9.noarch.rpm
edk2-ovmf-20230825-3072.btrh9.noarch.rpm
edk2-ovmf-ia32-20230825-3072.btrh9.noarch.rpm
edk2-ovmf-xen-20230825-3072.btrh9.noarch.rpm
edk2-riscv64-20230825-3072.btrh9.noarch.rpm
edk2-tools-20230825-3072.btrh9.x86_64.rpm
edk2-tools-doc-20230825-3072.btrh9.noarch.rpm
edk2-tools-python-20230825-3072.btrh9.noarch.rpm
fcode-utils-1.0.2-3072.svn1354.btrh9.x86_64.rpm
gtk-vnc2-1.3.1-3072.btrh9.x86_64.rpm
gtk-vnc2-devel-1.3.1-3072.btrh9.x86_64.rpm
guestfs-tools-1.48.2-3072.btrh9.x86_64.rpm
guestfs-tools-bash-completion-1.48.2-3072.btrh9.noarch.rpm
guestfs-tools-man-pages-ja-1.48.2-3072.btrh9.noarch.rpm
guestfs-tools-man-pages-uk-1.48.2-3072.btrh9.noarch.rpm
gvnc-1.3.1-3072.btrh9.x86_64.rpm
gvnc-devel-1.3.1-3072.btrh9.x86_64.rpm
gvncpulse-1.3.1-3072.btrh9.x86_64.rpm
gvncpulse-devel-1.3.1-3072.btrh9.x86_64.rpm
gvnc-tools-1.3.1-3072.btrh9.x86_64.rpm
libcacard-2.8.1-3072.btrh9.x86_64.rpm
libcacard-devel-2.8.1-3072.btrh9.x86_64.rpm
libguestfs-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-appliance-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-bash-completion-1.48.4-3072.btrh9.noarch.rpm
libguestfs-devel-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-gobject-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-gobject-devel-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-hfsplus-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-inspect-icons-1.48.4-3072.btrh9.noarch.rpm
libguestfs-man-pages-ja-1.48.4-3072.btrh9.noarch.rpm
libguestfs-man-pages-uk-1.48.4-3072.btrh9.noarch.rpm
libguestfs-rescue-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-rsync-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-ufs-1.48.4-3072.btrh9.x86_64.rpm
libguestfs-xfs-1.48.4-3072.btrh9.x86_64.rpm
liblxqt-1.3.0-1.btrh9.x86_64.rpm
liblxqt-devel-1.3.0-1.btrh9.x86_64.rpm
liblxqt-l10n-1.3.0-1.btrh9.noarch.rpm
libosinfo-1.10.0-3072.btrh9.x86_64.rpm
libosinfo-devel-1.10.0-3072.btrh9.x86_64.rpm
libphodav-2.5-3072.btrh9.x86_64.rpm
libphodav-devel-2.5-3072.btrh9.x86_64.rpm
libqtxdg-3.11.0-1.btrh9.x86_64.rpm
libqtxdg-devel-3.11.0-1.btrh9.x86_64.rpm
libvirt-9.8.0-3072.btrh9.x86_64.rpm
libvirt-client-9.8.0-3072.btrh9.x86_64.rpm
libvirt-client-qemu-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-common-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-config-network-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-config-nwfilter-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-interface-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-network-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-nodedev-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-nwfilter-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-qemu-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-secret-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-storage-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-storage-core-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-storage-disk-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-storage-iscsi-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-storage-logical-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-storage-mpath-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-storage-rbd-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-driver-storage-scsi-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-kvm-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-lock-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-log-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-plugin-lockd-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-plugin-sanlock-9.8.0-3072.btrh9.x86_64.rpm
libvirt-daemon-proxy-9.8.0-3072.btrh9.x86_64.rpm
libvirt-dbus-1.4.0-3072.btrh9.x86_64.rpm
libvirt-devel-9.8.0-3072.btrh9.x86_64.rpm
libvirt-docs-9.8.0-3072.btrh9.x86_64.rpm
libvirt-gconfig-4.0.0-3072.btrh9.x86_64.rpm
libvirt-gconfig-devel-4.0.0-3072.btrh9.x86_64.rpm
libvirt-glib-4.0.0-3072.btrh9.x86_64.rpm
libvirt-glib-devel-4.0.0-3072.btrh9.x86_64.rpm
libvirt-gobject-4.0.0-3072.btrh9.x86_64.rpm
libvirt-gobject-devel-4.0.0-3072.btrh9.x86_64.rpm
libvirt-libs-9.8.0-3072.btrh9.x86_64.rpm
libvirt-nss-9.8.0-3072.btrh9.x86_64.rpm
libvirt-wireshark-9.8.0-3072.btrh9.x86_64.rpm
libXvMC-1.0.13-3072.btrh9.x86_64.rpm
libXvMC-devel-1.0.13-3072.btrh9.x86_64.rpm
lua-guestfs-1.48.4-3072.btrh9.x86_64.rpm
lxqt-build-tools-0.13.0-1.btrh9.noarch.rpm
lzfse-1.0-3072.btrh9.x86_64.rpm
lzfse-devel-1.0-3072.btrh9.x86_64.rpm
lzfse-libs-1.0-3072.btrh9.x86_64.rpm
mesa-dri-drivers-22.3.0-3072.btrh9.x86_64.rpm
mesa-filesystem-22.3.0-3072.btrh9.x86_64.rpm
mesa-libEGL-22.3.0-3072.btrh9.x86_64.rpm
mesa-libEGL-devel-22.3.0-3072.btrh9.x86_64.rpm
mesa-libgbm-22.3.0-3072.btrh9.x86_64.rpm
mesa-libgbm-devel-22.3.0-3072.btrh9.x86_64.rpm
mesa-libGL-22.3.0-3072.btrh9.x86_64.rpm
mesa-libglapi-22.3.0-3072.btrh9.x86_64.rpm
mesa-libGL-devel-22.3.0-3072.btrh9.x86_64.rpm
mesa-libOSMesa-22.3.0-3072.btrh9.x86_64.rpm
mesa-libOSMesa-devel-22.3.0-3072.btrh9.x86_64.rpm
mesa-libxatracker-22.3.0-3072.btrh9.x86_64.rpm
mesa-libxatracker-devel-22.3.0-3072.btrh9.x86_64.rpm
mesa-vdpau-drivers-22.3.0-3072.btrh9.x86_64.rpm
mesa-vulkan-drivers-22.3.0-3072.btrh9.x86_64.rpm
openbios-20230126-3072.gitaf97fd7.btrh9.noarch.rpm
osinfo-db-20230719-3072.btrh9.noarch.rpm
osinfo-db-tools-1.10.0-3072.btrh9.x86_64.rpm
passt-20231027-3072.btrh9.x86_64.rpm
passt-selinux-20231027-3072.btrh9.noarch.rpm
pcre2-10.40-3072.btrh9.x86_64.rpm
pcre2-devel-10.40-3072.btrh9.x86_64.rpm
pcre2-static-10.40-3072.btrh9.x86_64.rpm
pcre2-syntax-10.40-3072.btrh9.noarch.rpm
pcre2-tools-10.40-3072.btrh9.x86_64.rpm
pcre2-utf16-10.40-3072.btrh9.x86_64.rpm
pcre2-utf32-10.40-3072.btrh9.x86_64.rpm
perl-Sys-Guestfs-1.48.4-3072.btrh9.x86_64.rpm
php-libguestfs-1.48.4-3072.btrh9.x86_64.rpm
python3-libguestfs-1.48.4-3072.btrh9.x86_64.rpm
python3-libvirt-9.8.0-3072.btrh9.x86_64.rpm
python3-pefile-2023.2.7-3072.btrh9.noarch.rpm
python3-virt-firmware-23.10-3072.btrh9.noarch.rpm
python3-virt-firmware-tests-23.10-3072.btrh9.noarch.rpm
qemu-8.1.2-3072.btrh9.x86_64.rpm
qemu-audio-alsa-8.1.2-3072.btrh9.x86_64.rpm
qemu-audio-dbus-8.1.2-3072.btrh9.x86_64.rpm
qemu-audio-oss-8.1.2-3072.btrh9.x86_64.rpm
qemu-audio-pa-8.1.2-3072.btrh9.x86_64.rpm
qemu-audio-sdl-8.1.2-3072.btrh9.x86_64.rpm
qemu-audio-spice-8.1.2-3072.btrh9.x86_64.rpm
qemu-block-blkio-8.1.2-3072.btrh9.x86_64.rpm
qemu-block-curl-8.1.2-3072.btrh9.x86_64.rpm
qemu-block-dmg-8.1.2-3072.btrh9.x86_64.rpm
qemu-block-iscsi-8.1.2-3072.btrh9.x86_64.rpm
qemu-block-rbd-8.1.2-3072.btrh9.x86_64.rpm
qemu-block-ssh-8.1.2-3072.btrh9.x86_64.rpm
qemu-char-baum-8.1.2-3072.btrh9.x86_64.rpm
qemu-char-spice-8.1.2-3072.btrh9.x86_64.rpm
qemu-common-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-qxl-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-vhost-user-gpu-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-virtio-gpu-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-virtio-gpu-ccw-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-virtio-gpu-gl-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-virtio-gpu-pci-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-virtio-gpu-pci-gl-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-virtio-vga-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-display-virtio-vga-gl-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-usb-host-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-usb-redirect-8.1.2-3072.btrh9.x86_64.rpm
qemu-device-usb-smartcard-8.1.2-3072.btrh9.x86_64.rpm
qemu-docs-8.1.2-3072.btrh9.noarch.rpm
qemu-guest-agent-8.1.2-3072.btrh9.x86_64.rpm
qemu-img-8.1.2-3072.btrh9.x86_64.rpm
qemu-kvm-8.1.2-3072.btrh9.x86_64.rpm
qemu-kvm-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-pr-helper-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-aarch64-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-aarch64-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-alpha-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-alpha-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-arm-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-arm-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-avr-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-avr-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-cris-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-cris-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-hppa-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-hppa-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-loongarch64-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-loongarch64-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-m68k-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-m68k-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-microblaze-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-microblaze-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-mips-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-mips-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-nios2-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-nios2-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-or1k-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-or1k-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-ppc-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-ppc-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-riscv-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-riscv-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-rx-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-rx-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-s390x-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-s390x-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-sh4-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-sh4-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-sparc-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-sparc-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-tricore-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-tricore-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-x86-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-x86-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-xtensa-8.1.2-3072.btrh9.x86_64.rpm
qemu-system-xtensa-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-tests-8.1.2-3072.btrh9.x86_64.rpm
qemu-tools-8.1.2-3072.btrh9.x86_64.rpm
qemu-ui-curses-8.1.2-3072.btrh9.x86_64.rpm
qemu-ui-dbus-8.1.2-3072.btrh9.x86_64.rpm
qemu-ui-egl-headless-8.1.2-3072.btrh9.x86_64.rpm
qemu-ui-gtk-8.1.2-3072.btrh9.x86_64.rpm
qemu-ui-opengl-8.1.2-3072.btrh9.x86_64.rpm
qemu-ui-sdl-8.1.2-3072.btrh9.x86_64.rpm
qemu-ui-spice-app-8.1.2-3072.btrh9.x86_64.rpm
qemu-ui-spice-core-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-binfmt-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-aarch64-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-alpha-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-arm-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-cris-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-hexagon-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-hppa-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-loongarch64-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-m68k-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-microblaze-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-mips-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-nios2-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-or1k-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-ppc-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-riscv-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-s390x-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-sh4-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-sparc-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-x86-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-static-xtensa-8.1.2-3072.btrh9.x86_64.rpm
qemu-user-vfio-8.1.2-3072.btrh9.x86_64.rpm
qtermwidget-1.3.0-1.btrh9.x86_64.rpm
qtermwidget-devel-1.3.0-1.btrh9.x86_64.rpm
qtermwidget-l10n-1.3.0-1.btrh9.noarch.rpm
qt-remote-viewer-0.72.99-6.btrh9.x86_64.rpm
qt-virt-manager-0.72.99-6.btrh9.x86_64.rpm
remmina-1.4.32-3072.btrh9.x86_64.rpm
remmina-devel-1.4.32-3072.btrh9.x86_64.rpm
remmina-gnome-session-1.4.32-3072.btrh9.x86_64.rpm
remmina-plugins-exec-1.4.32-3072.btrh9.x86_64.rpm
remmina-plugins-kwallet-1.4.32-3072.btrh9.x86_64.rpm
remmina-plugins-python-1.4.32-3072.btrh9.x86_64.rpm
remmina-plugins-rdp-1.4.32-3072.btrh9.x86_64.rpm
remmina-plugins-secret-1.4.32-3072.btrh9.x86_64.rpm
remmina-plugins-spice-1.4.32-3072.btrh9.x86_64.rpm
remmina-plugins-vnc-1.4.32-3072.btrh9.x86_64.rpm
remmina-plugins-www-1.4.32-3072.btrh9.x86_64.rpm
ruby-libguestfs-1.48.4-3072.btrh9.x86_64.rpm
SLOF-20220719-3072.git6b6c16b4.btrh9.noarch.rpm
spice-glib-0.40-3072.btrh9.x86_64.rpm
spice-glib-devel-0.40-3072.btrh9.x86_64.rpm
spice-gtk-0.40-3072.btrh9.x86_64.rpm
spice-gtk3-0.40-3072.btrh9.x86_64.rpm
spice-gtk3-devel-0.40-3072.btrh9.x86_64.rpm
spice-gtk-tools-0.40-3072.btrh9.x86_64.rpm
spice-protocol-0.14.4-3072.btrh9.noarch.rpm
spice-server-0.15.1-3072.btrh9.x86_64.rpm
spice-server-devel-0.15.1-3072.btrh9.x86_64.rpm
spice-webdavd-2.5-3072.btrh9.x86_64.rpm
virglrenderer-1.0.0-3072.btrh9.x86_64.rpm
virglrenderer-devel-1.0.0-3072.btrh9.x86_64.rpm
virglrenderer-test-server-1.0.0-3072.btrh9.x86_64.rpm
virt-backup-0.2.25-3072.btrh9.noarch.rpm
virt-install-4.1.0-3072.btrh9.noarch.rpm
virt-manager-4.1.0-3072.btrh9.noarch.rpm
virt-manager-common-4.1.0-3072.btrh9.noarch.rpm
virt-viewer-11.0-3072.btrh9.x86_64.rpm
virt-win-reg-1.48.2-3072.btrh9.noarch.rpm
xorg-x11-drv-intel-2.99.917-3072.btrh9.x86_64.rpm
xorg-x11-drv-nouveau-1.0.17-3072.btrh9.x86_64.rpm 

if [ ! $(sudo dnf repolist --quiet baseos 2>&1 | grep -Eo "^baseos") ]; then  
 printf "\nThe baseos repo is required but doesn't appear to be enabled.\n\n"
 exit 1
fi

if [ ! $(sudo dnf repolist --quiet appstream 2>&1 | grep -Eo "^appstream") ]; then  
 printf "\nThe appstream repo is required but doesn't appear to be enabled.\n\n"
 exit 1
fi
if [ ! $(sudo dnf repolist --quiet epel 2>&1 | grep -Eo "^epel") ]; then  
 printf "\nThe epel repo is required but doesn't appear to be installed (or enabled).\n\n"
 exit 1
fi

# To generate a current/updated list of RPM files for installation, run the following command.

# Install the basic qemu/libvirt/virt-manager/spice packages.
export INSTALLPKGS=$(echo `ls depends/opus*rpm depends/usbredir*rpm depends/capstone*rpm depends/python3-capstone*rpm depends/libblkio*rpm depends/SDL2*rpm depends/libogg-devel*rpm depends/pcsc-lite*rpm depends/usbredir-devel*rpm depends/opus-devel*rpm depends/gobject-introspection-devel*rpm depends/python3-markdown*rpm depends/vala*rpm depends/libvala*rpm avahi*rpm qemu*rpm spice*rpm openbios*rpm lzfse*rpm virglrenderer*rpm libcacard*rpm edk2*rpm SLOF*rpm mesa-libgbm*rpm mesa-libgbm-devel*rpm virt-manager*rpm virt-viewer*rpm virt-install*rpm virt-backup*rpm passt*rpm libphodav*rpm gvnc*rpm gtk-vnc*rpm chunkfs*rpm osinfo*rpm libosinfo*rpm libvirt*rpm python3-libvirt*rpm chezdav*rpm fcode-utils*rpm python3-pefile*rpm python3-virt-firmware*rpm libguestfs*rpm python3-libguestfs*rpm guestfs-tools*rpm | grep -Ev 'qemu-guest-agent|qemu-tests|debuginfo|debugsource|\.src\.rpm' ; echo vala`)

# Add the remmina packages.
## export INSTALLPKGS=$(echo $INSTALLPKGS `ls remmina*rpm | grep -Ev 'debuginfo|debugsource|\.src\.rpm'`)

# Add the mesa packages.
## export INSTALLPKGS=$(echo $INSTALLPKGS `ls mesa*rpm | grep -Ev 'debuginfo|debugsource|\.src\.rpm'`)

# Add the avahi packages.
## export INSTALLPKGS=$(echo $INSTALLPKGS `ls avahi*rpm | grep -Ev 'debuginfo|debugsource|\.src\.rpm'`)

# Add the xorg driver packages.
## export INSTALLPKGS=$(echo $INSTALLPKGS `ls xorg-x11*rpm libXvMC*rpm pcre2*rpm | grep -Ev 'debuginfo|debugsource|\.src\.rpm'`)

# Add the pcre2-static package.
## export INSTALLPKGS=$(echo $INSTALLPKGS `ls pcre2-static-*rpm | grep -Ev 'debuginfo|debugsource|\.src\.rpm'`)

# Add the qt version of virt manager. The gnutls/scrub packages are suggested by the spec file, but not required.
## export INSTALLPKGS=$(echo $INSTALLPKGS `ls pcsc-lite*rpm libcacard*rpm spice*rpm qt-virt-manager*rpm qtermwidget*rpm qt-remote-viewer*rpm liblxqt*rpm libqtxdg*rpm lxqt-build-tools*rpm | grep -Ev 'debuginfo|debugsource|\.src\.rpm' ; echo scrub gnutls`)

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
export REMOVEPKGS=$(echo `echo 'edk2-debugsource edk2-tools-debuginfo virglrenderer-debuginfo virglrenderer-debugsource virglrenderer-test-server-debuginfo virt-install virt-manager virt-manager-common virt-viewer virt-viewer-debuginfo virt-viewer-debugsource virt-backup gtk-vnc2 gtk-vnc2-devel gtk-vnc-debuginfo gtk-vnc-debugsource gvnc gvnc-devel gvncpulse gvncpulse-devel gvnc-tools libvirt-client libvirt-client-debuginfo libvirt-daemon libvirt-daemon-config-network libvirt-daemon-debuginfo libvirt-daemon-driver-interface libvirt-daemon-driver-interface-debuginfo libvirt-daemon-driver-network libvirt-daemon-driver-network-debuginfo libvirt-daemon-driver-nodedev libvirt-daemon-driver-nodedev-debuginfo libvirt-daemon-driver-nwfilter libvirt-daemon-driver-nwfilter-debuginfo libvirt-daemon-driver-qemu libvirt-daemon-driver-qemu-debuginfo libvirt-daemon-driver-secret libvirt-daemon-driver-secret-debuginfo libvirt-daemon-driver-storage libvirt-daemon-driver-storage-core libvirt-daemon-driver-storage-core-debuginfo libvirt-daemon-driver-storage-disk libvirt-daemon-driver-storage-disk-debuginfo libvirt-daemon-driver-storage-iscsi libvirt-daemon-driver-storage-iscsi-debuginfo libvirt-daemon-driver-storage-logical libvirt-daemon-driver-storage-logical-debuginfo libvirt-daemon-driver-storage-mpath libvirt-daemon-driver-storage-mpath-debuginfo libvirt-daemon-driver-storage-rbd libvirt-daemon-driver-storage-rbd-debuginfo libvirt-daemon-driver-storage-scsi libvirt-daemon-driver-storage-scsi-debuginfo libvirt-daemon-kvm libvirt-debuginfo libvirt-devel libvirt-glib libvirt-libs libvirt-libs-debuginfo libvirt-lock-sanlock-debuginfo libvirt-nss-debuginfo libvirt-wireshark-debuginfo python3-libvirt qemu-ga-win qemu-guest-agent qemu-guest-agent-debuginfo qemu-img qemu-img-debuginfo qemu-kvm qemu-kvm-audio-pa qemu-kvm-audio-pa-debuginfo qemu-kvm-block-curl qemu-kvm-block-curl-debuginfo qemu-kvm-block-rbd qemu-kvm-block-rbd-debuginfo qemu-kvm-block-ssh-debuginfo qemu-kvm-common qemu-kvm-common-debuginfo qemu-kvm-core qemu-kvm-core-debuginfo qemu-kvm-debuginfo qemu-kvm-debugsource qemu-kvm-device-display-virtio-gpu qemu-kvm-device-display-virtio-gpu-debuginfo qemu-kvm-device-display-virtio-gpu-gl qemu-kvm-device-display-virtio-gpu-gl-debuginfo qemu-kvm-device-display-virtio-gpu-pci qemu-kvm-device-display-virtio-gpu-pci-debuginfo qemu-kvm-device-display-virtio-gpu-pci-gl qemu-kvm-device-display-virtio-gpu-pci-gl-debuginfo qemu-kvm-device-display-virtio-vga qemu-kvm-device-display-virtio-vga-debuginfo qemu-kvm-device-display-virtio-vga-gl qemu-kvm-device-display-virtio-vga-gl-debuginfo qemu-kvm-device-usb-host qemu-kvm-device-usb-host-debuginfo qemu-kvm-device-usb-redirect qemu-kvm-device-usb-redirect-debuginfo qemu-kvm-docs qemu-kvm-tests-debuginfo qemu-kvm-tools qemu-kvm-tools-debuginfo qemu-kvm-ui-egl-headless qemu-kvm-ui-egl-headless-debuginfo qemu-kvm-ui-opengl qemu-kvm-ui-opengl-debuginfo qemu-pr-helper qemu-pr-helper-debuginfo libosinfo libosinfo-debuginfo libosinfo-debugsource python3-libvirt python3-libvirt-debuginfo pcsc-lite-debuginfo pcsc-lite-debugsource pcsc-lite-devel-debuginfo pcsc-lite-libs-debuginfo pcsc-lite-ccid-debuginfo pcsc-lite-ccid-debugsource mesa-libgbm-debuginfo' | tr ' ' '\n' | while read PKG ; do { rpm --quiet -q $PKG && rpm -q $PKG | grep -v '\.btrh9\.' ; } ; done`)

# This is handled seperately since the obsoleted qemu-virtiofsd package may be tagged with el9 or btrh9.
export REMOVEPKGS=$(echo $REMOVEPKGS $(echo `echo 'qemu-virtiofsd' | tr ' ' '\n' | while read PKG ; do { rpm --quiet -q $PKG && rpm -q $PKG ; } ; done`))

# Ensure previous attempts/transactions don't break the install attempt.
dnf clean all --enablerepo=* &>/dev/null

# On the target system, run the following command to install the new version of QEMU.
if [ "$REMOVEPKGS" ]; then
printf "%s\n" "install $INSTALLPKGS" "remove $REMOVEPKGS" "run" "exit" | dnf shell --assumeyes && dnf --assumeyes reinstall $INSTALLPKGS || exit 1
else 
dnf --assumeyes install $INSTALLPKGS && dnf --assumeyes reinstall $INSTALLPKGS || exit 1
fi

# This shouldn't be needed anymore.
#[ ! -f /usr/bin/qemu-kvm ] && [ -f /usr/bin/qemu-system-x86_64 ] && sudo ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-kvm
#[ ! -f /usr/libexec/qemu-kvm ] && [ -f /usr/bin/qemu-kvm ] && sudo ln -s /usr/bin/qemu-kvm /usr/libexec/qemu-kvm

