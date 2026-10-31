#!/bin/bash
set -e

## Download a package and fail if the file is missing or empty
download() {
    local url="$1" dest="$2"
    curl -fL "$url" -o "$dest" || { echo "Download failed: $url" >&2; exit 1; }
    [ -s "$dest" ] || { echo "File missing or empty: $dest" >&2; exit 1; }
}

## Create tmp dir
mkdir -p /tmp/gpu-pkg
if [ "$GPU" = "NVIDIA" ]; then 
    #pacman -S --noconfirm nvidia-utils lib32-nvidia-utils; \
    NVIDIA_PKG="/tmp/gpu-pkg/nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst"
    LIB32_PKG="/tmp/gpu-pkg/lib32-nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst"
    download "https://archive.archlinux.org/packages/l/lib32-nvidia-utils/lib32-nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst" "$LIB32_PKG"
    download "https://archive.archlinux.org/packages/n/nvidia-utils/nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst" "$NVIDIA_PKG"
    pacman --noconfirm -U "$NVIDIA_PKG" "$LIB32_PKG"
else
    ## TODO: Add gpu driver installation for amd
    pacman -S --noconfirm lib32-vulkan-radeon vulkan-radeon;
fi

## Clean up tmp dir
rm -rf /tmp/gpu-pkg