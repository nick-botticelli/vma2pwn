#!/bin/zsh

#
# vma2pwn - prepare.sh
# v0.1.0
#

# Fail-fast
set -e

# Check dependencies
if ! [[ -f 'tools/.finished' ]]; then
    echo 'Dependencies are not downloaded! Please run get-dependencies.sh first.'
    exit -1
fi

# Check arguments
# TODO: Allow for passing in either version or build number
if [ $# -eq 0 ]; then
    echo 'Please supply the macOS version (.e.g, \"12.0.1\") to use as an input to this script!'
    exit -1
fi

# Script arguments
MACOS_VERSION=$1

IPSW_URL=$(curl -sL 'https://api.ipsw.me/v4/device/Macmini9,1?type=ipsw' | ./tools/jq '.firmwares | .[] | select(.version=="'$MACOS_VERSION'")' | ./tools/jq -s '.[0] | .url' --raw-output)
IPSW_OUTPUT=$(basename $IPSW_URL)
IPSW_EXT_OUTPUT=$IPSW_OUTPUT:t:r

# Get build (e.g., 21A559)
IFS="_"
read -A BUILD_ARR <<< "$IPSW_EXT_OUTPUT"
BUILD="${BUILD_ARR[3]}"

# Check if IPSW already exists
if [ -d "$IPSW_EXT_OUTPUT" ]; then
    echo "$IPSW_EXT_OUTPUT already exists; skipping download and extraction."
elif [ -f "$IPSW_OUTPUT" ]; then
    echo "$IPSW_OUTPUT already exists; extracting..."
    unzip "$IPSW_OUTPUT" "$IPSW_EXT_OUTPUT"
else
    mkdir -p "$IPSW_EXT_OUTPUT"
    
    # Download IPSW
    ../tools/pzb -g "$IPSW_OUTPUT" "$IPSW_URL" > /dev/null
    
    # TODO: Remove redundant code
    echo "Extracting $IPSW_OUTPUT..."
    unzip "$IPSW_OUTPUT" "$IPSW_EXT_OUTPUT"
    
    echo 'Finished downloading.'
fi

# Find restore ramdisk path
BM_PATH="$IPSW_EXT_OUTPUT/BuildManifest.plist"
BM_NUM=$(plutil -extract BuildIdentities raw $BM_PATH)
for (( i = 0; i <= $BM_NUM; i++ ))
do
    BM_ENTRY="BuildIdentities.$i"
    BM_CHIPID=$(plutil -extract $BM_ENTRY.ApChipID raw $BM_PATH)
    
    if [ $BM_CHIPID = '0xFE00' ]; then
        BM_MANIFEST=$(plutil -extract $BM_ENTRY.Manifest raw $BM_PATH)
        
        # Download all Manifest files needed for restore
        while IFS= read -r manifestEntry; do
            BM_ENTRY_FILE=$(plutil -extract $BM_ENTRY.Manifest.$manifestEntry.Info.Path raw $BM_PATH)
            
            if [ $manifestEntry = 'RestoreRamDisk' ]; then
                BM_RDSK_PATH="$BM_ENTRY_FILE"
            elif [ $manifestEntry = 'OS' ]; then
                BM_OS_PATH="$BM_ENTRY_FILE"
            fi
        done <<< "$BM_MANIFEST"
    
        break
    fi
done

# Patch iBSS
echo 'Patching iBSS...'
./tools/img4 -i "$IPSW_EXT_OUTPUT/Firmware/dfu/iBSS.vma2.RELEASE.im4p" -o 'iBSS.vma2.RELEASE'
./tools/bspatch 'iBSS.vma2.RELEASE' 'iBSS.vma2.RELEASE.patched' "patches/$BUILD/iBSS.bspatch43"
./tools/img4tool -c "$IPSW_EXT_OUTPUT/Firmware/dfu/iBSS.vma2.RELEASE.im4p" -t 'ibss' 'iBSS.vma2.RELEASE.patched'
rm 'iBSS.vma2.RELEASE' 'iBSS.vma2.RELEASE.patched'

# Patch iBEC
echo 'Patching iBEC...'
./tools/img4 -i "$IPSW_EXT_OUTPUT/Firmware/dfu/iBEC.vma2.RELEASE.im4p" -o 'iBEC.vma2.RELEASE'
./tools/bspatch 'iBEC.vma2.RELEASE' 'iBEC.vma2.RELEASE.patched' "patches/$BUILD/iBEC.bspatch43"
./tools/img4tool -c "$IPSW_EXT_OUTPUT/Firmware/dfu/iBEC.vma2.RELEASE.im4p" -t 'ibec' 'iBEC.vma2.RELEASE.patched'
rm 'iBEC.vma2.RELEASE' 'iBEC.vma2.RELEASE.patched'

# Patch LLB
echo 'Patching LLB...'
./tools/img4 -i "$IPSW_EXT_OUTPUT/Firmware/all_flash/LLB.vma2.RELEASE.im4p" -o 'LLB.vma2.RELEASE'
./tools/bspatch 'LLB.vma2.RELEASE' 'LLB.vma2.RELEASE.patched' "patches/$BUILD/LLB.bspatch43"
./tools/img4tool -c "$IPSW_EXT_OUTPUT/Firmware/all_flash/LLB.vma2.RELEASE.im4p" -t 'illb' 'LLB.vma2.RELEASE.patched'
rm 'LLB.vma2.RELEASE' 'LLB.vma2.RELEASE.patched'

# Patch iBoot
echo 'Patching iBoot...'
./tools/img4 -i "$IPSW_EXT_OUTPUT/Firmware/all_flash/iBoot.vma2.RELEASE.im4p" -o 'iBoot.vma2.RELEASE'
./tools/bspatch 'iBoot.vma2.RELEASE' 'iBoot.vma2.RELEASE.patched' "patches/$BUILD/iBoot.bspatch43"
./tools/img4tool -c "$IPSW_EXT_OUTPUT/Firmware/all_flash/iBoot.vma2.RELEASE.im4p" -t 'ibot' 'iBoot.vma2.RELEASE.patched'
rm 'iBoot.vma2.RELEASE' 'iBoot.vma2.RELEASE.patched'

# Patch kernel
echo 'Patching kernel...'
./tools/img4 -i "$IPSW_EXT_OUTPUT/kernelcache.release.vma2" -o 'kernelcache.release.vma2.raw'
./tools/bspatch 'kernelcache.release.vma2.raw' 'kernelcache.release.vma2.raw.patched' "patches/$BUILD/kernelcache.bspatch43"
./tools/img4tool -c "$IPSW_EXT_OUTPUT/kernelcache.release.vma2" -t 'krnl' 'kernelcache.release.vma2.raw.patched'
rm 'kernelcache.release.vma2.raw' 'kernelcache.release.vma2.raw.patched'

# Patch restore ramdisk
echo "Patching restore ramdisk ($BM_RDSK_PATH)..."
BM_RDSK_PATH_BASE=$(basename $BM_RDSK_PATH)
mkdir -p 'rdsk_tmp'
./tools/img4 -i "$IPSW_EXT_OUTPUT/$BM_RDSK_PATH" -o "$BM_RDSK_PATH_BASE"
hdiutil attach "$BM_RDSK_PATH_BASE" -mountpoint 'rdsk_tmp'
./tools/bspatch 'rdsk_tmp/usr/local/bin/restored_external' 'rdsk_tmp/usr/local/bin/restored_external' "patches/$BUILD/restored_external.bspatch43"
./tools/bspatch 'rdsk_tmp/usr/sbin/asr_ramdisk' 'rdsk_tmp/usr/sbin/asr_ramdisk' "patches/$BUILD/asr_ramdisk.bspatch43"
./tools/ldid_macosx_arm64 -S -M 'rdsk_tmp/usr/local/bin/restored_external'
./tools/ldid_macosx_arm64 -S -M 'rdsk_tmp/usr/sbin/asr_ramdisk'
hdiutil detach 'rdsk_tmp'
rm -r 'rdsk_tmp'
./tools/img4tool -c "$IPSW_EXT_OUTPUT/$BM_RDSK_PATH" -t 'rdsk' "$BM_RDSK_PATH_BASE"
rm "$BM_RDSK_PATH_BASE"

echo "Extracting AVPBooter image from OS ($BM_OS_PATH)..."
mkdir -p 'rootfs_tmp'
hdiutil attach "$IPSW_EXT_OUTPUT/$BM_OS_PATH" -mountpoint 'rootfs_tmp'
mkdir -p "avpbooter-images/$BUILD"
cp 'rootfs_tmp/System/Library/Frameworks/Virtualization.framework/Versions/A/Resources/AVPBooter.vmapple2.bin' 'avpbooter-images/AVPBooter.vmapple2.bin' "avpbooter-images/$BUILD/"
hdiutil detach 'rootfs_tmp'
rm -r 'rootfs_tmp'
echo 'Patching AVPBooter...'
./tools/bspatch "avpbooter-images/$BUILD/AVPBooter.vmapple2.bin" "avpbooter-images/$BUILD/AVPBooter.vmapple2.bin" "patches/$BUILD/AVPBooter.bspatch43"
echo "Patched AVPBooter is located at avpbooter-images/$BUILD/AVPBooter.vmapple2.bin. Please copy and use this as needed (e.g., to ~/.tart/vms/<VM name>/AVPBooter.vmapple2.bin if using super-tart)."

echo "Finished preparing $IPSW_EXT_OUTPUT!"
echo "Restore with: ./vma2pwn.sh restore $IPSW_EXT_OUTPUT"
