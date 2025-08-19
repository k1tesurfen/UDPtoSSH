#!/bin/bash

# --- File and Path Definitions ---
SCRIPT_FILE="udp-to-ssh-emitter.sh"
SERVICE_FILE="udp-to-ssh-emitter.service"
INSTALL_DIR_SCRIPT="/usr/local/bin/"
INSTALL_DIR_SERVICE="/etc/systemd/system/"
SERVICE_NAME="udp-to-ssh-emitter.service"

# Dynamically get the name of the user executing the script
USER_NAME=$(whoami)

# --- Functions ---
install_script() {
  echo "Installing $SCRIPT_FILE to $INSTALL_DIR_SCRIPT..."

  # Check if the script file exists in the current directory
  if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Error: $SCRIPT_FILE not found in the current directory. Aborting."
    exit 1
  fi

  # Move the script to the installation directory
  sudo mv "$SCRIPT_FILE" "$INSTALL_DIR_SCRIPT"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to move $SCRIPT_FILE. Check permissions."
    exit 1
  fi

  # Set correct permissions to make the script executable
  sudo chmod 755 "$INSTALL_DIR_SCRIPT$SCRIPT_FILE"
  echo "$SCRIPT_FILE installed and permissions set."
}

install_service() {
  echo "Installing $SERVICE_FILE to $INSTALL_DIR_SERVICE..."

  # Check if the service file exists in the current directory
  if [ ! -f "$SERVICE_FILE" ]; then
    echo "Error: $SERVICE_FILE not found in the current directory. Aborting."
    exit 1
  fi

  # Read the service file content
  SERVICE_CONTENT=$(cat "$SERVICE_FILE")

  # Replace the placeholder username with the dynamic user name
  # The placeholder is now 'YOUR_USERNAME_HERE' instead of a specific user.
  UPDATED_SERVICE_CONTENT=$(echo "$SERVICE_CONTENT" | sed "s/User=CUSTOM_USERNAME/User=$USER_NAME/")

  # Write the updated content to the service file in the correct location
  echo "$UPDATED_SERVICE_CONTENT" | sudo tee "$INSTALL_DIR_SERVICE$SERVICE_FILE" >/dev/null
  if [ $? -ne 0 ]; then
    echo "Error: Failed to write updated service file. Check permissions."
    exit 1
  fi

  # Set correct permissions for the service file
  sudo chmod 644 "$INSTALL_DIR_SERVICE$SERVICE_FILE"
  echo "$SERVICE_FILE installed and permissions set."
}

enable_service() {
  echo "Reloading systemd and enabling the service..."

  # Reload systemd daemon to recognize the new service file
  sudo systemctl daemon-reload

  # Enable the service to start on boot
  sudo systemctl enable "$SERVICE_NAME"

  # Start the service immediately
  sudo systemctl start "$SERVICE_NAME"

  echo "Service $SERVICE_NAME is enabled and started."
  echo "You can check its status with 'sudo systemctl status $SERVICE_NAME'."
}

# --- Main Execution ---
echo "Starting IP Emitter installation..."

# Install the script and service files
install_script
install_service

# Enable and start the service
enable_service

echo "Installation complete. The IP Emitter service should now be running and will restart automatically."
