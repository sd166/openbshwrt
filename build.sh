#!/bin/sh
#
# Copyright (C) 2025 Dyadev (Sergey Dyadev) <sdyadev@bsh.ru> for OpenBSHWrt project
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

set -e

umask 0022
unset GREP_OPTIONS SED

_get_repo() (
	mkdir -p "$1"
	cd "$1"
	[ -d .git ] || git init
	if git remote get-url origin >/dev/null 2>/dev/null; then
		git remote set-url origin "$2"
	else
		git remote add origin "$2"
	fi
	git fetch origin -f
	git fetch origin --tags -f
	git checkout -f "origin/$3" -B "build" 2>/dev/null || git checkout "$3" -B "build"
)

OBW_DIST=${OBW_DIST:-openbshwrt}
OBW_HOST=${OBW_HOST:-$(curl -sS ifconfig.co)}
OBW_PORT=${OBW_PORT:-80}
OBW_KEEPBIN=${OBW_KEEPBIN:-no}
OBW_IMG=${OBW_IMG:-yes}
#OBW_UEFI=${OBW_UEFI:-yes}
OBW_PACKAGES=${OBW_PACKAGES:-full}
OBW_ALL_PACKAGES=${OBW_ALL_PACKAGES:-no}
OBW_TARGET=${OBW_TARGET:-x86_64}
OBW_TARGET_CONFIG="config-$OBW_TARGET"
UPSTREAM=${UPSTREAM:-no}
SYSLOG=${SYSLOG:-busybox-syslogd}
#SYSLOG=${SYSLOG:-syslog-ng}
OBW_KERNEL=${OBW_KERNEL:-5.4}
SHORTCUT_FE=${SHORTCUT_FE:-no}
DISABLE_FAILSAFE=${DISABLE_FAILSAFE:-no}

