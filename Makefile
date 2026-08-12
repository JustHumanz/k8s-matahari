# Makefile for Matahari Docker Container

.PHONY: build run stop clean logs shell

# Variables
IMAGE_NAME := hub.humanz.moe/gaming/matahari:archlinux-kde-latest
CONTAINER_NAME := matahari
PORTS := 47984-47990:47984-47990/tcp 48010:48010 47998-48000:47998-48000/udp
VOLUME := ./config:/home/kde/.config/sunshine/
TIMEZONE := Asia/Jakarta
RESOLUTION := 1920x1080@144

# Build the Docker image
build:
	docker build -t $(IMAGE_NAME) .

# Run the container
run: build
	docker run -it --rm \
		--hostname matahari \
		--cap-add=NET_ADMIN \
		--cap-add=SYS_ADMIN \
		--cap-add=SYS_PTRACE \
		--cap-add=CAP_SYS_NICE \
		--device=/dev/fuse \
		--device=/dev/dri:/dev/dri \
		--device=/dev/tty0:/dev/tty0 \
		--device=/dev/uinput:/dev/uinput \
		--device=/dev/uhid:/dev/uhid \
		--device=/dev/snd:/dev/snd \
		--device=/dev/input:/dev/input \
		--device-cgroup-rule='c 13:* rmw' \
		-v /dev/input:/dev/input \
		-v /run/udev:/run/udev:rw \
		-v /dev/:/dev/:rw \
		-v $(VOLUME) \
		-e OUTPUT_MODE=$(RESOLUTION) \
		-e TIMEZONE=$(TIMEZONE) \
		-p $(PORTS) \
		--gpus all \
		$(IMAGE_NAME)

# Stop the container (if running)
stop:
	docker stop $(CONTAINER_NAME) || true

# Clean up (remove stopped containers, images, etc.)
clean: stop
	docker system prune -f

# View container logs
logs:
	docker logs -f $(CONTAINER_NAME) || echo "No running container found"

# Get a shell inside the running container
shell:
	docker exec -it $(CONTAINER_NAME) /bin/bash || echo "No running container found"

# Rebuild and run
rebuild: clean build run

# Help target
help:
	@echo "Available targets:"
	@echo "  build     - Build the Docker image"
	@echo "  run       - Run the container with default settings"
	@echo "  stop      - Stop the running container"
	@echo "  clean     - Clean up stopped containers and images"
	@echo "  logs      - Show container logs"
	@echo "  shell     - Get a shell in the running container"
	@echo "  rebuild   - Clean, build, and run the container"
	@echo "  help      - Show this help message"