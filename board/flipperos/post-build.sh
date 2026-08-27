#!/bin/sh
# Trim files no package flag can remove. Buildroot runs this after installing all
# packages, before packing the image, and exports TARGET_DIR (also passed as $1).
set -eu

TARGET="${TARGET_DIR:-${1:?target directory not provided}}"

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
