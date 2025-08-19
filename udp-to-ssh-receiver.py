#!/usr/bin/env python3
import socket
import json
import os
import sys

UDP_PORT = 5005

# Listen on all available network interfaces
LISTEN_IP = "0.0.0.0"


def main():
    """
    Listens for a single UDP broadcast and then uses the data
    to replace the current process with an SSH connection.
    """
    try:
        # Create a socket for UDP communication
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # Bind the socket to the specified IP and port
        sock.bind((LISTEN_IP, UDP_PORT))
        print(f"Listening for broadcast on port {UDP_PORT}...")
    except OSError as e:
        print(f"Error: Could not bind to port {UDP_PORT}. {e}", file=sys.stderr)
        print(
            "   Is another process (or another instance of this script) already using this port?",
            file=sys.stderr,
        )
        sys.exit(1)

    try:
        # Wait until a packet is received (buffer size of 1024 bytes)
        data, addr = sock.recvfrom(1024)
        print(f"Received packet from {addr[0]}")
    finally:
        # Always close the socket once we have the data
        sock.close()

    try:
        message = json.loads(data.decode("utf-8"))
        ssh_user = message["user"]
        ssh_ip = message["ip"]
        # Use .get() for the hostname to avoid an error if the key is missing
        hostname = message.get("hostname", "N/A")
    except (json.JSONDecodeError, KeyError, UnicodeDecodeError) as e:
        print(f"Error parsing received data: {e}", file=sys.stderr)
        print(f"   Received raw data: {data}", file=sys.stderr)
        sys.exit(1)

    print(f"Found '{hostname}' ({ssh_user}@{ssh_ip}). Attempting to connect...")

    # The ssh command and its arguments must be in a list
    ssh_target = f"{ssh_user}@{ssh_ip}"
    args = ["ssh", ssh_target]

    try:
        os.execvp("ssh", args)
    except FileNotFoundError:
        print("Error: 'ssh' command not found in your system's PATH.", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"Error executing ssh: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
