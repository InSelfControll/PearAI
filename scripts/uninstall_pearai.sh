#!/bin/bash

source "$(dirname "$0")/pearai_config.sh"
source "$(dirname "$0")/utils.sh"

ensure_log_file

uninstall_pearai() {
    log "Starting PearAI uninstallation..."

    if [ "$IS_NIXOS" = true ]; then
        # Remove desktop files
        rm -f "$REAL_HOME/.local/share/applications/$(basename "$DESKTOP_FILE")"
        rm -f "$REAL_HOME/.local/share/applications/$(basename "$URL_HANDLER_FILE")"
        
        # Remove icon
        rm -f "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/$(basename "$ICON_FILE")"
        
        # Remove symlink from local bin
        rm -f "$REAL_HOME/.local/bin/$BINARY"
        
        # Remove app directory
        rm -rf "$REAL_HOME/apps/$PKG_NAME"
        
        # Remove config files
        rm -f "$USER_CONFIG_DIR_SYMLINK"
        rm -rf "$USER_CONFIG_DIR"
        
        # Remove apps directory if empty
        rmdir "$REAL_HOME/apps" 2>/dev/null || true
        
        # Update desktop database
        if command -v update-desktop-database &> /dev/null; then
            sudo -u "$REAL_USER" update-desktop-database "$REAL_HOME/.local/share/applications" || \
                log "Warning: Failed to update desktop database (non-critical)"
        fi
    else
        remove_file_or_dir "$BIN_DIR/$BINARY" "$BIN_DIR/$BINARY"
        remove_file_or_dir "$APP_DIR/$(basename "$DESKTOP_FILE")" "$APP_DIR/$(basename "$DESKTOP_FILE")"
        remove_file_or_dir "$APP_DIR/$(basename "$URL_HANDLER_FILE")" "$APP_DIR/$(basename "$URL_HANDLER_FILE")"
        remove_file_or_dir "$ICON_DIR/$(basename "$ICON_FILE")" "$ICON_DIR/$(basename "$ICON_FILE")"
        remove_file_or_dir "$INSTALL_DIR" "$INSTALL_DIR"
        remove_file_or_dir "$USER_CONFIG_DIR_SYMLINK" "$USER_CONFIG_DIR_SYMLINK"
        remove_file_or_dir "$USER_CONFIG_DIR" "$USER_CONFIG_DIR"
    fi
}

uninstall_pearai
