#!/bin/bash

## Create tmp dir
mkdir -p /tmp/gpu-pkg
if [ "$GPU" = "NVIDIA" ]; then 
    #pacman -S --noconfirm nvidia-utils lib32-nvidia-utils; \
    wget -q https://archive.archlinux.org/packages/l/lib32-nvidia-utils/lib32-nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst \
            -O /tmp/gpu-pkg/lib32-nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst 
    wget -q https://archive.archlinux.org/packages/n/nvidia-utils/nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst \
            -O /tmp/gpu-pkg/nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst 
    pacman --noconfirm -U /tmp/gpu-pkg/nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst
    pacman --noconfirm -U /tmp/gpu-pkg/lib32-nvidia-utils-${NVIDIA_DRIVER_VERSION}-x86_64.pkg.tar.zst 
else
    ## TODO: Add gpu driver installation for amd
    pacman -S --noconfirm lib32-vulkan-radeon vulkan-radeon;
fi

## Clean up tmp dir
rm -rf /tmp/gpu-pkg