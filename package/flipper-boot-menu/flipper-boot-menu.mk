################################################################################
#
# flipper-boot-menu
#
################################################################################

# Track the upstream development branch by default. Overridable from the
# environment or the make command line so CI can pin an exact commit per build:
#   make FLIPPER_BOOT_MENU_VERSION=<sha>
FLIPPER_BOOT_MENU_VERSION ?= dev
FLIPPER_BOOT_MENU_SITE = https://github.com/flipperdevices/flipctl-slint.git
FLIPPER_BOOT_MENU_SITE_METHOD = git

# The binary is a workspace member, and cargo cannot install from a virtual
# manifest, so the build happens in the binary's own directory. The workspace
# root above it still supplies [profile.release]: opt-level=z, fat LTO, one
# codegen unit, panic=abort, stripped.
FLIPPER_BOOT_MENU_SUBDIR = bin/flipper-boot-menu

# No feature flags: this crate asks flipper-ui for `device` and `slint` in its own
# manifest, and asks for nothing else. In particular it does not take `screens`,
# which would compile flipctl's Root and every screen with it; this program draws
# the boot menu and the keyboard it renames with, from its own entry file.
#
# What it does NOT need, and the installer does: libinput, libxkbcommon,
# xkeyboard-config, fontconfig and freetype. Slint is taken as a renderer with no
# backend at all -- this owns the DRM card and reads evdev itself -- and glyphs are
# embedded at build time, so nothing enumerates system fonts. That is also why
# there is no hook installing TTFs into /usr/share/fonts.

# License of the built binary, which is a combined work -- not just Flipper's
# (MIT) source. flipctl's REUSE metadata declares only its own source as MIT and
# does not (cannot) waive its dependencies' terms:
#   - flipctl source + Busy9px font : MIT
#   - HaxrCorp 4090 font            : CC-BY-SA-3.0
#   - Born2bSportyV2 font           : Unlicense
#   - Slint (statically-linked)     : GPL-3.0-only  <-- copyleft; governs the
#     whole binary. Slint is tri-licensed (GPL-3.0-only / royalty-free /
#     commercial); building from the public sources with no Slint agreement
#     uses GPL-3.0-only.
# GPLv3 requires the license text accompany the binary. Slint's own copy lives in
# vendored crates whose paths shift across releases, so a stable copy (identical
# canonical GPLv3) lives in this package dir and is staged into the extracted
# source so legal-info always captures it.
FLIPPER_BOOT_MENU_LICENSE = \
	GPL-3.0-only (whole binary: statically links Slint), \
	MIT (our source, Busy9px font), \
	CC-BY-SA-3.0 (HaxrCorp 4090 font), \
	Unlicense (Born2bSportyV2 font)
FLIPPER_BOOT_MENU_LICENSE_FILES = \
	GPL-3.0-only.txt \
	LICENSES/MIT.txt \
	third_party/flipctl-fonts/HaxrCorp4090-FlipCTL/LICENSE \
	third_party/flipctl-fonts/Busy9px-FlipCTL/LICENSE \
	third_party/flipctl-fonts/Born2bSportyV2-FlipCTL/LICENSE

define FLIPPER_BOOT_MENU_STAGE_GPL_TEXT
	$(INSTALL) -m 0644 $(FLIPPER_BOOT_MENU_PKGDIR)/GPL-3.0-only.txt $(FLIPPER_BOOT_MENU_DIR)/
endef
FLIPPER_BOOT_MENU_POST_PATCH_HOOKS += FLIPPER_BOOT_MENU_STAGE_GPL_TEXT

# lsblk and findmnt: the menu finds the filesystems that can hold profiles by
# partition type and asks which one it booted from. BusyBox has neither applet.
# host-rustc is added automatically by the cargo-package infrastructure.
FLIPPER_BOOT_MENU_DEPENDENCIES = host-pkgconf util-linux

$(eval $(cargo-package))
