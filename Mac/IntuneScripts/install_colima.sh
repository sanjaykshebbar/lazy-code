#!/bin/bash

INSTALL_DIR="$HOME/.colima_install"
BIN_DIR="$INSTALL_DIR/bin"
COLIMA_VERSION="v0.6.9"
ARCH=$(uname -m)

detect_profile() {
    local shell_name
    shell_name=$(basename "$SHELL")

    if [ "$shell_name" = "zsh" ]; then
        PROFILE="$HOME/.zshrc"
    elif [ "$shell_name" = "bash" ]; then
        if [ -f "$HOME/.bash_profile" ]; then
            PROFILE="$HOME/.bash_profile"
        elif [ -f "$HOME/.bashrc" ]; then
            PROFILE="$HOME/.bashrc"
        else
            PROFILE="$HOME/.bash_profile"
        fi
    else
        PROFILE="$HOME/.profile"
    fi

    [ ! -f "$PROFILE" ] && touch "$PROFILE"
}

update_path() {
    local PATH_ENTRY="export PATH=\"\$PATH:$BIN_DIR\""

    if ! grep -q "$BIN_DIR" "$PROFILE"; then
        echo "" >> "$PROFILE"
        echo "# Colima PATH" >> "$PROFILE"
        echo "$PATH_ENTRY" >> "$PROFILE"
        echo "Added '$BIN_DIR' to PATH in $PROFILE."
    else
        echo "Path already contains '$BIN_DIR'. No update needed."
    fi
}

echo "--- Starting Colima Installation ($COLIMA_VERSION) ---"

if [ "$ARCH" = "arm64" ]; then
    BINARY_URL="https://github.com/abiosoft/colima/releases/download/$COLIMA_VERSION/colima-Darwin-arm64"
elif [ "$ARCH" = "x86_64" ]; then
    BINARY_URL="https://github.com/abiosoft/colima/releases/download/$COLIMA_VERSION/colima-Darwin-amd64"
else
    echo "ERROR: Unsupported architecture: $ARCH"
    exit 1
fi

mkdir -p "$BIN_DIR"

echo "Downloading Colima binary..."
if ! curl -fsSL "$BINARY_URL" -o "$BIN_DIR/colima"; then
    echo "ERROR: Failed to download Colima binary."
    rm -rf "$INSTALL_DIR"
    exit 1
fi

chmod +x "$BIN_DIR/colima"

detect_profile
update_path

echo "--- Colima Installation Finished: $(date) ---"
echo "NEXT STEP: Run 'source $PROFILE' or open a new terminal session."
