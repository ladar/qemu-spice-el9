
# QEMU with SPICE support for Alma / Rocky / Oracle / RHEL 9 (aka el9)

The official virtualization packages for RHEL 9 lack support for hardware acceleration, and this made my graphical development environments unusuable. As a result, my choices were rebuild the packages with SPICE support, or switch to a commercial/proprietary alternative. Ultimately I've decided to rebuild the packages with SPICE support.  

Use the `INSTALL.sh` script to replace the default packages with the RPMs in this repository. If you would like to build the packages yourself, you can use the `BUILD.sh` script. These RPMS were built using equivalent Alma and Fedora source packages, which is why some versions are newer than what is shipped with RHEL. As such a handful of additional features are enabled in addition to SPICE support. 

To quickly download and installthese packages without using the `INSTALL.sh` script:

```bash
git clone --depth=1 https://github.com/ladar/qemu-spice-el9.git && cd qemu-spice-el9
export PACKAGES="$(ls *rpm depends/libblkio*rpm | grep -Ev '\.src\.|debug|ocaml|vala|uki\-direct|xorg\-x11\-drv')"
sudo dnf install --enablerepo=baseos --enablerepo=appstream --enablerepo=epel --enablerepo=crb $PACKAGES
```

The `edk2-*.btrh9.src.rpm`, `qemu-*.btrh9.src.rpm` and `qemu-user-debuginfo-*.btrh9.x86_64.rpm` packages exceed the repo size limit. As a result, these packages have been split into eight files. Use the following commands to split/reassemble the original RPM files.

```bash
# The packages were split using these commands.
export EDKRPM="$(ls edk2-*.btrh9.src.rpm)" && \
export QEMURPM="$(ls qemu-*.btrh9.src.rpm)" && \
export QEMUDEBUGRPM="$(ls qemu-user-debuginfo-*.btrh9.x86_64.rpm)" && \
split --numeric-suffixes=01 --number=8 $EDKRPM $EDKRPM. && \
split --numeric-suffixes=01 --number=8 $QEMURPM $QEMURPM. && \
split --numeric-suffixes=01 --number=8 $QEMUDEBUGRPM $QEMUDEBUGRPM.

# To recombine them.
export EDKRPM="$(ls edk2-*.btrh9.src.rpm.01 | sed 's/.01$//g')"
export QEMURPM="$(ls qemu-*.btrh9.src.rpm.01 | sed 's/.01$//g')"
export QEMUDEBUGRPM="$(ls qemu-user-debuginfo-*.btrh9.x86_64.rpm.01 | sed 's/.01$//g')"
export EDKFILES="$(ls edk2-*.btrh9.src.rpm.0[1-8])"
export QEMUFILES="$(ls qemu-*.btrh9.src.rpm.0[1-8])"
export QEMUDEBUGFILES="$(ls qemu-user-debuginfo-*.btrh9.x86_64.rpm.0[1-8])"
cat $EDKFILES > $EDKRPM=
cat $QEMUFILES > $QEMURPM
cat $QEMUDEBUGFILES > $QEMUDEBUGRPM
sha256sum --quiet -c SHA256SUMS
```

Since these packages won't be needed in most cases, I felt this was better than using LFS.

