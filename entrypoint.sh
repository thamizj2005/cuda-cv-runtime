#!/bin/bash
# ==============================================================================
#  user-entrypoint.sh
#  Wraps the system entrypoint with Qt / X11 / runtime directory setup.
#  Placed at: /usr/local/bin/user-entrypoint.sh
# ==============================================================================

export XDG_RUNTIME_DIR=/tmp/runtime-root
export QT_X11_NO_MITSHM=1
export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-xcb}
export DISPLAY=${DISPLAY:-:0}
export YOLO_CONFIG_DIR=/home/aiadmin/.ultralytics
export ULTRALYTICS_CONFIG_DIR=/home/aiadmin/.ultralytics

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Start dbus session if not already running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval "$(dbus-launch --sh-syntax)" 2>/dev/null || true
fi

exec "$@"
