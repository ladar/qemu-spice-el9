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
 texlive-xltxtra texlive-xtab tpm2-pkcs11 tpm2-pkcs11-tools wireshark wireshark-cli \
 doxygen-latex json-c-devel libcmocka trousers trousers-devel \
 trousers-static python3-flake8 python3-mccabe gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu \
 python3-pycodestyle python3-pyflakes clang-devel clang-analyzer nfs-utils virtiofsd \
 iscsi-initiator-utils lzop swtpm-tools systemd-container mdevctl nethogs kf5-kwallet-devel \
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
 ntfs-3g ntfsprogs ntfs-3g-system-compression ntfs-3g-libs which zerofree hexedit perl-JSON || exit 1

# Packages needed to enable X11 forwarding support along with some graphical tools
# which are helpful when we need to troubleshoot. 
dnf --quiet --assumeyes --enablerepo=baseos --enablerepo=appstream --enablerepo=epel \
--enablerepo=extras --enablerepo=plus --enablerepo=crb --exclude=minizip1.2 \
--exclude=minizip1.2-devel install \
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
 gedit-plugin-editorconfig libgit2 python3-editorconfig meld || exit 1

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
dnf download --quiet --disablerepo=* --repofrompath="fc36,https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/36/Everything/source/tree" --repofrompath="fc36-updates,https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/36/Everything/source/tree" --source phodav spice-gtk libguestfs guestfs-tools || exit 1
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
index 359e6a8..ab5848f 100644
--- a/libguestfs.spec
+++ b/libguestfs.spec
@@ -117,10 +117,8 @@ BuildRequires: rpm-devel
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
@@ -130,9 +128,7 @@ BuildRequires: perl(Expect)
 %endif
 BuildRequires: libacl-devel
 BuildRequires: libcap-devel
-%if !0%{?rhel}
 BuildRequires: libldm-devel
-%endif
 BuildRequires: jansson-devel
 BuildRequires: systemd-devel
 BuildRequires: bash-completion
@@ -173,14 +169,10 @@ BuildRequires: rubygem(json)
 BuildRequires: rubygem(rdoc)
 BuildRequires: rubygem(test-unit)
 BuildRequires: ruby-irb
-%if !0%{?rhel}
 BuildRequires: php-devel
-%endif
 BuildRequires: gobject-introspection-devel
 BuildRequires: gjs
-%if !0%{?rhel}
 BuildRequires: vala
-%endif
 %ifarch %{golang_arches}
 BuildRequires: golang
 %endif
@@ -204,10 +196,8 @@ BuildRequires: bzip2
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
@@ -221,24 +211,18 @@ BuildRequires: gfs2-utils
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
@@ -246,9 +230,7 @@ BuildRequires: lsscsi
 BuildRequires: lvm2
 BuildRequires: lzop
 BuildRequires: mdadm
-%if !0%{?rhel}
 BuildRequires: ntfs-3g ntfsprogs ntfs-3g-system-compression
-%endif
 BuildRequires: openssh-clients
 BuildRequires: parted
 BuildRequires: pciutils
@@ -274,15 +256,11 @@ BuildRequires: tar
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
@@ -321,15 +299,13 @@ Requires:      tar
 
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
@@ -355,7 +331,6 @@ Conflicts:     libguestfs-winsupport
 Conflicts:     libguestfs-winsupport < 7.2
 %endif
 
-
 %description
 Libguestfs is a library for accessing and modifying virtual machine
 disk images.  http://libguestfs.org
@@ -370,14 +345,12 @@ For enhanced features, install:
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
@@ -396,14 +369,10 @@ Language bindings:
               lua-guestfs  Lua bindings
    ocaml-libguestfs-devel  OCaml bindings
          perl-Sys-Guestfs  Perl bindings
-%if !0%{?rhel}
            php-libguestfs  PHP bindings
-%endif
        python3-libguestfs  Python 3 bindings
           ruby-libguestfs  Ruby bindings
