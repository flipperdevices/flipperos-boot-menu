# Toplevel Makefile: out-of-tree Buildroot build for the FlipperOS boot menu
# initramfs. Every target is forwarded to the pinned Buildroot submodule,
# built out-of-tree (O=) with this directory as the BR2_EXTERNAL tree.
#
#   make                 configure (if needed) + build the initramfs, from the
#                        current dev tip of both of our packages
#   make menuconfig      tweak the config   |  make savedefconfig  save it back
#   make clean|distclean |  make <pkg>-rebuild  |  ... any Buildroot target
#   O=<dir>              override the output directory (default: ./output)
#
# Result images land in $(O)/images/: rootfs.cpio and rootfs.cpio.zst

BR2_EXTERNAL := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
O            ?= $(BR2_EXTERNAL)/output

# Keep Buildroot's download cache out of the submodule (its default is
# buildroot/dl). Persist it across runs and across `make distclean`.
BR2_DL_DIR   ?= $(BR2_EXTERNAL)/dl
export BR2_DL_DIR

# Both of our packages track a branch, and Buildroot keys its download cache AND its
# build directory on the version string. A plain `dev` is therefore fetched once and
# reused for ever: the second build silently carries whatever the first one downloaded,
# which is how a fix pushed upstream can be missing from an image that just rebuilt.
# Resolve the tips to shas, which change when the branch does. Override either to pin a
# build, and either falls back to `dev` when the network is not there to ask.
FLIPPER_BOOT_MENU_VERSION ?= $(or $(shell git ls-remote https://github.com/flipperdevices/flipctl-slint.git dev 2>/dev/null | awk 'NR==1{print $$1}'),dev)
FLIPPER_BTRFS_TOOLS_VERSION ?= $(or $(shell git ls-remote https://github.com/flipperdevices/flipperos-btrfs-tools.git dev 2>/dev/null | awk 'NR==1{print $$1}'),dev)
export FLIPPER_BOOT_MENU_VERSION
export FLIPPER_BTRFS_TOOLS_VERSION

BR_MAKE       = $(MAKE) -C $(BR2_EXTERNAL)/buildroot O=$(O) BR2_EXTERNAL=$(BR2_EXTERNAL)

# Default build: load the defconfig on first use, then let Buildroot build.
.DEFAULT_GOAL := all
all:
	@test -f $(O)/.config || $(BR_MAKE) flipperos_boot_menu_defconfig
	@$(BR_MAKE)

# Forward every other target straight to Buildroot.
%:
	@$(BR_MAKE) $@
