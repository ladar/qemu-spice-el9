
# QEMU with SPICE support for Alma / Rocky / Oracle / RHEL 9 (aka el9)

The official virtualization packages for RHEL 9 lack support for hardware acceleration, and the drop in performance made my development environments unusuable. As a result my choices were rebuild the packages with SPICE support, or switch to a commercial/proprietary alternative. Ultimately I decided to rebuild the packages myself. 

Use the `INSTALL.sh` script to replace the default packages with the ones in this repository. If you would like to build the packages yourself, you can use the `BUILD.sh` script. These RPMS were built using the equivalent Fedora source package, which is why the version is newer than what is shipped with RHEL (where applicable).

To the best of my knowledge, all of the features available on Fedora are included with these packages, with the exception of webdav support. 

Note, the `qemu-7.1.0-3.btrh9.src.rpm` and the `qemu-user-debuginfo-7.1.0-3.btrh9.x86_64.rpm` exceeded the 100 MiB limit. As a result, those packages have been split into two files.

```bash
# The packages were split using these commands.
split --numeric-suffixes=01 --number=2 qemu-7.1.0-3.btrh9.src.rpm qemu-7.1.0-3.btrh9.src.rpm.
split --numeric-suffixes=01 --number=2 qemu-user-debuginfo-7.1.0-3.btrh9.x86_64.rpm qemu-user-debuginfo-7.1.0-3.btrh9.x86_64.rpm.

# To recombine them.
cat qemu-7.1.0-3.btrh9.src.rpm.01 qemu-7.1.0-3.btrh9.src.rpm.02 > qemu-7.1.0-3.btrh9.src.rpm
cat qemu-user-debuginfo-7.1.0-3.btrh9.x86_64.rpm.01 qemu-user-debuginfo-7.1.0-3.btrh9.x86_64.rpm.02 > qemu-user-debuginfo-7.1.0-3.btrh9.x86_64.rpm
```

Since these packages won't be needed in most cases, I felt this was better than using LFS.