-%if !0%{?rhel}
           libguestfs-vala  Vala language bindings
-%endif
 
 
 %package appliance
@@ -465,7 +434,6 @@ disk images containing GFS2.
 %endif
 
 
-%if !0%{?rhel}
 %ifnarch ppc
 %package hfsplus
 Summary:       HFS+ support for %{name}
@@ -476,7 +444,6 @@ Requires:      %{name}%{?_isa} = %{epoch}:%{version}-%{release}
 This adds HFS+ support to %{name}.  Install it if you want to process
 disk images containing HFS+ / Mac OS Extended filesystems.
 %endif
-%endif
 
 
 %package rescue
@@ -499,7 +466,6 @@ This adds rsync support to %{name}.  Install it if you want to use
 rsync to upload or download files into disk images.
 
 
-%if !0%{?rhel}
 %package ufs
 Summary:       UFS (BSD) support for %{name}
 License:       LGPLv2+
@@ -508,7 +474,6 @@ Requires:      %{name}%{?_isa} = %{epoch}:%{version}-%{release}
 %description ufs
 This adds UFS support to %{name}.  Install it if you want to process
 disk images containing UFS (BSD filesystems).
-%endif
 
 
 %package xfs
@@ -619,7 +584,6 @@ Provides:      ruby(guestfs) = %{version}
 ruby-%{name} contains Ruby bindings for %{name}.
 
 
-%if !0%{?rhel}
 %package -n php-%{name}
 Summary:       PHP bindings for %{name}
 Requires:      %{name}%{?_isa} = %{epoch}:%{version}-%{release}
@@ -628,7 +592,6 @@ Requires: php(api) = %{php_core_api}
 
 %description -n php-%{name}
 php-%{name} contains PHP bindings for %{name}.
-%endif
 
 
 %package -n lua-guestfs
@@ -662,7 +625,6 @@ This package is needed if you want to write software using the
 GObject bindings.  It also contains GObject Introspection information.
 
 
-%if !0%{?rhel}
 %package vala
 Summary:       Vala for %{name}
 Requires:      %{name}-devel%{?_isa} = %{epoch}:%{version}-%{release}
@@ -671,7 +633,6 @@ Requires:      vala
 
 %description vala
 %{name}-vala contains GObject bindings for %{name}.
-%endif
 
 
 
@@ -751,9 +712,6 @@ else
 fi
 
 %{configure} \\
-%if 0%{?rhel} && !0%{?eln}
-  QEMU=%{_libexecdir}/qemu-kvm \\
-%endif
   PYTHON=%{__python3} \\
   --with-default-backend=libvirt \\
   --enable-appliance-format-auto \\
@@ -762,10 +720,6 @@ fi
 %else
   --with-extra="rhel=%{rhel},release=%{release},libvirt" \\
 %endif
-%if 0%{?rhel} && !0%{?eln}
-  --with-qemu="qemu-kvm qemu-system-%{_build_arch} qemu" \\
-  --disable-php \\
-%endif
 %ifnarch %{golang_arches}
   --disable-golang \\
 %endif
@@ -837,28 +791,19 @@ function move_to
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
@@ -875,11 +820,9 @@ move_to zfs-fuse        zz-packages-zfs
 remove zfs-fuse
 %endif
 
-%if !0%{?rhel}
 # On Fedora you need kernel-modules-extra to be able to mount
 # UFS (BSD) filesystems.
 echo "kernel-modules-extra" > zz-packages-ufs
-%endif
 
 popd
 
@@ -973,12 +916,10 @@ rm ocaml/html/.gitignore
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
@@ -988,10 +929,8 @@ rm ocaml/html/.gitignore
 %{_bindir}/virt-rescue
 %{_mandir}/man1/virt-rescue.1*
 
-%if !0%{?rhel}
 %files ufs
 %{_libdir}/guestfs/supermin.d/zz-packages-ufs
-%endif
 
 %files xfs
 %{_libdir}/guestfs/supermin.d/zz-packages-xfs
