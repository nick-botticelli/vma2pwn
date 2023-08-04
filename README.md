# vma2pwn
vma2pwn is a command-line tool for arm64 macOS to patch VMA2 (virtual Mac platform) components for
restoring and booting a fully modded chain of iBoot + macOS components.

This is very much a work-in-progress, and more functionality and support will be added over time.

## Supported Guest Versions
### macOS
* 12.0.1 (21A559)

## Requirements
* Apple Silicon (arm64) Mac (at least 12.0 host preferred). There are no plans to support anything else.
* A tool to run vma2 virtual machines through Virtualization.framework. I recommend
[super-tart](https://github.com/nick-botticelli/super-tart), my fork of tart.
* idevicerestore, [but preferably my fork with a few
changes](https://github.com/nick-botticelli/idevicerestore). Currently not fully tested, but may
be required for successful restore.

## Usage
### super-tart Part 1 (Optional)
1. Download and build super-tart from the link above.
2. Create a new virtual machine (VM) with
`tart create <VM name> --from-ipsw <matching IPSW> --disk-size <disk size in GB>`. You should have
a minimum of about ~25 GB for the disk. Don't specify a custom AVPBooter path here.
3. Wait for the VM to be created (probably doesn't even need to fully install, just enough to
launch in DFU mode).
4. Note: The AVPBooter image will now need to be patched. Move on to the steps in `vma2pwn`
section.

### vma2pwn
1. Download or clone the repository, and open a Terminal in this directory.
2. Run `./vma2pwn.sh prepare <macOS version>`, e.g., `./vma2pwn.sh prepare 12.0.1`, and wait for it
to complete.

### super-tart Part 2 (Optional)
1. Copy the patched AVPBooter image created (`avpbooter-images/<version>/AVPBooter.vmapple2.bin`)
to `~/.tart/vms/<VM name>/AVPBooter.vmapple2.bin`, replacing the one that already exists.
2. Start the virtual machine in DFU mode (i.e., `tart run <VM name> --force-dfu`).
2. Restore this modded image via idevicerestore with `./vma2pwn.sh restore <output from step 2>`,
e.g., `./vma2pwn.sh restore UniversalMac_12.0.1_21A559_Restore`.
3. Wait for the restore process to complete, and your macOS virtual machine should automatically
startup to the Setup Assistant like normal.

## Notes
* This is a work in progress. File an issue if you have one, make a pull request if you want to;
I recommend filing an issue first.
* Scripts are not always fully tested before uploading. There may be slight issues.
* This tool relies on two binaries downloaded from my
[vma2pwn-tools](https://github.com/nick-botticelli/vma2pwn-tools) repository: `bspatch` and `img4`.
If you don't want to use these, build them yourself.
* iBoot (iBootStage2 post-restore) is patched with various debugging boot-args, which means that
you currently cannot set your own. I may test `nvram`'s boot-arg functionality and remove this part
of the patch.
* Kernelcache currently contains many patches, not all of which are likely necessary. I hope to
work on reducing the number of patches.

## Known Isues
* Double-patching (running `vma2pwn.sh` twice on) the same extracted IPSW may result in broken
components
* [You tell me](../../issues)

## License
[GNU Lesser General Public License v3.0](LICENSE)

## Credits
* [NyanSatan](https://github.com/NyanSatan) – Initial iBoot + kernel patches from
[Virtual-iBoot-Fun](https://github.com/NyanSatan/Virtual-iBoot-Fun)
* Various members of the Hack Different Discord server – Answering and putting up with my
constant bombardment of questions
