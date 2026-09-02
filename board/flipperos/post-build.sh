#!/bin/sh
# Trim files no package flag can remove. Buildroot runs this after installing all
# packages, before packing the image, and exports TARGET_DIR (also passed as $1).
set -eu

TARGET="${TARGET_DIR:-${1:?target directory not provided}}"

# Init scripts for services this image does not have. rcS is a `::sysinit:` entry, so
# all of it runs to completion before init starts the menu.
#
#   S40network   the image carries no networking, by design: nothing listens
#   S50crond     nothing to schedule in a boot menu
#   S01syslogd   nothing reads syslog; our log goes to /dev/kmsg
#   S02klogd     the same, from the other direction
#   S01seedrng   saves the RNG seed to a tmpfs, so it persists nothing across boots
#
# Removed because they do nothing here, and not for the time: rcS measured 955ms and
# 977ms with these gone against 635ms with them present, because what it costs is
# `udevadm settle` in S10udevd waiting for the UFS disk, which arrives when it arrives.
#
# Kept: S02sysctl, S11modules, and S10udevd, which is load-bearing: until udevd has
# written its database, lsblk reports an empty PARTTYPE (its udev lookup succeeds off
# bare sysfs and returns no properties, so its blkid fallback never runs), and PARTTYPE
# is how a drive is recognised at all.
for s in S40network S50crond S01syslogd S02klogd S01seedrng; do
	rm -f "$TARGET/etc/init.d/$s"
done

# Where boot-pivot mounts the profile it is handing PID 1 to. It has to exist in the image:
# init's last shutdown action is `umount -a -r`, which remounts this root read-only, so by the
# time boot-pivot runs as PID 1 it cannot create a mount point of its own.
mkdir -p "$TARGET/newroot"

# glibc's vectorized-math library. Buildroot copies it in as part of the C
# library runtime, but nothing in the image links it (the menu
# use scalar libm); libm does not depend on it. Safe to drop (~216 KB).
rm -f "$TARGET"/lib/libmvec.so* "$TARGET"/usr/lib/libmvec.so*

# btrfs-progs statically-linked debug/recovery tools the menu never runs.
# btrfs-progs has no Buildroot sub-option to install a subset, so purge them
# here. Kept: mkfs.btrfs, the btrfs multi-tool, btrfsck symlink, fsck.btrfs.
# (~3 MB, ~580-620 KB each.)
for t in btrfs-image btrfstune btrfs-select-super btrfs-map-logical \
         btrfs-find-root btrfs-corrupt-block; do
	rm -f "$TARGET/usr/bin/$t" "$TARGET/usr/sbin/$t" "$TARGET/sbin/$t"
done

echo "post-build: removed unused libmvec and btrfs debug tools"