@@ -1063,13 +1002,11 @@ rm ocaml/html/.gitignore
 %{_mandir}/man3/guestfs-ruby.3*
 
 
-%if !0%{?rhel}
 %files -n php-%{name}
 %doc php/README-PHP
 %dir %{_sysconfdir}/php.d
 %{_sysconfdir}/php.d/guestfs_php.ini
 %{_libdir}/php/modules/guestfs_php.so
-%endif
 
 
 %files -n lua-guestfs
@@ -1094,11 +1031,9 @@ rm ocaml/html/.gitignore
 %{_mandir}/man3/guestfs-gobject.3*
 
 
-%if !0%{?rhel}
 %files vala
 %{_datadir}/vala/vapi/libguestfs-gobject-1.0.deps
 %{_datadir}/vala/vapi/libguestfs-gobject-1.0.vapi
-%endif
 
 
 %ifarch %{golang_arches}
@@ -4978,3 +4913,4 @@ rm ocaml/html/.gitignore
 
 * Sat Apr  4 2009 Richard Jones <rjones@redhat.com> - 0.9.9-1
 - Initial build.
+
PATCH

patch -p1 <<-PATCH
diff --git a/qemu.spec b/qemu.spec
index 0472a1b..2f41096 100644
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
@@ -75,7 +77,7 @@
 %global have_spice 0
 %endif
 %if 0%{?rhel} >= 9
-%global have_spice 0
+%global have_spice 1
 %endif
 
 # Matches xen ExclusiveArch
@@ -87,14 +89,14 @@
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
 
@@ -114,13 +116,10 @@
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
@@ -157,7 +156,7 @@
 
 %define have_libcacard 1
 %if 0%{?rhel} >= 9
-%define have_libcacard 0
+%define have_libcacard 1
 %endif
 
 # LTO still has issues with qemu on armv7hl and aarch64
@@ -202,7 +201,6 @@
 %define requires_audio_alsa Requires: %{name}-audio-alsa = %{evr}
 %define requires_audio_oss Requires: %{name}-audio-oss = %{evr}
 %define requires_audio_pa Requires: %{name}-audio-pa = %{evr}
-%define requires_audio_pipewire Requires: %{name}-audio-pipewire = %{evr}
 %define requires_audio_sdl Requires: %{name}-audio-sdl = %{evr}
 %define requires_char_baum Requires: %{name}-char-baum = %{evr}
 %define requires_device_usb_host Requires: %{name}-device-usb-host = %{evr}
@@ -288,7 +286,6 @@
 %{requires_audio_dbus} \\
 %{requires_audio_oss} \\
 %{requires_audio_pa} \\
-%{requires_audio_pipewire} \\
 %{requires_audio_sdl} \\
 %{requires_audio_jack} \\
 %{requires_audio_spice} \\
@@ -343,7 +340,7 @@ Summary: QEMU is a FAST! processor emulator
 Name: qemu
 Version: 8.1.0
 Release: %{baserelease}%{?rcrel}%{?dist}
-Epoch: 2
+Epoch: 1024
 License: Apache-2.0 AND BSD-2-Clause AND BSD-3-Clause AND FSFAP AND GPL-1.0-or-later AND GPL-2.0-only AND GPL-2.0-or-later AND GPL-2.0-or-later with GCC-exception-2.0 exception AND LGPL-2.0-only AND LGPL-2.0-or-later AND LGPL-2.1-only and LGPL-2.1-or-later AND MIT and public-domain and CC-BY-3.0
 URL: http://www.qemu.org/
 
@@ -361,6 +358,7 @@ Source31: kvm-x86.conf
 Source36: README.tests
 
 Patch0001: 0001-tests-Disable-iotests-like-RHEL-does.patch
+#Patch0005: 0005-Enable-disable-devices-for-RHEL.patch
 
 BuildRequires: meson >= %{meson_version}
 BuildRequires: bison