OBW_RELEASE=${OBW_RELEASE:-$(git describe --tags `git rev-list --tags --max-count=1` | tail -1)}
OBW_REPO=${OBW_REPO:-http://$OBW_HOST:$OBW_PORT/release/$OBW_RELEASE-$OBW_KERNEL/$OBW_TARGET}

OBW_FEED_URL="${OBW_FEED_URL:-https://github.com/ysurac/openmptcprouter-feeds}"
OBW_FEED_SRC="${OBW_FEED_SRC:-develop}"

CUSTOM_FEED_URL="${CUSTOM_FEED_URL}"
CUSTOM_FEED_URL_BRANCH="${CUSTOM_FEED_URL_BRANCH:-main}"

OBW_OPENWRT=${OBW_OPENWRT:-default}
OBW_OPENWRT_GIT=${OBW_OPENWRT_GIT:-https://github.com}
OBW_FORCE_DSA=${OBW_FORCE_DSA:-0}


if [ ! -f "$OBW_TARGET_CONFIG" ]; then
	echo "Target $OBW_TARGET not found !"
	#exit 1
fi


if [ "$OBW_TARGET" = "x86" ]; then
	OBW_REAL_TARGET="i386_pentium4"
else
	OBW_REAL_TARGET=${OBW_TARGET}
fi

if [ "$ONLY_PREPARE" != "yes" ]; then
	if [ "$OBW_OPENWRT" = "default" ]; then
		if [ "$OBW_KERNEL" = "6.6" ] || [ "$OBW_KERNEL" = "6.10" ] || [ "$OBW_KERNEL" = "6.11" ]; then
			# Use OpenWRT 24.10 for 6.6 kernel
			_get_repo "$OBW_TARGET/${OBW_KERNEL}/source" ${OBW_OPENWRT_GIT}/openwrt/openwrt "ad98c322cc50e4b2819dc195cb195b0e3daf9d5a"
			_get_repo feeds/${OBW_KERNEL}/packages ${OBW_OPENWRT_GIT}/openwrt/packages "212eb308f108b2460909b3cd25d68374913b266f"
			_get_repo feeds/${OBW_KERNEL}/luci ${OBW_OPENWRT_GIT}/openwrt/luci "36b610767adf7172f87e89e02edc1a91af1fcb45"
			_get_repo feeds/${OBW_KERNEL}/routing ${OBW_OPENWRT_GIT}/openwrt/routing "e87b55c6a642947ad7e24cd5054a637df63d5dbe"
		elif [ "$OBW_KERNEL" = "6.12" ]; then
			_get_repo "$OBW_TARGET/${OBW_KERNEL}/source" ${OBW_OPENWRT_GIT}/openwrt/openwrt "0a7c8ed9d94930ba062c71df79f63c06eeab4543"
			_get_repo feeds/${OBW_KERNEL}/packages ${OBW_OPENWRT_GIT}/openwrt/packages "b939b3e79392835b1c20865e61add02e8d9f2054"
			_get_repo feeds/${OBW_KERNEL}/luci ${OBW_OPENWRT_GIT}/openwrt/luci "370e2479a77ffc35f095850cd56e3d6b866e990b"
			_get_repo feeds/${OBW_KERNEL}/routing ${OBW_OPENWRT_GIT}/openwrt/routing "4a65e359c301d30b70e448e8c25c6edc9c909be5"
		fi
	elif [ "$OBW_OPENWRT" = "coolsnowwolfmix" ]; then
		_get_repo "$OBW_TARGET/${OBW_KERNEL}/source" ${OBW_OPENWRT_GIT}/coolsnowwolf/lede.git "master"
		_get_repo feeds/${OBW_KERNEL}/packages ${OBW_OPENWRT_GIT}/openwrt/packages "master"
		_get_repo feeds/${OBW_KERNEL}/luci ${OBW_OPENWRT_GIT}/openwrt/luci "master"
	elif [ "$OBW_OPENWRT" = "coolsnowwolf" ]; then
		_get_repo "$OBW_TARGET/${OBW_KERNEL}/source" ${OBW_OPENWRT_GIT}/coolsnowwolf/lede.git "master"
		_get_repo feeds/${OBW_KERNEL}/packages ${OBW_OPENWRT_GIT}/coolsnowwolf/packages "master"
		_get_repo feeds/${OBW_KERNEL}/luci ${OBW_OPENWRT_GIT}/coolsnowwolf/luci "master"
	elif [ "$OBW_OPENWRT" = "master" ]; then
		_get_repo "$OBW_TARGET/${OBW_KERNEL}/source" ${OBW_OPENWRT_GIT}/openwrt/openwrt "main"
		_get_repo feeds/${OBW_KERNEL}/packages ${OBW_OPENWRT_GIT}/openwrt/packages "main"
		_get_repo feeds/${OBW_KERNEL}/luci ${OBW_OPENWRT_GIT}/openwrt/luci "main"
		_get_repo feeds/${OBW_KERNEL}/luci ${OBW_OPENWRT_GIT}/openwrt/routing "main"
	else
		_get_repo "$OBW_TARGET/${OBW_KERNEL}/source" ${OBW_OPENWRT_GIT}/openwrt/openwrt "${OBW_OPENWRT}"
		_get_repo feeds/${OBW_KERNEL}/packages ${OBW_OPENWRT_GIT}/openwrt/packages "${OBW_OPENWRT}"
		_get_repo feeds/${OBW_KERNEL}/luci ${OBW_OPENWRT_GIT}/openwrt/luci "${OBW_OPENWRT}"
		_get_repo feeds/${OBW_KERNEL}/luci ${OBW_OPENWRT_GIT}/openwrt/routing "${OBW_OPENWRT}"
	fi
fi

if [ -z "$OBW_FEED" ]; then
	OBW_FEED=feeds/openbshwrt
	[ "$ONLY_PREPARE" != "yes" ] && _get_repo "$OBW_FEED" "$OBW_FEED_URL" "$OBW_FEED_SRC"
fi

if [ -n "$CUSTOM_FEED_URL" ] && [ -z "$CUSTOM_FEED" ]; then
	CUSTOM_FEED=feeds/${OBW_KERNEL}/${OBW_DIST}
	[ "$ONLY_PREPARE" != "yes" ] && _get_repo "$CUSTOM_FEED" "$CUSTOM_FEED_URL" "$CUSTOM_FEED_URL_BRANCH"
fi

if [ -n "$1" ] && [ -f "$OBW_FEED/$1/Makefile" ]; then
	OBW_DIST=$1
	shift 1
fi

if [ "$OBW_KEEPBIN" = "no" ]; then 
	rm -rf "$OBW_TARGET/${OBW_KERNEL}/source/bin"
fi
if [ "$ONLY_GET_REPO" = "yes" ]; then
	exit 0
fi
rm -rf "$OBW_TARGET/${OBW_KERNEL}/source/files" "$OBW_TARGET/${OBW_KERNEL}/source/tmp"

echo "rm -rf $OBW_TARGET/${OBW_KERNEL}/source/package/boot/uboot-mvebu"
rm -rf "${OBW_TARGET}/${OBW_KERNEL}/source/package/boot/uboot-mvebu"
[ "${OBW_KERNEL}" = "6.6" ] || [ "${OBW_KERNEL}" = "6.10" ] || [ "${OBW_KERNEL}" = "6.11" ] || [ "${OBW_KERNEL}" = "6.12" ] && {
	echo "rm -rf $OBW_TARGET/${OBW_KERNEL}/source/package/boot/uboot-ipq40xx"
	rm -rf "${OBW_TARGET}/${OBW_KERNEL}/source/package/boot/uboot-ipq40xx"
}
[ "${OBW_KERNEL}" = "6.1" ] && {
	rm -rf "${OBW_TARGET}/${OBW_KERNEL}/source/target/linux/bcm27xx/patches-6.1"
}

echo "cp -rf common/* $OBW_TARGET/${OBW_KERNEL}/source"
cp -rf common/* "$OBW_TARGET/${OBW_KERNEL}/source"
echo "cp -rf ${OBW_KERNEL}/* $OBW_TARGET/${OBW_KERNEL}/source"
cp -rf ${OBW_KERNEL}/* "$OBW_TARGET/${OBW_KERNEL}/source"

if [ -n "$CUSTOM_FEED" ] && [ -d ${CUSTOM_FEED}/source/${OBW_TARGET}/${OBW_KERNEL} ]; then
	echo "Copy ${CUSTOM_FEED}/source/${OBW_TARGET}/${OBW_KERNEL}/* to $OBW_TARGET/${OBW_KERNEL}/source"
	cp -rf ${CUSTOM_FEED}/source/${OBW_TARGET}/${OBW_KERNEL}/* "$OBW_TARGET/${OBW_KERNEL}/source"
fi

cat >> "$OBW_TARGET/${OBW_KERNEL}/source/package/base-files/files/etc/banner" <<EOF
-----------------------------------------------------
 PACKAGE:     $OBW_DIST
 VERSION:     $OBW_RELEASE
 TARGET:      $OBW_TARGET
 ARCH:        $OBW_REAL_TARGET

 BUILD REPO:  $(git config --get remote.origin.url)
 BUILD DATE:  $(date -u)
-----------------------------------------------------
EOF

cat > "$OBW_TARGET/${OBW_KERNEL}/source/feeds.conf" <<EOF
src-link packages $(readlink -f feeds/${OBW_KERNEL}/packages)
src-link luci $(readlink -f feeds/${OBW_KERNEL}/luci)
src-link openbshwrt $(readlink -f "$OBW_FEED")
EOF

if [ -n "$CUSTOM_FEED" ]; then
	echo "src-link ${OBW_DIST} $(readlink -f ${CUSTOM_FEED})" >> "$OBW_TARGET/${OBW_KERNEL}/source/feeds.conf"
fi

if [ "$OBW_KERNEL" != "6.12" ]; then
	if [ "$OBW_DIST" = "openbshwrt" ]; then
		cat > "$OBW_TARGET/${OBW_KERNEL}/source/package/system/opkg/files/customfeeds.conf" <<-EOF
		src/gz openwrt_luci http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/luci
		src/gz openwrt_packages http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/packages
		src/gz openwrt_base http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/base
		src/gz openwrt_routing http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/routing
		src/gz openwrt_telephony http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/telephony
		EOF
	elif [ -n "$OBW_PACKAGES_URL" ]; then
		cat > "$OBW_TARGET/${OBW_KERNEL}/source/package/system/opkg/files/customfeeds.conf" <<-EOF
		src/gz openwrt_luci ${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/luci
		src/gz openwrt_packages ${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/packages
		src/gz openwrt_base ${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/base
		src/gz openwrt_routing ${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/routing
		src/gz openwrt_telephony ${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/telephony
		EOF
	else
		# Force use of opkg ipk packages
		cat > "$OBW_TARGET/${OBW_KERNEL}/source/package/system/opkg/files/customfeeds.conf" <<-EOF
		src/gz openwrt_luci http://downloads.openwrt.org/releases/packages-24.10/${OBW_REAL_TARGET}/luci
		src/gz openwrt_packages http://downloads.openwrt.org/releases/packages-24.10/${OBW_REAL_TARGET}/packages
		src/gz openwrt_base http://downloads.openwrt.org/releases/packages-24.10/${OBW_REAL_TARGET}/base
		src/gz openwrt_routing http://downloads.openwrt.org/releases/packages-24.10/${OBW_REAL_TARGET}/routing
		src/gz openwrt_telephony http://downloads.openwrt.org/releases/packages-24.10/${OBW_REAL_TARGET}/telephony
		EOF
	fi
else
	if [ "$OBW_DIST" = "openbshwrt" ]; then
		cat > "$OBW_TARGET/${OBW_KERNEL}/source/package/system/apk/files/customfeeds.list" <<-EOF
		http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/luci/packages.adb
		http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/packages/packages.adb
		http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/base/packages.adb
		http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/routing/packages.adb
		http://packages.openmptcprouter.com/${OBW_RELEASE}/${OBW_REAL_TARGET}/telephony/packages.adb
		EOF
	elif [ -n "$OBW_PACKAGES_URL" ]; then
		cat > "$OBW_TARGET/${OBW_KERNEL}/source/package/system/apk/files/customfeeds.list" <<-EOF
		${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/luci/packages.adb
		${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/packages/packages.adb
		${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/base/packages.adb
		${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/routing/packages.adb
		${OBW_PACKAGES_URL}/${OBW_RELEASE}/${OBW_REAL_TARGET}/telephony/packages.adb
		EOF
	else
		cat > "$OBW_TARGET/${OBW_KERNEL}/source/package/system/apk/files/customfeeds.list" <<-EOF
		http://downloads.openwrt.org/snapshots/packages/${OBW_REAL_TARGET}/luci/packages.adb
		http://downloads.openwrt.org/snapshots/packages/${OBW_REAL_TARGET}/packages/packages.adb
		http://downloads.openwrt.org/snapshots/packages/${OBW_REAL_TARGET}/base/packages.adb
		http://downloads.openwrt.org/snapshots/packages/${OBW_REAL_TARGET}/routing/packages.adb
		http://downloads.openwrt.org/snapshots/packages/${OBW_REAL_TARGET}/telephony/packages.adb
		EOF
	fi

fi

if [ -f $OBW_TARGET_CONFIG ]; then
	cat "$OBW_TARGET_CONFIG" config -> "$OBW_TARGET/${OBW_KERNEL}/source/.config" <<-EOF
	CONFIG_IMAGEOPT=y
	CONFIG_VERSIONOPT=y
	CONFIG_VERSION_DIST="$OBW_DIST"
	CONFIG_VERSION_REPO="$OBW_REPO"
	CONFIG_VERSION_NUMBER="${OBW_RELEASE}-${OBW_KERNEL}"
	EOF
else
	cat config -> "$OBW_TARGET/${OBW_KERNEL}/source/.config" <<-EOF
	CONFIG_IMAGEOPT=y
	CONFIG_VERSIONOPT=y
	CONFIG_VERSION_DIST="$OBW_DIST"
	CONFIG_VERSION_REPO="$OBW_REPO"
	CONFIG_VERSION_NUMBER="${OBW_RELEASE}-${OBW_FEED_SRC}-$(git -C "$OBW_FEED" rev-parse --short HEAD)"
	EOF
fi

if [ "$OBW_ALL_PACKAGES" = "yes" ]; then
	echo 'CONFIG_ALL=y' >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo 'CONFIG_ALL_NONSHARED=y' >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
fi
if [ "$OBW_IMG" = "yes" ] && [ "$OBW_TARGET" = "x86_64" ]; then 
	echo 'CONFIG_VDI_IMAGES=y' >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo 'CONFIG_VMDK_IMAGES=y' >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo 'CONFIG_VHDX_IMAGES=y' >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
fi

if [ "$DISABLE_FAILSAFE" = "yes" ]; then
	rm -f "$OBW_TARGET/${OBW_KERNEL}/source/package/base-files/files/lib/preinit/30_failsafe_wait"
	rm -f "$OBW_TARGET/${OBW_KERNEL}/source/package/base-files/files/lib/preinit/40_run_failsafe_hook"
fi

echo "CONFIG_PACKAGE_${OBW_DIST}-${OBW_PACKAGES}=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"

if [ "$SYSLOG" = "busybox-syslogd" ]; then
	echo "CONFIG_BUSYBOX_CONFIG_FEATURE_SYSLOG=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_BUSYBOX_CONFIG_FEATURE_SYSLOGD_CFG=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_BUSYBOX_CONFIG_FEATURE_SYSLOGD_PRECISE_TIMESTAMP=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_BUSYBOX_CONFIG_FEATURE_SYSLOGD_READ_BUFFER_SIZE=256" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_BUSYBOX_CONFIG_FEATURE_REMOTE_LOG=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_BUSYBOX_CONFIG_SYSLOGD=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_BUSYBOX_CONFIG_LOGREAD=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_PACKAGE_syslogd=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
elif [ "$SYSLOG" = "syslog-ng" ]; then
	echo "CONFIG_PACKAGE_syslog-ng=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
fi

if [ "$SHORTCUT_FE" = "yes" ]; then
	echo "CONFIG_PACKAGE_kmod-fast-classifier=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_PACKAGE_kmod-shortcut-fe=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_PACKAGE_kmod-shortcut-fe-cm=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_PACKAGE_shortcut-fe-drv=y" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
else
	echo "# CONFIG_PACKAGE_kmod-fast-classifier is not set" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "# CONFIG_PACKAGE_kmod-shortcut-fe-cm is not set" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "# CONFIG_PACKAGE_kmod-shortcut-fe is not set" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "# CONFIG_PACKAGE_shortcut-fe is not set" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
fi
if [ "$OBW_KERNEL" != "5.4" ] && [ "$OBW_TARGET" != "x86_64" ] && [ "$OBW_TARGET" != "x86" ]; then
	echo "# CONFIG_PACKAGE_kmod-r8125 is not set" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
#	echo "# CONFIG_PACKAGE_kmod-r8168 is not set" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
	echo "CONFIG_PACKAGE_kmod-r8168=m" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
fi
if [ "$OBW_KERNEL" = "6.1" ] || [ "$OBW_KERNEL" = "6.6" ] || [ "$OBW_KERNEL" = "6.10" ] || [ "$OBW_KERNEL" = "6.11" ] || [ "$OBW_KERNEL" = "6.12" ]; then
	echo "# CONFIG_PACKAGE_kmod-rtl8812au-ct is not set" >> "$OBW_TARGET/${OBW_KERNEL}/source/.config"
fi

cd "$OBW_TARGET/${OBW_KERNEL}/source"

echo "Checking if Nanqinlang patch is set or not"
if ! patch -Rf -N -p1 -s --dry-run < ../../../patches/nanqinlang.patch; then
	echo "apply..."
	patch -N -p1 -s < ../../../patches/nanqinlang.patch
fi
echo "Done"

echo "Checking if Meson patch is set or not"
if [ "$OBW_KERNEL" = "5.4" ] && ! patch -Rf -N -p1 -s --dry-run < ../../../patches/meson.patch; then
	patch -N -p1 -s < ../../../patches/meson.patch
fi
echo "Done"

echo "Checking if smsc75xx patch is set or not"
if ! patch -Rf -N -p1 -s --dry-run < ../../../patches/smsc75xx.patch; then
	echo "apply..."
	patch -N -p1 -s < ../../../patches/smsc75xx.patch
fi
echo "Done"

if [ -f target/linux/mediatek/patches-5.4/0999-hnat.patch ]; then
	rm -f target/linux/mediatek/patches-5.4/0999-hnat.patch
fi

if [ -f target/linux/ipq806x/patches-5.4/0063-2-tsens-support-configurable-interrupts.patch ]; then
	rm -f target/linux/ipq806x/patches-5.4/0063-*
fi

if [ -f package/boot/uboot-rockchip/patches/100-rockchip-rk3328-Add-support-for-FriendlyARM-NanoPi-R.patch ]; then
	rm -f package/boot/uboot-rockchip/patches/100-rockchip-rk3328-Add-support-for-FriendlyARM-NanoPi-R.patch
fi

NOT_SUPPORTED="0"

if [ "$OBW_KERNEL" = "6.6" ]; then
	echo "Set to kernel 6.6 for x86 arch"
	find target/linux/x86 -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for mediatek"
	find target/linux/mediatek -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for qualcommmax"
	find target/linux/qualcommax -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for bcm27xx"
	find target/linux/bcm27xx -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for ipq40xx"
	find target/linux/ipq40xx -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for ipq806x"
	find target/linux/ipq806x -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for kirkwood"
	find target/linux/kirkwood -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for mpc85xx"
	find target/linux/mpc85xx -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for mvebu"
	find target/linux/mvebu -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for ramips"
	find target/linux/ramips -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"
	echo "Set to kernel 6.6 for rockchip"
	find target/linux/rockchip -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.1%KERNEL_PATCHVER:=6.6%g' {} \;
	echo "Done"


	echo "# CONFIG_PACKAGE_kmod-gpio-nct5104d is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-vfio is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-vfio-pci is not set" >> ".config"

	if [ "$OBW_TARGET" != "ubnt-erx" ] && [ "$OBW_TARGET" != "r7800" ]; then
		echo "CONFIG_BPF_TOOLCHAIN=y" >> ".config"
		echo "CONFIG_BPF_TOOLCHAIN_HOST=y" >> ".config"
		echo "CONFIG_KERNEL_BPF_EVENTS=y" >> ".config"
		echo "CONFIG_KERNEL_DEBUG_INFO=y" >> ".config"
		echo "CONFIG_KERNEL_DEBUG_INFO_BTF=y" >> ".config"
		echo "CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES=y" >> ".config"
		echo "# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set" >> ".config"
		echo "CONFIG_KERNEL_MODULE_ALLOW_BTF_MISMATCH=y" >> ".config"
	fi

	# Remove not needed patches
	rm -f target/linux/generic/hack-6.6/212-tools_portability.patch
	if [ ! -d target/linux/`sed -nE 's/CONFIG_TARGET_([a-z0-9]*)=y/\1/p' ".config" | tr -d "\n"`/patches-6.6 ]; then
		echo "Sorry but kernel 6.6 is not supported on your arch yet"
		NOT_SUPPORTED="1"
	fi
fi
if [ "$OBW_KERNEL" = "6.10" ]; then
	echo "Set to kernel 6.10 for x86 arch"
	find target/linux/x86 -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.6%KERNEL_PATCHVER:=6.10%g' {} \;
	echo "Done"
	echo "Set to kernel 6.10 for mediatek"
	find target/linux/mediatek -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.6%KERNEL_PATCHVER:=6.10%g' {} \;
	echo "Done"
	echo "CONFIG_VERSION_CODE=6.10" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-gpio-button-hotplug is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-meraki-mx100 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-gpio-nct5104d is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8168 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-button-hotplug is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-cryptodev is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-trelay is not set" >> ".config"
	echo "# CONFIG_PACKAGE_464xlat is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-nat46 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-ath10k-ct-smallbuffers is not set" >> ".config"
	echo "CONFIG_BPF_TOOLCHAIN=y" >> ".config"
	echo "CONFIG_BPF_TOOLCHAIN_HOST=y" >> ".config"
	echo "CONFIG_KERNEL_BPF_EVENTS=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO_BTF=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES=y" >> ".config"
	echo "# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set" >> ".config"
	echo "CONFIG_KERNEL_MODULE_ALLOW_BTF_MISMATCH=y" >> ".config"
	# Remove for now packages that doesn't compile
	rm -rf package/kernel/mt76
	rm -rf package/kernel/rtl8812au-ct
	# Remove not needed patches
	rm -f package/kernel/mac80211/patches/build/200-Revert-wifi-iwlwifi-Use-generic-thermal_zone_get_tri.patch
	rm -f package/kernel/mac80211/patches/build/210-revert-split-op.patch
	rm -f package/kernel/mac80211/patches/subsys/301-mac80211-sta-randomize-BA-session-dialog-token-alloc.patch
	rm -f package/kernel/mac80211/patches/build/240-backport_genl_split_ops.patch
	rm -f package/kernel/mac80211/patches/build/250-backport_iwlwifi_thermal.patch
	rm -f package/kernel/rtl8812au-ct/patches/099-cut-linkid-linux-version-code-conditionals.patch
	rm -f package/kernel/rtl8812au-ct/patches/100-api_update.patch
	echo 'CONFIG_KERNEL_GIT_CLONE_URI="https://github.com/multipath-tcp/mptcp_net-next.git"' >> ".config"
	echo 'CONFIG_KERNEL_GIT_REF="30be9e34452a634aab77a15634890e9c7637812a"' >> ".config"
fi
if [ "$OBW_KERNEL" = "6.11" ]; then
	echo "Set to kernel 6.11 for x86 arch"
	find target/linux/x86 -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.6%KERNEL_PATCHVER:=6.11%g' {} \;
	echo "Done"
	echo "Set to kernel 6.11 for mediatek"
	find target/linux/mediatek -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.6%KERNEL_PATCHVER:=6.11%g' {} \;
	echo "Done"
	echo "CONFIG_VERSION_CODE=6.11" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-gpio-button-hotplug is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-meraki-mx100 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-gpio-nct5104d is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8168 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8125 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8125-rss is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8126 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8126-rss is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-button-hotplug is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-cryptodev is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-trelay is not set" >> ".config"
	echo "# CONFIG_PACKAGE_464xlat is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-nat46 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-ath10k-ct-smallbuffers is not set" >> ".config"
	echo "CONFIG_BPF_TOOLCHAIN=y" >> ".config"
	echo "CONFIG_BPF_TOOLCHAIN_HOST=y" >> ".config"
	echo "CONFIG_KERNEL_BPF_EVENTS=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO_BTF=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES=y" >> ".config"
	echo "# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set" >> ".config"
	echo "CONFIG_KERNEL_MODULE_ALLOW_BTF_MISMATCH=y" >> ".config"
	# Remove for now packages that doesn't compile
	rm -rf package/kernel/mt76
	rm -rf package/kernel/rtl8812au-ct
	# Remove not needed patches
	rm -f package/kernel/mac80211/patches/build/200-Revert-wifi-iwlwifi-Use-generic-thermal_zone_get_tri.patch
	rm -f package/kernel/mac80211/patches/build/210-revert-split-op.patch
	rm -f package/kernel/mac80211/patches/subsys/301-mac80211-sta-randomize-BA-session-dialog-token-alloc.patch
	rm -f package/kernel/mac80211/patches/build/240-backport_genl_split_ops.patch
	rm -f package/kernel/mac80211/patches/build/250-backport_iwlwifi_thermal.patch
	rm -f package/kernel/rtl8812au-ct/patches/099-cut-linkid-linux-version-code-conditionals.patch
	rm -f package/kernel/rtl8812au-ct/patches/100-api_update.patch
fi
if [ "$OBW_KERNEL" = "6.12" ]; then
	echo "Set to kernel 6.12 for x86 arch"
	find target/linux/x86 -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.6%KERNEL_PATCHVER:=6.12%g' {} \;
	echo "Done"
	echo "Set to kernel 6.12 for mediatek"
	find target/linux/mediatek -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.6%KERNEL_PATCHVER:=6.12%g' {} \;
	echo "Done"
	echo "Set to kernel 6.12 for bcm27xx"
	find target/linux/bcm27xx -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.6%KERNEL_PATCHVER:=6.12%g' {} \;
	echo "Done"
	echo "Set to kernel 6.12 for bcm27xx"
	find target/linux/qualcommax -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=6.6%KERNEL_PATCHVER:=6.12%g' {} \;
	echo "Done"
	echo "CONFIG_VERSION_CODE=6.12" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-gpio-button-hotplug is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-meraki-mx100 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-gpio-nct5104d is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8168 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8125 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8125-rss is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8126 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-r8126-rss is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-button-hotplug is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-cryptodev is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-trelay is not set" >> ".config"
	echo "# CONFIG_PACKAGE_464xlat is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-nat46 is not set" >> ".config"
	echo "# CONFIG_PACKAGE_kmod-ath10k-ct-smallbuffers is not set" >> ".config"
	echo "CONFIG_BPF_TOOLCHAIN=y" >> ".config"
	echo "CONFIG_BPF_TOOLCHAIN_HOST=y" >> ".config"
	echo "CONFIG_KERNEL_BPF_EVENTS=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO_BTF=y" >> ".config"
	echo "CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES=y" >> ".config"
	echo "# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set" >> ".config"
	echo "CONFIG_KERNEL_MODULE_ALLOW_BTF_MISMATCH=y" >> ".config"
	echo 'CONFIG_EXTRA_OPTIMIZATION="-fno-caller-saves -fno-plt -Wno-stringop-truncation -Wno-stringop-overread -Wno-calloc-transposed-args"' >> ".config"
	# Remove for now packages that doesn't compile
	rm -rf package/kernel/mt76
	rm -rf package/kernel/rtl8812au-ct
	# Remove not needed patches
	rm -f package/kernel/mac80211/patches/build/200-Revert-wifi-iwlwifi-Use-generic-thermal_zone_get_tri.patch
	rm -f package/kernel/mac80211/patches/build/210-revert-split-op.patch
	rm -f package/kernel/mac80211/patches/subsys/301-mac80211-sta-randomize-BA-session-dialog-token-alloc.patch
	rm -f package/kernel/mac80211/patches/build/240-backport_genl_split_ops.patch
	rm -f package/kernel/mac80211/patches/build/250-backport_iwlwifi_thermal.patch
	rm -f package/kernel/rtl8812au-ct/patches/099-cut-linkid-linux-version-code-conditionals.patch
	rm -f package/kernel/rtl8812au-ct/patches/100-api_update.patch

	echo 'CONFIG_PACKAGE_apk-openssl=y' >> ".config"
	if [ ! -d target/linux/`sed -nE 's/CONFIG_TARGET_([a-z0-9]*)=y/\1/p' ".config" | tr -d "\n"`/patches-6.12 ]; then
		echo "Sorry but kernel 6.12 is not supported on your arch yet"
		NOT_SUPPORTED="1"
	fi
fi

cd "../../.."
rm -rf feeds/${OBW_KERNEL}/luci/modules/luci-mod-network

if [ -d feeds/${OBW_KERNEL}/${OBW_DIST}/luci-mod-status ]; then
	rm -rf feeds/${OBW_KERNEL}/luci/modules/luci-mod-status
elif [ "$OBW_KERNEL" = "6.6" ] || [ "$OBW_KERNEL" = "6.10" ] || [ "$OBW_KERNEL" = "6.11" ] || [ "$OBW_KERNEL" = "6.12" ]; then
	cd feeds/${OBW_KERNEL}
	if ! patch -Rf -N -p1 -s --dry-run < ../../patches/luci-syslog-6.10.patch; then
		patch -N -p1 -s < ../../patches/luci-syslog-6.10.patch
	fi
	cd -
else
	cd feeds/${OBW_KERNEL}
	if ! patch -Rf -N -p1 -s --dry-run < ../../patches/luci-syslog.patch; then
		patch -N -p1 -s < ../../patches/luci-syslog.patch
	fi
	cd -
fi

cd feeds/${OBW_KERNEL}
if ! patch -Rf -N -p1 -s --dry-run < ../../patches/luci-unbound-logread.patch; then
	patch -N -p1 -s < ../../patches/luci-unbound-logread.patch
fi
cd -


[ -d feeds/${OBW_KERNEL}/${OBW_DIST}/luci-app-statistics ] && rm -rf feeds/${OBW_KERNEL}/luci/applications/luci-app-statistics
[ -d feeds/${OBW_KERNEL}/${OBW_DIST}/luci-proto-modemmanager ] && rm -rf feeds/${OBW_KERNEL}/luci/protocols/luci-proto-modemmanager

[ -d ${OBW_FEED}/libgpiod ] && rm -rf feeds/${OBW_KERNEL}/packages/libs/libgpiod
[ -d ${OBW_FEED}/iperf3 ] && rm -rf feeds/${OBW_KERNEL}/packages/net/iperf3
[ -d ${OBW_FEED}/golang ] && {
	rm -rf feeds/${OBW_KERNEL}/packages/lang/golang
	cp -r ${OBW_FEED}/golang feeds/${OBW_KERNEL}/packages/lang/
}
[ -d ${OBW_FEED}/openvpn ] && rm -rf feeds/${OBW_KERNEL}/packages/net/openvpn
[ -d ${OBW_FEED}/iproute2 ] && rm -rf feeds/${OBW_KERNEL}/packages/network/utils/iproute2
[ -d ${CUSTOM_FEED}/syslog-ng ] && rm -rf feeds/${OBW_KERNEL}/packages/admin/syslog-ng
([ "$OBW_KERNEL" = "6.6" ] || [ "$OBW_KERNEL" = "6.10" ]) && [ -d ${OBW_FEED}/xtables-addons ] && rm -rf feeds/${OBW_KERNEL}/packages/net/xtables-addons

echo "Add Occitan translation support"
cd feeds/${OBW_KERNEL}
if ! patch -Rf -N -p1 -s --dry-run < ../../patches/luci-occitan.patch; then
	patch -N -p1 -s < ../../patches/luci-occitan.patch
fi
if [ "$OBW_KERNEL" = "5.4" ] && ! patch -Rf -N -p1 -s --dry-run < ../../patches/luci-base-add_array_sort_utilities.patch; then
	patch -N -p1 -s < ../../patches/luci-base-add_array_sort_utilities.patch
fi

cd ../..
[ -d $OBW_FEED/luci-base/po/oc ] && cp -rf $OBW_FEED/luci-base/po/oc feeds/${OBW_KERNEL}/luci/modules/luci-base/po/
echo "Done"

cd "$OBW_TARGET/${OBW_KERNEL}/source"
echo "Update feeds index"
cp .config .config.keep
scripts/feeds clean
scripts/feeds update -a


if [ "$OBW_ALL_PACKAGES" = "yes" ]; then
	scripts/feeds install -a -d m -p packages
	scripts/feeds install -a -d m -p luci
fi
if [ -n "$CUSTOM_FEED" ]; then
	scripts/feeds install -a -d m -p openmptcprouter
	scripts/feeds install -a -d y -f -p ${OBW_DIST}
else
	scripts/feeds install -a -d y -f -p openmptcprouter
fi

if [ "$OBW_KERNEL" != "5.4" ] && [ "$OBW_KERNEL" != "6.1" ]; then
	scripts/feeds uninstall netifd
	scripts/feeds install netifd
fi
cp .config.keep .config
scripts/feeds install kmod-macremapper
echo "Done"

if [ ! -f "../../../$OBW_TARGET_CONFIG" ] || [ "$NOT_SUPPORTED" = "1" ]; then
	echo "Target $OBW_TARGET not found ! You have to configure and compile your kernel manually."
	exit 1
fi
[ "$ONLY_PREPARE" = "yes" ] && exit 0
echo "Building $OBW_DIST for the target $OBW_TARGET with kernel ${OBW_KERNEL}"
make defconfig
make IGNORE_ERRORS=m "$@"
echo "Done"
