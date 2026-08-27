# flipperos-boot-menu

Buildroot builder for an **initramfs-only ARM64 image** that boots first on a
Flipper One and asks what to boot. It lists the bootable profiles it can find,
on the internal storage and on anything plugged in, and kexecs into the one
chosen.

The build produces a standalone initramfs archive in two forms:

- `output/images/rootfs.cpio` — uncompressed
- `output/images/rootfs.cpio.zst` — zstd-compressed (kernel must support
  `CONFIG_RD_ZSTD`)

There is **no kernel and no bootloader** here, and that is the point twice over:
this image is unpacked by whatever kernel the loader gives it, and every profile
it boots is entered with that profile's *own* kernel, initrd and device tree,
read from that profile's own BLS entry. The menu supplies none of its own.

## What is in the image

| | |
|---|---|
| [flipper-boot-menu](https://github.com/flipperdevices/flipctl-slint) | the menu, drawn on the 256x144 SPI panel |
| [flipperos-btrfs-tools](https://github.com/flipperdevices/flipperos-btrfs-tools) | `list-profiles`, `flipmeta`, `boot-profile` |
| kexec-tools, btrfs-progs, dtc, jq, tinycbor | what those three shell out to |
| coreutils, mawk, util-linux binaries | the dialects and tools the scripts are written for |
| BusyBox + eudev | init, the shell, and /dev |

The menu is a binary of its own in the flipctl-slint tree, not flipctl with things
switched off: it takes flipper-ui with `device` and `slint` and compiles its own
entry file, so flipctl's other screens are never built at all. It owns the DRM card
and reads the buttons from evdev, so unlike the installer's GUI it needs no libinput,
no libxkbcommon, no fontconfig and no freetype, and its glyphs are embedded at build
time. No compositor, no seat, no browser view, no app hosting.

BusyBox is deliberately *not* trusted for the parts that matter: it has no
`kexec` applet at all, no `lsblk` and no `findmnt`, and its `awk` would be a
third dialect in scripts that have already been caught out by the mawk/gawk
difference. So the real tools come along.

## Layout

This repository is a Buildroot **BR2_EXTERNAL** tree (`external.desc` name:
`FLIPPEROS_BOOTMENU`) with Buildroot itself vendored as a submodule:

```
.
├── Makefile                       # out-of-tree wrapper around the submodule
├── external.desc / Config.in / external.mk
├── configs/
│   └── flipperos_boot_menu_defconfig
├── package/
│   ├── flipper-boot-menu/         # the menu (cargo-package)
│   └── flipper-btrfs-tools/       # the profile tools, and what they need
├── board/flipperos/
│   ├── rootfs-overlay/etc/inittab
│   ├── rootfs-overlay/usr/bin/boot-menu-launch
│   └── post-build.sh
└── buildroot/                     # submodule, pinned
```

## Building

```sh
git submodule update --init --recursive
make                       # defconfig on first use, then build
make menuconfig            # tweak    | make savedefconfig   save it back
make FLIPPER_BOOT_MENU_VERSION=<sha>   # pin the menu to an exact commit
```

## Kernel command line

| | |
|---|---|
| `bootmenu=dryrun` | load a profile's kernel and unload it again instead of handing over: proves an entry resolves without losing the session |
| `bootmenu=shell` | skip the menu, drop to a shell |

## Licensing

Our source is MIT. The image contains flipctl, which statically links Slint under
GPL-3.0-only, so **that binary as a whole is GPL-3.0-only**; the package declares
the combination, and `make legal-info` collects it.
