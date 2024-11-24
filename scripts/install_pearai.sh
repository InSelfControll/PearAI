#!/bin/bash
# Source external configuration and utility scripts
source "$(dirname "$0")/pearai_config.sh"
source "$(dirname "$0")/utils.sh"

# Ensure a log file is set up
ensure_log_file

# Trap for handling interruptions and ensuring cleanup
trap 'handle_interrupt' INT TERM

handle_interrupt() {
    log "Installation interrupted. Performing cleanup..."
    cleanup_on_interrupt
    exit 1
}

cleanup_on_interrupt() {
    # Add any necessary cleanup commands here
    # For example, if you have temporary files or directories, remove them
    # Example:
    # rm -rf "$TEMP_DIR"
    log "Cleanup after interruption completed."
}

create_symlink() {
    log "Creating symbolic link for PearAI"

    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        USER_NAME="$SUDO_USER"
    else
        USER_HOME="$HOME"
        USER_NAME=$(whoami)
    fi

    log "Detected user: $USER_NAME"
    log "User home directory: $USER_HOME"

    local source_dir="$USER_CONFIG_DIR"
    local target_link="$USER_CONFIG_DIR_SYMLINK"

    check_directory_exists "$source_dir"
    configure_permissions "$source_dir" "dir" "$USER_NAME"

    if [ -L "$target_link" ] && [ "$(readlink -f "$target_link")" = "$source_dir" ]; then
        log "Correct symbolic link already exists."
        return 0
    fi

    remove_file_or_dir "$target_link" "existing target"

    log "Creating symbolic link '$target_link' -> '$source_dir'..."
    sudo -u "$USER_NAME" ln -s "$source_dir" "$target_link" || handle_error "Failed to create symbolic link"

    configure_permissions "$(dirname "$target_link")" "dir" "$USER_NAME"

    log "Symbolic link created successfully: '$target_link' -> '$source_dir'"
}

extract_files() {
    log "Extracting installation files from the archive..."

    # Check if tarball exists
    check_file_exists "$TARBALL"

    if [ "$IS_NIXOS" = true ]; then
        # Create apps directory in user's home if it doesn't exist
        mkdir -p "$REAL_HOME/apps" || handle_error "Failed to create apps directory"
        mkdir -p "$INSTALL_DIR" || handle_error "Failed to create installation directory $INSTALL_DIR"
        mkdir -p "$REAL_HOME/.local/share/applications" || handle_error "Failed to create applications directory"
        mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps" || handle_error "Failed to create icons directory"
        
        # Set correct ownership for apps directory
        chown "$REAL_USER:users" "$REAL_HOME/apps"
        chmod 755 "$REAL_HOME/apps"
        
        # Extract files
        tar -xzf "$TARBALL" -C "$INSTALL_DIR" || handle_error "Failed to extract tarball $TARBALL"
        
        # Set permissions for the installation directory
        chown -R "$REAL_USER:users" "$INSTALL_DIR" || handle_error "Failed to set ownership of $INSTALL_DIR"
        chmod 755 "$INSTALL_DIR"
        find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
        find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
        [ -f "$INSTALL_DIR/bin/$BINARY" ] && chmod 755 "$INSTALL_DIR/bin/$BINARY"
        
        # Set correct ownership for user-specific directories
        chown "$REAL_USER:users" "$REAL_HOME/.local/share/applications"
        chown -R "$REAL_USER:users" "$REAL_HOME/.local/share/icons"
    else
        mkdir -p "$INSTALL_DIR" || handle_error "Failed to create installation directory $INSTALL_DIR"
        tar -xzf "$TARBALL" -C "$INSTALL_DIR" || handle_error "Failed to extract tarball $TARBALL"
    fi

    log "Files extracted successfully"
}

