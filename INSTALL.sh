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
export REMOVEPKGS=$(echo `echo 'edk2 edk2-aarch64 edk2-arm edk2-debugsource edk2-ext4 edk2-ovmf edk2-ovmf-experimental edk2-ovmf-ia32 edk2-tools edk2-tools-debuginfo edk2-tools-doc edk2-tools-python qemu-kvm-audio-pa qemu-kvm-block-curl qemu-kvm-block-rbd qemu-kvm-common qemu-kvm-debugsource qemu-kvm-device-display-virtio-gpu qemu-kvm-device-display-virtio-gpu-gl qemu-kvm-device-display-virtio-gpu-pci qemu-kvm-device-display-virtio-gpu-pci-gl qemu-kvm-device-display-virtio-vga qemu-kvm-device-display-virtio-vga-gl qemu-kvm-device-usb-host qemu-kvm-device-usb-redirect qemu-kvm-docs qemu-kvm-tools qemu-kvm-ui-egl-headless qemu-kvm-ui-opengl virtiofsd qemu-kvm-audio-pa-debuginfo qemu-kvm-block-curl-debuginfo qemu-kvm-block-rbd-debuginfo qemu-kvm-block-ssh-debuginfo qemu-kvm-common-debuginfo qemu-kvm-core-debuginfo qemu-kvm-debuginfo qemu-kvm-device-display-virtio-gpu-debuginfo qemu-kvm-device-display-virtio-gpu-gl-debuginfo qemu-kvm-device-display-virtio-gpu-pci-debuginfo qemu-kvm-device-display-virtio-gpu-pci-gl-debuginfo qemu-kvm-device-display-virtio-vga-debuginfo qemu-kvm-device-display-virtio-vga-gl-debuginfo qemu-kvm-device-usb-host-debuginfo qemu-kvm-device-usb-redirect-debuginfo qemu-kvm-tests-debuginfo qemu-kvm-tools-debuginfo qemu-kvm-ui-egl-headless-debuginfo qemu-kvm-ui-opengl-debuginfo qemu-guest-agent-debuginfo qemu-img-debuginfo qemu-pr-helper-debuginfo virtiofsd virtiofsd-debuginfo virtiofsd-debugsource virglrenderer virglrenderer-debuginfo virglrenderer-debugsource virglrenderer-devel virglrenderer-test-server virglrenderer-test-server-debuginfo virt-install virt-manager virt-manager-common' | tr ' ' '\n' | while read PKG ; do { rpm --quiet -q $PKG && echo $PKG ; } ; done`)

# The adobe-source-code-pro-fonts package might be required.
# On the target system, run the following command to install the new version of QEMU.
if [ "$REMOVEPKGS" ]; then
printf "%s\n" "install $INSTALLPKGS" "remove $REMOVEPKGS" "run" "clean all" "exit" | sudo dnf shell --assumeyes
else 
printf "%s\n" "install $INSTALLPKGS" "run" "clean all" "exit" | sudo dnf shell --assumeyes
fi

[ ! -f /usr/bin/qemu-kvm ] && [ -f /usr/bin/qemu-system-x86_64 ] && sudo ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-kvm
[ ! -f /usr/libexec/qemu-kvm ] && [ -f /usr/bin/qemu-kvm ] && sudo ln -s /usr/bin/qemu-kvm /usr/libexec/qemu-kvm
