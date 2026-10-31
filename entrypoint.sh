#!/bin/bash
set -e

OUTPUT_MODE="${OUTPUT_MODE:-1024x768@60}"
TIMEZONE="${TIMEZONE:-UTC}"
KDE_PASSWORD="${KDE_PASSWORD:-SuperSecretAgent}"
WALLPAPER_URL="${WALLPAPER_URL:-https://storage.humanz.moe/humanz-blog/kano_indie.jpg}"
LOCK_SCRREN_WALLPAPER_URL="${LOCK_SCRREN_WALLPAPER_URL:-$WALLPAPER_URL}"
PROFILE_PIC_RUL="${PROFILE_PIC_RUL:-https://storage.humanz.moe/humanz-blog/EMi9P6hUYAAYTlB-modified.png}"
ROOTLESS="${ROOTLESS:-false}"
AUTO_START="${AUTO_START:-steam}"

if [ "$OUTPUT_NAME" = "" ]; then
  echo OUTPUT_NAME env is empty, trying to find one
  for status in /sys/class/drm/*/status; do
    if grep -qw connected "$status"; then
      OUTPUT_NAME=$(basename "$(dirname "$status")")
      export OUTPUT_NAME="${OUTPUT_NAME#card[0-9]*-}"
      break
    fi
  done

  if [ "$OUTPUT_NAME" = "" ]; then
    echo "[ERROR] Display not found"
    exit 1
  fi
  echo Found the Output $OUTPUT_NAME with $OUTPUT_MODE
fi

# Align group gids with the device nodes passed into the container
set_group_gid() {
  local group="$1" gid
  shift
  gid=$(stat -c "%g" "$@" | head -n 1)
  getent group "$gid" >/dev/null || sudo groupmod -g "$gid" "$group"
}

echo "Set gid for video,render"
set_group_gid video /dev/dri/card*
set_group_gid render /dev/dri/renderD*


# Set timezone to UTC
sudo -E ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

# Set password
echo "kde:$KDE_PASSWORD" | sudo -E chpasswd

# Fetch wallpaper
TMP_FILE=$(mktemp -d)
pids=()
curl -s -o "${TMP_FILE}/wallpaper.png" "$WALLPAPER_URL" & pids+=($!)
curl -s -o "${TMP_FILE}/lock_wallpaper.png" "$LOCK_SCRREN_WALLPAPER_URL" & pids+=($!)
curl -s -o /home/kde/.face.png "$PROFILE_PIC_RUL" & pids+=($!)
for pid in "${pids[@]}"; do wait "$pid"; done
ln -sf /home/kde/.face.png /home/kde/.face.icon

# Set auto start
IFS="," read -ra APPS <<< "$AUTO_START"
mkdir -p /home/kde/.config/autostart/
for app in "${APPS[@]}"; do
    src="/usr/share/applications/${app}.desktop"
    echo "Validate ${app} desktop file"
    if [ -f "$src" ]; then
      echo "Copy ${app} desktop file into autostart"
      cp "$src" /home/kde/.config/autostart/
    else
      echo "[WARN] $src not found, skipping"
    fi
done

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
    touch \"\$XDG_RUNTIME_DIR/.plasma-start\"; \
    exec startplasma-wayland & \
    PLASMA_PID=\$!; \
    for i in \$(seq 1 30); do \
      echo \"Waiting for Wayland socket...\"; \
      WAYLAND_NAME=\$(find \"\$XDG_RUNTIME_DIR\" -maxdepth 1 -type s -name \"wayland-*\" -newer \"\$XDG_RUNTIME_DIR/.plasma-start\" -printf \"%f\n\" | head -n 1); \
      [ -n \"\$WAYLAND_NAME\" ] && break; \
      sleep 1; \
    done; \
    sleep 3; \
    export WAYLAND_DISPLAY=\${WAYLAND_NAME:-wayland-0}; \
    echo \"Wayland socket \$WAYLAND_DISPLAY ready, Set Display Resolution&Wallpaper...\"; \
    if [ -n \"$OUTPUT_NAME\" ] && [ -n \"$OUTPUT_MODE\" ]; then \
      kscreen-doctor output.$OUTPUT_NAME.scale.1; \
      kscreen-doctor output.$OUTPUT_NAME.mode.$OUTPUT_MODE; \
      plasma-apply-wallpaperimage $TMP_FILE/wallpaper.png; \
      kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image \"file://$TMP_FILE/lock_wallpaper.png\"; \
      kwriteconfig6 --file /home/kde/.config/powerdevilrc --notify --group AC --group Display --key TurnOffDisplayIdleTimeoutSec -- -1 && \
        kwriteconfig6 --file konsolerc --group \"Desktop Entry\" --key \"DefaultProfile\" \"DefaultProfile.profile\" && \
        qdbus6 org.freedesktop.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.reparseConfiguration && \
        qdbus6 org.freedesktop.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus
    fi; \
    export XAUTHORITY=/run/user/1000/xauth_*; \

    if [ "$ROOTLESS" = "true" ]; then
      sudo rm /etc/sudoers.d/kde
    fi

    if [ -f /tmp/non_steam.sh ]; then \
      chmod +x /tmp/non_steam.sh; \
      /tmp/non_steam.sh; \
    fi; \

    echo \"Starting Sunshine...\"; \
    env WAYLAND_DISPLAY=\$WAYLAND_DISPLAY XDG_SESSION_TYPE=wayland sunshine /home/kde/.config/sunshine/sunshine.conf
  '"