install_desktop_entries() {
    log "Setting up desktop entries..."

    if [ "$IS_NIXOS" = true ]; then
        # Ensure directory exists
        mkdir -p "$REAL_HOME/.local/share/applications"
        
        # Copy and update desktop files
        cp "$DESKTOP_FILE" "$REAL_HOME/.local/share/applications/$(basename "$DESKTOP_FILE")" || \
            handle_error "Failed to copy $DESKTOP_FILE"
        cp "$URL_HANDLER_FILE" "$REAL_HOME/.local/share/applications/$(basename "$URL_HANDLER_FILE")" || \
            handle_error "Failed to copy $URL_HANDLER_FILE"
        
        # Update paths in desktop files to use the app from user's apps directory
        sed -i "s|Exec=/usr/bin/|Exec=$REAL_HOME/apps/$PKG_NAME/bin/|g" "$REAL_HOME/.local/share/applications/$(basename "$DESKTOP_FILE")"
        sed -i "s|Icon=/usr/share/icons/|Icon=$REAL_HOME/.local/share/icons/|g" "$REAL_HOME/.local/share/applications/$(basename "$DESKTOP_FILE")"
        
        sed -i "s|Exec=/usr/bin/|Exec=$REAL_HOME/apps/$PKG_NAME/bin/|g" "$REAL_HOME/.local/share/applications/$(basename "$URL_HANDLER_FILE")"
        sed -i "s|Icon=/usr/share/icons/|Icon=$REAL_HOME/.local/share/icons/|g" "$REAL_HOME/.local/share/applications/$(basename "$URL_HANDLER_FILE")"
        
        # Set correct ownership and permissions
        chown "$REAL_USER:users" "$REAL_HOME/.local/share/applications/"*
        chmod 644 "$REAL_HOME/.local/share/applications/"*
        
        log "Desktop entries installed in user directory with updated paths"
    else
        # Standard Linux installation
        cp "$DESKTOP_FILE" "$APP_DIR/$(basename "$DESKTOP_FILE")" || handle_error "Failed to copy $DESKTOP_FILE"
        cp "$URL_HANDLER_FILE" "$APP_DIR/$(basename "$URL_HANDLER_FILE")" || handle_error "Failed to copy $URL_HANDLER_FILE"
        configure_permissions "$APP_DIR/$(basename "$DESKTOP_FILE")" "file"
        configure_permissions "$APP_DIR/$(basename "$URL_HANDLER_FILE")" "file"
    fi
}

install_icon() {
    log "Installing the PearAI icon..."

    check_file_exists "$ICON_FILE"

    if [ "$IS_NIXOS" = true ]; then
        # Ensure icon directory exists
        mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
        
        # Copy icon
        cp "$ICON_FILE" "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/$(basename "$ICON_FILE")" || \
            handle_error "Failed to install app icon"
        
        # Set correct ownership and permissions
        chown "$REAL_USER:$(id -gn $REAL_USER)" "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/$(basename "$ICON_FILE")"
        chmod 644 "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/$(basename "$ICON_FILE")"
        
        log "Icon installed in user directory"
    else
        install -Dm644 "$ICON_FILE" "$ICON_DIR/$(basename "$ICON_FILE")" || handle_error "Failed to install app icon"
    fi
}

create_symlink_bin() {
    log "Creating a symlink for PearAI binary..."

    if [ "$IS_NIXOS" = true ]; then
        # Check if binary exists in the apps directory
        check_file_exists "$REAL_HOME/apps/$PKG_NAME/bin/$BINARY"
        
        # Create user's local bin directory if it doesn't exist
        mkdir -p "$REAL_HOME/.local/bin"
        chown "$REAL_USER:users" "$REAL_HOME/.local/bin"
        chmod 755 "$REAL_HOME/.local/bin"
        
        # Remove existing symlink if it exists
        [ -L "$REAL_HOME/.local/bin/$BINARY" ] && rm "$REAL_HOME/.local/bin/$BINARY"
        
        # Create new symlink in user's local bin
        ln -sf "$REAL_HOME/apps/$PKG_NAME/bin/$BINARY" "$REAL_HOME/.local/bin/$BINARY" || \
            handle_error "Failed to create symlink for $BINARY"
        
        # Ensure binary is executable
        chmod 755 "$REAL_HOME/apps/$PKG_NAME/bin/$BINARY"
        chown "$REAL_USER:users" "$REAL_HOME/.local/bin/$BINARY"
        
        log "Binary symlink created in user's local bin directory"
        
        # Update desktop files to use the local bin path
        sed -i "s|Exec=$REAL_HOME/apps/$PKG_NAME/bin/|Exec=$REAL_HOME/.local/bin/|g" \
            "$REAL_HOME/.local/share/applications/$(basename "$DESKTOP_FILE")"
        sed -i "s|Exec=$REAL_HOME/apps/$PKG_NAME/bin/|Exec=$REAL_HOME/.local/bin/|g" \
            "$REAL_HOME/.local/share/applications/$(basename "$URL_HANDLER_FILE")"
    else
        check_file_exists "$INSTALL_DIR/bin/$BINARY"
        ln -sf "$INSTALL_DIR/bin/$BINARY" "$BIN_DIR/$BINARY" || handle_error "Failed to create symlink for $BINARY"
    fi

    log "Symlink created successfully"
}

