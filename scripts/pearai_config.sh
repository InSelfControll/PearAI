#!/bin/bash

# PearAI Configuration File

# PearAI version and package name
PEARAI_VERSION="1.5.0"
PKG_NAME="PearAI"

# Get the real user (even when using sudo)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

# Check if system is NixOS
IS_NIXOS=false
if [ -e "/etc/NIXOS" ]; then
    IS_NIXOS=true
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$BASE_DIR/source"
UTILS_DIR="$BASE_DIR/utils"

# Set installation directories based on system type
if [ "$IS_NIXOS" = true ]; then
    INSTALL_DIR="$REAL_HOME/apps/$PKG_NAME"
    APP_DIR="$REAL_HOME/.local/share/applications"
    ICON_DIR="$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
    BIN_DIR="/usr/bin"
else
    INSTALL_DIR="/opt/$PKG_NAME"
    APP_DIR="/usr/share/applications"
    ICON_DIR="/usr/share/icons/hicolor/256x256/apps"
    BIN_DIR="/usr/bin"
fi

USER_CONFIG_DIR="$REAL_HOME/.config/PearAI"
USER_CONFIG_DIR_SYMLINK="$REAL_HOME/.config/pearai"

# Binary and application files
BINARY="PearAI"
DESKTOP_FILE="$UTILS_DIR/$PKG_NAME.desktop"
URL_HANDLER_FILE="$UTILS_DIR/$PKG_NAME-url-handler.desktop"
ICON_FILE="$UTILS_DIR/pearAI.png"

# Tarball location
TARBALL="$SOURCE_DIR/${PKG_NAME}.tar.gz"

# Log file location
LOG_FILE="/tmp/${PKG_NAME}_install.log"

# Documentation URL
DOCS_URL="https://trypear.ai/docs"
