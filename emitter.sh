#!/bin/bash
# Emitter script for continuous IP address broadcasting.

# The message contains all necessary info for the receiver
PI_IP=""
PI_HOSTNAME=$(hostname)
SSH_USER=$(whoami)

# Loop parameters
MAX_WAIT_TIME_ON_STARTUP=120 # Total time to wait for network on boot
BROADCAST_INTERVAL=3         # Interval between broadcasts in seconds

echo "Starting IP Emitter in continuous broadcast mode."

# --- Initial Network Waiting Logic ---
echo "Waiting for network connectivity..."
counter=0
while [ -z "$PI_IP" ] && [ $counter -lt $MAX_WAIT_TIME_ON_STARTUP ]; do
  echo "Network not ready. Retrying in 5 seconds..."
  sleep 5
  PI_IP=$(hostname -I | awk '{print $1}')
  counter=$((counter + 5))
done

# If the network never came up, exit with an error
if [ -z "$PI_IP" ]; then
  echo "ERROR: Network did not become available within $MAX_WAIT_TIME_ON_STARTUP seconds. Exiting."
  exit 1
fi

# --- Main Broadcast Loop ---

while true; do

  # Re-evaluate IP address on each loop in case it changes

  PI_IP=$(hostname -I | awk '{print $1}')

  # Exit if IP address somehow disappears (e.g., network disconnected)

  if [ -z "$PI_IP" ]; then

    echo "WARNING: No IP address found. Network likely disconnected. The script will exit."

    exit 1

  fi

  # Construct the broadcast IP from the Pi's own IP address

  SUBNET_PREFIX=$(echo "$PI_IP" | cut -d'.' -f1-3)

  BROADCAST_IP="$SUBNET_PREFIX.255"

  # Construct the JSON message with the correct info

  MESSAGE="{\"ip\":\"$PI_IP\", \"user\":\"$SSH_USER\", \"hostname\":\"$PI_HOSTNAME\"}"

  UDP_PORT=5005

  # Send the message as a UDP broadcast, suppressing errors

  echo "Broadcasting message to $BROADCAST_IP..."

  echo "$MESSAGE" | nc -u -w 1 -b "$BROADCAST_IP" "$UDP_PORT" 2>/dev/null

  # Wait for the next broadcast

  sleep "$BROADCAST_INTERVAL"

done

exit 0
