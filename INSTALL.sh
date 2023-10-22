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
# sudo dnf install `ls *rpm | grep -Ev "\.src\.|debuginfo|debugsource|devel|ocaml|vala|uki-direct"` `ls libguestfs-devel*rpm libvirt-gobject-devel*rpm libvirt-gconfig-devel*rpm libvirt-glib-devel*rpm  libvirt-devel*rpm libguestfs-gobject-devel*rpm gobject-introspection-devel*rpm pcre2-devel*rpm libosinfo-devel*rpm`


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

