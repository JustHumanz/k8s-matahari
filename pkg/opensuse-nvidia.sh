#!/bin/bash

## Download a package and fail if the file is missing or empty
download() {
    local url="$1" dest="$2"
    curl -fL "$url" -o "$dest" || { echo "Download failed: $url" >&2; exit 1; }
    [ -s "$dest" ] || { echo "File missing or empty: $dest" >&2; exit 1; }
}


## Create tmp dir
mkdir -p /tmp/gpu-pkg
if [ "$GPU" = "NVIDIA" ]; then 
    echo "Download NVIDIA driver"
    download "https://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run" \
        "/tmp/gpu-pkg/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run"
    chmod +x /tmp/gpu-pkg/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run
    /tmp/gpu-pkg/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run --ui=none --no-questions \
        --no-kernel-modules --no-kernel-module-source --no-questions 
else
    ## TODO: Add gpu driver installation for amd
    echo "BipBop"
fi

## Clean up tmp dir
rm -rf /tmp/gpu-pkg