update_desktop_database() {
    log "Updating desktop database..."

    if [ "$IS_NIXOS" = true ]; then
        if command -v update-desktop-database &> /dev/null; then
            sudo -u "$REAL_USER" update-desktop-database "$REAL_HOME/.local/share/applications" || \
                log "Warning: Failed to update desktop database (non-critical)"
        fi
    else
        if command -v update-desktop-database &> /dev/null; then
            update-desktop-database "$APP_DIR" || handle_error "Failed to update desktop database"
        fi
    fi
}

rebuild_icon_cache() {
    log "Rebuilding icon cache..."

    if [ "$IS_NIXOS" = true ]; then
        if command -v gtk-update-icon-cache &> /dev/null; then
            sudo -u "$REAL_USER" gtk-update-icon-cache "$REAL_HOME/.local/share/icons/hicolor" || \
                log "Warning: Failed to update icon cache (non-critical)"
        fi
    else
        if command -v gtk-update-icon-cache &> /dev/null; then
            gtk-update-icon-cache /usr/share/icons/hicolor || \
                log "Warning: Failed to update icon cache (non-critical)"
        fi
    fi
}

updating_chrome_sandbox_permissions() {
    log "Updating chrome-sandbox permissions..."

    if [ -f "$INSTALL_DIR/chrome-sandbox" ]; then
        if [ "$IS_NIXOS" = true ]; then
            chown root:root "$INSTALL_DIR/chrome-sandbox" || handle_error "Failed to change owner of chrome-sandbox"
            chmod 4755 "$INSTALL_DIR/chrome-sandbox" || handle_error "Failed to set permissions on chrome-sandbox"
        else
            sudo chown root "$INSTALL_DIR/chrome-sandbox" || handle_error "Failed to change owner of chrome-sandbox"
            sudo chmod 4755 "$INSTALL_DIR/chrome-sandbox" || handle_error "Failed to set permissions on chrome-sandbox"
        fi
        log "Permissions for chrome-sandbox updated successfully."
    else
        log "No chrome-sandbox found, skipping this step."
    fi
}

copy_additional_resources() {
    log "Copying additional resources..."

    # Assuming additional resources are in a specific directory within the tarball
    # Adjust the source and destination as needed
    local resources_dir="$INSTALL_DIR/resources"
    local target_resources_dir="$INSTALL_DIR/"

    if [ -d "$resources_dir" ]; then
        cp -r "$resources_dir/"* "$target_resources_dir" || handle_error "Failed to copy additional resources"
        log "Additional resources copied successfully."
    else
        log "No additional resources to copy."
    fi
}

cleanup() {
    log "Cleaning up temporary files..."
    # No temporary files to clean up in this version
    log "Cleanup completed."
}

final_messages() {
    log "Installation of PearAI completed successfully!"
    log "Installation of PearAI completed successfully!"
    log "You can launch PearAI from the applications menu (e.g., GNOME, KDE, etc.) or by typing '$BINARY' in the terminal."
    log "If you experience issues, try logging out and back in."
    log "For further help, feel free to contact us on the PearAI Discord community!"
}

install_pearai() {
    log "Starting PearAI installation..."

    # Ensure the installation is fresh and version checks are performed
    check_fresh_install
    check_version

    extract_files
    create_symlink_bin
    install_desktop_entries
    install_icon
    create_symlink
    updating_chrome_sandbox_permissions
    copy_additional_resources
    update_desktop_database
    rebuild_icon_cache
    cleanup
    final_messages
}

# Execute the installation
install_pearai
