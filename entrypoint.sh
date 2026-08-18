#!/bin/bash
set -e

OUTPUT_MODE="${OUTPUT_MODE:-1024x768@60}"
TIMEZONE="${TIMEZONE:-UTC}"
KDE_PASSWORD="${KDE_PASSWORD:-SuperSecretAgent}"
WALLPAPER_URL="${WALLPAPER_URL:-https://storage.humanz.moe/humanz-blog/kano_indie.jpg}"
ROOTLESS="${ROOTLESS:-false}"

if [ "$OUTPUT_NAME" = "" ]; then
  echo OUTPUT_NAME env is empty, trying to find one
  export OUTPUT_NAME=$(for i in $(ls /sys/class/drm/*/status); do   grep connected -owq "$i" && basename $(dirname "$i") | sed 's/^card[0-9]*-//'; done)

  if [ "$OUTPUT_NAME" = "" ]; then
    echo "[ERROR] Display not found"
    exit 1
  fi
  echo Found the Output $OUTPUT_NAME with $OUTPUT_MODE
fi

echo "Set gid for video,render"
# Set the video,render group
vid_gid=$(stat -c "%g" /dev/dri/card* | head -n 1)
if ! grep -q ${vid_gid} /etc/group; then
  sudo groupmod -g ${vid_gid} video
fi

ren_gid=$(stat -c "%g" /dev/dri/renderD* | head -n 1)
if ! grep -q "$ren_gid" /etc/group; then
  sudo groupmod -g ${ren_gid} render
fi


# Set timezone to UTC
sudo -E ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# Set password
echo "kde:$KDE_PASSWORD" | sudo -E chpasswd

# Fetch wallpaper
curl -s -o /tmp/wallpaper.jpg $WALLPAPER_URL

# seatd manages device/seat access (VT switching, input, DRM master)
# without needing a full systemd-logind stack inside the container.
sudo -E seatd -g seat &
SEATD_PID=$!
sleep 1

sudo setcap 'cap_sys_admin=+ep cap_sys_nice=+ep' /usr/bin/sunshine
sudo -E /lib/systemd/systemd-udevd --daemon

# Start dbus as user
dbus-daemon --config-file=/usr/share/dbus-1/system.conf
# startplasma-wayland auto-detects it's running on a bare seat (no existing
# WAYLAND_DISPLAY/DISPLAY) and will launch kwin_wayland with the DRM backend,
# taking over the HDMI output directly.
sudo su - kde bash -c "\
  export XDG_RUNTIME_DIR=/run/user/1000; \
  export XDG_SESSION_TYPE=wayland; \
  export KWIN_DRM_SW_CURSOR=1; \
  export KWIN_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1; \
  dbus-run-session bash -c '\
    pipewire & \
    sleep 1; \
    wireplumber & \
    sleep 1; \
    pipewire-pulse & \
    sleep 1; \
    exec startplasma-wayland & \
    PLASMA_PID=\$!; \
    for i in \$(seq 1 30); do \
      echo \"Waiting for Wayland socket...\"; \
      [ -S \"\$XDG_RUNTIME_DIR/wayland-0\" ] && break; \
      sleep 1; \
    done; \
    sleep 3; \
    echo \"Wayland socket ready, Set Display Resolution&Wallpaper...\"; \
    export DISPLAY=:0 ;\
    if [ -n \"$OUTPUT_NAME\" ] && [ -n \"$OUTPUT_MODE\" ]; then \
      kscreen-doctor output.$OUTPUT_NAME.scale.1; \
      kscreen-doctor output.$OUTPUT_NAME.mode.$OUTPUT_MODE; \
      plasma-apply-wallpaperimage /tmp/wallpaper.jpg; \
      kwriteconfig6 --file /home/kde/.config/powerdevilrc --notify --group AC --group Display --key TurnOffDisplayIdleTimeoutSec -- -1 && \
        kwriteconfig6 --file konsolerc --group \"Desktop Entry\" --key \"DefaultProfile\" \"DefaultProfile.profile\" && \
        qdbus6 org.freedesktop.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.reparseConfiguration && \
        qdbus6 org.freedesktop.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus
    fi; \
    export XAUTHORITY=/run/user/1000/xauth_*; \

    if [ "$ROOTLESS" = "true" ]; then
      sudo rm /etc/sudoers.d/kde
    fi

    echo \"Starting Sunshine...\"; \
    env WAYLAND_DISPLAY=wayland-0 XDG_SESSION_TYPE=wayland sunshine /home/kde/.config/sunshine/sunshine.conf
  '"