@@ -515,16 +513,11 @@ BuildRequires: SDL2_image-devel
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
@@ -755,12 +748,6 @@ Requires: %{name}-common%{?_isa} = %{epoch}:%{version}-%{release}
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
@@ -1514,7 +1501,6 @@ mkdir -p %{static_builddir}
   --disable-linux-user             \\\\\\
   --disable-live-block-migration   \\\\\\
   --disable-lto                    \\\\\\
-  --disable-lzfse                  \\\\\\
   --disable-lzo                    \\\\\\
   --disable-malloc-trim            \\\\\\
   --disable-membarrier             \\\\\\
@@ -1693,7 +1679,6 @@ run_configure \\
   --enable-oss \\
   --enable-pa \\
   --enable-pie \\
-  --enable-pipewire \\
 %if %{have_block_rbd}
   --enable-rbd \\
 %endif
@@ -1726,7 +1711,7 @@ run_configure \\
   --enable-xkbcommon \\
   \\
   \\
-  --audio-drv-list=pipewire,pa,sdl,alsa,%{?jack_drv}oss \\
+  --audio-drv-list=pa,sdl,alsa,%{?jack_drv}oss \\
   --target-list-exclude=moxie-softmmu \\
   --with-default-devices \\
   --enable-auth-pam \\
@@ -1737,6 +1722,7 @@ run_configure \\
   --enable-curses \\
   --enable-dmg \\
   --enable-fuse \\
+  --enable-fuse-lseek \\
   --enable-gio \\
 %if %{have_block_gluster}
   --enable-glusterfs \\
@@ -1751,7 +1737,6 @@ run_configure \\
   --enable-linux-io-uring \\
 %endif
   --enable-linux-user \\
-  --enable-live-block-migration \\
   --enable-multiprocess \\
   --enable-parallels \\
 %if %{have_librdma}
@@ -1760,7 +1745,6 @@ run_configure \\
   --enable-qcow1 \\
   --enable-qed \\
   --enable-qom-cast-debug \\
-  --enable-replication \\
   --enable-sdl \\
 %if %{have_sdl_image}
   --enable-sdl-image \\
@@ -1768,6 +1752,7 @@ run_configure \\
 %if %{have_libcacard}
   --enable-smartcard \\
 %endif
+  --enable-sparse \\
 %if %{have_spice}
   --enable-spice \\
   --enable-spice-protocol \\
