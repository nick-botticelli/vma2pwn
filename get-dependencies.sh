#!/bin/zsh

#
# vma2pwn - get-dependencies.sh
# v0.1.0
#

# Fail-fast
set -e

if [ -f 'tools/.finished' ]; then
    # Exit gracefully; dependencies should already be fully downloaded
    exit 0
fi

echo 'Downloading dependencies...'

# Create output directory
mkdir -p 'tools'

# Download img4tool
curl -sL 'https://github.com/tihmstar/img4tool/releases/download/197/buildroot_macos-latest.zip' -o 'tools/img4tool.zip'
unzip -p 'tools/img4tool.zip' 'buildroot_macos-latest/usr/local/bin/img4tool' > 'tools/img4tool'
rm 'tools/img4tool.zip'
chmod +x 'tools/img4tool'

# Download pzb
curl -sL 'https://github.com/palera1n/palera1n/raw/legacy/binaries/Darwin/pzb' -o 'tools/pzb'
chmod +x 'tools/pzb'

# Download jq
#curl -sL 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64' -o 'tools/jq'
curl -sL 'https://github.com/palera1n/palera1n/raw/legacy/binaries/Darwin/jq' -o 'tools/jq'
chmod +x 'tools/jq'

# Download Procursus ldid
curl -sL 'https://github.com/ProcursusTeam/ldid/releases/download/v2.1.5-procursus7/ldid_macosx_arm64' -o 'tools/ldid_macosx_arm64'
chmod +x 'tools/ldid_macosx_arm64'

# Download img4
curl -sL 'https://github.com/nick-botticelli/vma2pwn-tools/raw/eb8b76bd96c040dd203ef611829870cbb072bcd1/img4' -o 'tools/img4'
chmod +x 'tools/img4'

# Download bspatch (from bsdiff)
curl -sL 'https://github.com/nick-botticelli/vma2pwn-tools/raw/eb8b76bd96c040dd203ef611829870cbb072bcd1/bspatch' -o 'tools/bspatch'
chmod +x 'tools/bspatch'

# Mark the tools directory as fully initialized
touch 'tools/.finished'

echo 'Finished downloading dependencies!'
