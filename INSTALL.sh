#!/bin/bash -eu

# To generate a current/updated list of RPM files for installation, run the following command.
export INSTALLPKGS=$(echo `ls qemu*rpm spice*rpm opus*rpm usbredir*rpm openbios*rpm capstone*rpm libblkio*rpm lzfse*rpm virglrenderer*rpm libcacard*rpm edk2*rpm SLOF*rpm SDL2*rpm libogg-devel*rpm pcsc-lite-devel*rpm mesa-libgbm-devel*rpm usbredir-devel*rpm opus-devel*rpm gobject-introspection-devel*rpm python3-markdown*rpm virt-manager*rpm virt-install*rpm | grep -Ev 'debuginfo|debugsource|\.src\.rpm'`)

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
export REMOVEPKGS=$(echo `echo 'qemu-kvm-audio-pa qemu-kvm-block-curl qemu-kvm-block-rbd qemu-kvm-common qemu-kvm-debugsource qemu-kvm-device-display-virtio-gpu qemu-kvm-device-display-virtio-gpu-gl qemu-kvm-device-display-virtio-gpu-pci qemu-kvm-device-display-virtio-gpu-pci-gl qemu-kvm-device-display-virtio-vga qemu-kvm-device-display-virtio-vga-gl qemu-kvm-device-usb-host qemu-kvm-device-usb-redirect qemu-kvm-docs qemu-kvm-tools qemu-kvm-ui-egl-headless qemu-kvm-ui-opengl virtiofsd qemu-kvm-audio-pa-debuginfo qemu-kvm-block-curl-debuginfo qemu-kvm-block-rbd-debuginfo qemu-kvm-block-ssh-debuginfo qemu-kvm-common-debuginfo qemu-kvm-core-debuginfo qemu-kvm-debuginfo qemu-kvm-device-display-virtio-gpu-debuginfo qemu-kvm-device-display-virtio-gpu-gl-debuginfo qemu-kvm-device-display-virtio-gpu-pci-debuginfo qemu-kvm-device-display-virtio-gpu-pci-gl-debuginfo qemu-kvm-device-display-virtio-vga-debuginfo qemu-kvm-device-display-virtio-vga-gl-debuginfo qemu-kvm-device-usb-host-debuginfo qemu-kvm-device-usb-redirect-debuginfo qemu-kvm-tests-debuginfo qemu-kvm-tools-debuginfo qemu-kvm-ui-egl-headless-debuginfo qemu-kvm-ui-opengl-debuginfo qemu-guest-agent-debuginfo qemu-img-debuginfo qemu-pr-helper-debuginfo virtiofsd virtiofsd-debuginfo virtiofsd-debugsource' | tr ' ' '\n' | while read PKG ; do { rpm --quiet -q $PKG && echo $PKG ; } ; done`)

# The adobe-source-code-pro-fonts package might be required.
# On the target system, run the following command to install the new version of QEMU.
if [ "$REMOVEPKGS" ]; then
printf "%s\n" "install $INSTALLPKGS" "remove $REMOVEPKGS" "run" "clean all" "exit" | sudo dnf shell --assumeyes
else 
printf "%s\n" "install $INSTALLPKGS" "run" "clean all" "exit" | sudo dnf shell --assumeyes
fi

[ ! -f /usr/bin/qemu-kvm ] && [ -f /usr/bin/qemu-system-x86_64 ] && sudo ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-kvm
[ ! -f /usr/libexec/qemu-kvm ] && && [ -f /usr/bin/qemu-kvm ] && sudo ln -s /usr/bin/qemu-kvm /usr/libexec/qemu-kvm
