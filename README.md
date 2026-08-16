# k8s-matahari

A Kubernetes-based containerized desktop environment powered by Matahari and KDE Plasma, with GPU support and remote streaming via Sunshine.

## Overview

This project enables running a fully-featured KDE Plasma desktop in Kubernetes using containers. It includes:

- **Multi-distribution support**: Dockerfiles for Arch Linux and openSUSE
- **GPU acceleration**: NVIDIA GPU support for accelerated graphics
- **Remote streaming**: Sunshine server for remote desktop access
- **Kubernetes deployment**: Helm charts for easy K8s deployment
## Project Structure

```
├── Dockerfile.archlinux           # Arch Linux container image
├── Dockerfile.opensuse            # openSUSE container image
├── entrypoint.sh                  # Container startup script
├── Makefile                       # Build and run commands
├── charts/                        # Kubernetes deployment files
│   └── matahari/
│       ├── Chart.yaml             # Helm chart metadata
│       ├── values.yaml            # Default configuration
│       └── templates/             # K8s resource templates
├── infrastructure/
│   └── runtimeclass/              # Kubernetes runtime configurations
├── pkg/                           # Package resources
│   ├── arch-nvidia.sh             # NVIDIA setup for Arch
│   ├── opensuse-nvidia.sh         # NVIDIA setup for openSUSE
│   └── sunshine-*.rpm             # Sunshine streaming server
```

## Quick Start

### Prerequisites

- Docker (for local testing) or Kubernetes cluster
- NVIDIA GPU and drivers (for GPU support)
- Helm 3+ (for Kubernetes deployment)
- Make (for convenience targets)

### Local Docker Usage

Build and run the container locally:

```bash
# Build the Docker image
make build

# Run the container
make run

# View logs
make logs

# Get a shell in the running container
make shell

# Stop the container
make stop

# Clean up resources
make clean
```

### Configuration

Edit the `Makefile` variables to customize:
- `IMAGE_NAME` - Container registry and tag
- `PORTS` - Sunshine streaming ports
- `VOLUME` - Sunshine configuration volume
- `TIMEZONE` - Container timezone
- `RESOLUTION` - Display resolution (e.g., `1920x1080@144`)

### Environment Variables

- `OUTPUT_MODE` - Display resolution (default: `1024x768@60`)
- `TIMEZONE` - Container timezone (default: `UTC`)
- `KDE_PASSWORD` - KDE user password (default: `SuperSecretAgent`)
- `WALLPAPER_URL` - Wallpaper image URL
- `ROOTLESS` - Run rootless mode (default: `false`)

## Kubernetes Deployment

### Using Helm

Deploy to your Kubernetes cluster:

```bash
helm install matahari ./charts/matahari \
  -f charts/matahari-override-values.yaml
```

### Configuration

- **Chart**: [charts/matahari/Chart.yaml](charts/matahari/Chart.yaml)
- **Values**: [charts/matahari/values.yaml](charts/matahari/values.yaml)
- **Overrides**: [charts/matahari-override-values.yaml](charts/matahari-override-values.yaml)

### Runtime Classes

The project includes Kubernetes runtime class configurations for specialized execution:

- Location: [infrastructure/runtimeclass/](infrastructure/runtimeclass/)

## Features

### GPU Support

- NVIDIA GPU access via device mappings
- Automatic driver detection and group configuration
- Support for multiple GPUs

### Desktop Environment

- **KDE Plasma Wayland** - Modern Wayland-based KDE desktop
- **PipeWire** - Advanced audio/video framework
- **systemd-udevd** - Device management

### Remote Access

- **Sunshine** - Cloud gaming and remote desktop server
- Configurable ports for streaming
- Persistent configuration storage

## Building

### Docker Images

Choose your preferred distribution:

```bash
# Arch Linux
docker build -t matahari:archlinux -f Dockerfile.archlinux .

# openSUSE
docker build -t matahari:opensuse -f Dockerfile.opensuse .
```

Both images include:
- KDE Plasma desktop
- NVIDIA GPU drivers and utilities
- Sunshine streaming server
- All necessary runtime dependencies

## Architecture & Device Access

The container requires specific capabilities and device access:

**Capabilities**:
- `NET_ADMIN` - Network administration
- `SYS_ADMIN` - System administration
- `SYS_PTRACE` - Process tracing
- `CAP_SYS_NICE` - Process priority

**Devices**:
- `/dev/fuse` - Filesystem in userspace
- `/dev/dri/*` - GPU/graphics
- `/dev/sound/*` - Audio
- `/dev/input/*` - Input devices
- `/dev/uinput`, `/dev/uhid` - Input emulation
- `/dev/tty0` - Terminal device

## Networking

Sunshine streams on the following ports:

- `47984-47990/tcp` - Sunshine control
- `48010/tcp` - Sunshine video
- `47998-48000/udp` - Sunshine audio/control

Map these ports to the host or expose them in your Kubernetes service.

## Troubleshooting

### No GPU detected

Ensure:
1. NVIDIA drivers are installed on the host
2. `--gpus all` flag is passed to Docker
3. `/dev/dri` is accessible and mounted

### Wayland socket issues

The script waits up to 30 seconds for the Wayland socket. Check container logs:

```bash
make logs
```

### Resolution not applying

Verify:
1. `OUTPUT_NAME` is correctly detected or set
2. `OUTPUT_MODE` is a supported resolution
3. GPU is properly initialized

## Contributing

Contributions are welcome. Please ensure:
- Changes work on all supported distributions
- GPU functionality remains intact
- Kubernetes integration is maintained

## License

[Add license information here]

## Related Projects

- [Sunshine](https://github.com/LizardByte/Sunshine) - Remote desktop server
- [KDE Plasma](https://kde.org/plasma-desktop/) - Desktop environment