@@ -1811,8 +1796,12 @@ run_configure \\
 
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
@@ -1884,6 +1873,8 @@ install -D -p -m 644 %{_sourcedir}/95-kvm-memlock.conf %{buildroot}%{_sysconfdir
 %if %{have_kvm}
 install -D -p -m 0644 %{_sourcedir}/vhost.conf %{buildroot}%{_sysconfdir}/modprobe.d/vhost.conf
 install -D -p -m 0644 %{modprobe_kvm_conf} %{buildroot}%{_sysconfdir}/modprobe.d/kvm.conf
+install -D -p -m 0755 %{qemu_kvm_build}/%{kvm_target}-softmmu/qemu-system-%{kvm_target} %{buildroot}%{_libexecdir}/qemu-kvm
+
 %endif
 
 # Copy some static data into place
@@ -2281,6 +2272,7 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 
 %files block-dmg
 %{_libdir}/%{name}/block-dmg-bz2.so
+%{_libdir}/%{name}/block-dmg-lzfse.so
 %if %{have_block_gluster}
 %files block-gluster
 %{_libdir}/%{name}/block-gluster.so
@@ -2300,8 +2292,6 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
 %{_libdir}/%{name}/audio-oss.so
 %files audio-pa
 %{_libdir}/%{name}/audio-pa.so
-%files audio-pipewire
-%{_libdir}/%{name}/audio-pipewire.so
 %files audio-sdl
 %{_libdir}/%{name}/audio-sdl.so
 %if %{have_jack}
@@ -2380,7 +2370,12 @@ useradd -r -u 107 -g qemu -G kvm -d / -s /sbin/nologin \\
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

# Some changes are just easier with sed.
sed -i 's/defined rhel/defined nullified/g' edk2.spec
sed -i 's/defined fedora/defined rhel/g' edk2.spec
sed -i 's/\.\/edk2\-build\.py \-\-config/.\/edk2-build.py --jobs 6 --config/g' edk2.spec 

sed -i "s/^Version:\([\t ]*\).*/Version:\1$(date +%Y%m%d)/g" passt.spec 

# Use a release string of 1024 so the virt-manager rebuild will be seen as an upgrade.
sed -E -i 's/^Release\: .\%\{\?dist\}/Release: 1024\%\{\?dist\}/g' virt-manager.spec

sed -E -i 's/^Epoch:(\W*) [0-9]*/Epoch:\1 1024/g' libguestfs.spec 
sed -E -i 's/^Release\:(\W*) .\%\{\?dist\}/Release:\1 1024\%\{\?dist\}/g' libguestfs.spec
sed -E -i 's/^Release\:(\W*) .\%\{\?dist\}/Release:\1 1024\%\{\?dist\}/g' guestfs-tools.spec

## Check whether all of the build dependencies, available in the distro 
## repositories, are installed. Note that some build dependencies may be 
## replaced during the build process below.
## dnf builddep --spec  --enablerepo=* *.spec


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




# The qemu.spec patch is updating the jobs, but we might switch back to using this in the future.
# JOBS="$(($(lscpu -e=core | grep -v CORE | sort | uniq | wc -l)+2))"
# sed -i "s/%make_build/%make_build -j$JOBS/g" qemu.spec
# unset JOBS

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) qemu.spec 2>&1 | tee qemu.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{PROVIDES}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " qemu.spec ) || \
{ printf "\n\e[1;91m# The qemu rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The qemu rpmbuild finished.\e[0;0m\n"

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

rpmbuild -ba --rebuild --undefine="dist" -D "dist .btrh9" --target=$(uname -m) libvirt-designer.spec 2>&1 | tee libvirt-designer.log > /dev/null && \
rpm -i -U --replacepkgs --replacefiles $(rpmspec -q --undefine="dist" -D "dist .btrh9" --queryformat="$HOME/rpmbuild/RPMS/%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm " libvirt-designer.spec ) || \
{ printf "\n\e[1;91m# The libvirt-designer rpmbuild failed.\e[0;0m\n\n" ; exit 1 ; }
printf "\e[1;92m# The libvirt-designer rpmbuild finished.\e[0;0m\n"

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




# Download various dependencies needed for installation. We add them to the repo as RPMs if 
# they aren't available from the official, and/or, EPEL repos.

# SDL2
dnf --quiet --enablerepo=remi --enablerepo=remi-debuginfo --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download SDL2_image SDL2_image-debuginfo SDL2_image-devel SDL2_image-debugsource

# pcsc-lite
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download pcsc-lite pcsc-lite-debuginfo pcsc-lite-debugsource pcsc-lite-devel pcsc-lite-devel-debuginfo pcsc-lite-libs pcsc-lite-libs-debuginfo pcsc-lite-ccid pcsc-lite-ccid-debuginfo pcsc-lite-ccid-debugsource

# mesa-libgbm
# dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download mesa-libgbm mesa-libgbm-devel mesa-libgbm-debuginfo

# usbredir
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download usbredir usbredir-devel usbredir-debuginfo usbredir-debugsource

# opus
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download opus opus-devel opus-debuginfo opus-debugsource

# gobject-introspection
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download gobject-introspection gobject-introspection-devel gobject-introspection-debuginfo gobject-introspection-debugsource

# libogg
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download libogg libogg-devel libogg-debuginfo libogg-debugsource

# capstone
dnf --quiet --enablerepo=appstream --enablerepo=appstream-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download capstone capstone-devel capstone-debuginfo capstone-debugsource python3-capstone python3-capstone-debuginfo

# python3-markdown
dnf --quiet --enablerepo=crb --enablerepo=crb-debuginfo --arch=noarch --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/noarch/ download python3-markdown

# vala
dnf --quiet --enablerepo=baseos --enablerepo=baseos-debug --enablerepo=crb --enablerepo=crb-debuginfo --arch=x86_64 --urlprotocol=https --downloaddir=$HOME/rpmbuild/RPMS/x86_64/ download vala libvala libvala-devel vala-debuginfo vala-debugsource valadoc-debuginfo libvala-debuginfo

# Consolidate the RPMs.
mkdir $HOME/RPMS/
find $HOME/rpmbuild/RPMS/noarch/*rpm $HOME/rpmbuild/RPMS/x86_64/*rpm $HOME/rpmbuild/SRPMS/*btrh*rpm > $HOME/rpm.outputs.txt
mv $HOME/rpmbuild/RPMS/noarch/*rpm $HOME/rpmbuild/RPMS/x86_64/*rpm $HOME/rpmbuild/SRPMS/*btrh*rpm $HOME/RPMS/

cd $HOME/RPMS/

curl -LOs https://archive.org/download/libblkio-eln125/libblkio-1.2.2-2.eln125.x86_64.rpm
curl -LOs https://archive.org/download/libblkio-eln125/libblkio-devel-1.2.2-2.eln125.x86_64.rpm

sha256sum -c <<-EOF || { printf "\n\e[1;91m# The libblkio download failed.\e[0;0m\n\n" ; exit 1 ; }
637892248b0875e1b2ca2e14039ca20fa1a7d91f765385040f58e8487dca83ad  libblkio-1.2.2-2.eln125.x86_64.rpm
6f0ab5cf409c448b32ee9bdf6875d2e8c7557475dc294edf80fbcc478516c25e  libblkio-devel-1.2.2-2.eln125.x86_64.rpm
EOF

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
# sudo dnf install \`ls *rpm | grep -Ev "\\.src\\.|debuginfo|debugsource|devel|ocaml|vala"\` \`ls libguestfs-devel*rpm libvirt-gobject-devel*rpm libvirt-gconfig-devel*rpm libvirt-glib-devel*rpm  libvirt-devel*rpm libvirt-designer-devel*rpm libguestfs-gobject-devel*rpm gobject-introspection-devel*rpm pcre2-devel*rpm libosinfo-devel*rpm\`


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

# Install the basic qemu/libvirt/virt-manager/spice packages.
export INSTALLPKGS=\$(echo \`ls qemu*rpm spice*rpm opus*rpm usbredir*rpm openbios*rpm capstone*rpm python3-capstone*rpm libblkio*rpm lzfse*rpm virglrenderer*rpm libcacard*rpm edk2*rpm SLOF*rpm SDL2*rpm libogg-devel*rpm pcsc-lite*rpm mesa-libgbm-devel*rpm usbredir-devel*rpm opus-devel*rpm gobject-introspection-devel*rpm python3-markdown*rpm virt-manager*rpm virt-viewer*rpm virt-install*rpm virt-backup*rpm passt*rpm libphodav*rpm gvnc*rpm gtk-vnc*rpm chunkfs*rpm osinfo*rpm libosinfo*rpm libvirt*rpm python3-libvirt*rpm chezdav*rpm fcode-utils*rpm python3-pefile*rpm python3-virt-firmware*rpm libguestfs*rpm python3-libguestfs*rpm guestfs-tools*rpm vala*rpm libvala*rpm | grep -Ev 'qemu-guest-agent|qemu-tests|debuginfo|debugsource|\\.src\\.rpm' ; echo vala\`)

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
dnf --quiet --assumeyes remove edk2* lzfse* mesa* openbios* pcsc* qemu* SDL2* SLOF* spice* virglrenderer* virtiofsd* $(rpm -qa | grep btrh)
dnf --quiet --enablerepo=* clean all
dnf --quiet --assumeyes install qemu* libvirt* virt* 
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

printf "\n\nAll done.\n\n"
