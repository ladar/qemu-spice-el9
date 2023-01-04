
# QEMU with SPICE support for Alma / Rocky / Oracle / RHEL 9 (aka el9)

The official virtualization packages for RHEL 9 lack support for hardware acceleration, and the drop in performance made my development environments unusuable. As a result my choices were rebuild the packages with SPICE support, or switch to a commercial/proprietary alternative. Ultimately I decided to rebuild the packages myself. 

Use the `INSTALL.sh` script to replace the default packages with the ones in this repository. If you would like to build the packages yourself, you can use the `BUILD.sh` script. These RPMS were built using the equivalent Fedora source package, which is why the version is newer than what is shipped with RHEL (where applicable).

To the best of my knowledge, all of the features available on Fedora are included with these packages, with the exception of webdav support. 

Note, the `qemu-*.btrh9.src.rpm` and the `qemu-user-debuginfo-*.btrh9.x86_64.rpm` exceeded the 100 MiB limit. As a result, those packages have been split into four files. Use the following commands to split/reassemble the original RPM files.

```bash
# The packages were split using these commands.
export QEMURPM="`ls qemu-*.btrh9.src.rpm`" && \
export QEMUDEBUGRPM="`ls qemu-user-debuginfo-*.btrh9.x86_64.rpm`" && \
split --numeric-suffixes=01 --number=4 $QEMURPM $QEMURPM. && \
split --numeric-suffixes=01 --number=4 $QEMUDEBUGRPM $QEMUDEBUGRPM.

# To recombine them.
cat qemu-*.btrh9.src.rpm.{01,02,03,04} > qemu-7.1.0-3.btrh9.src.rpm
cat qemu-user-debuginfo-*.btrh9.x86_64.rpm.{01,02,03,04} > qemu-user-debuginfo-7.1.0-3.btrh9.x86_64.rpm
```

Since these packages won't be needed in most cases, I felt this was better than using LFS.

