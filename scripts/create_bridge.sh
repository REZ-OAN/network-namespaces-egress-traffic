#!/bin/bash
set -e

BRIDGE_NAME="br_custom"

# Check if the bridge already exists
if ip link show | grep -q "$BRIDGE_NAME"; then
    echo "Bridge '$BRIDGE_NAME' already exists. Skipping creation."
    exit 0
fi

# Create the bridge
sudo ip link add name "$BRIDGE_NAME" type bridge
sudo ip addr add 192.168.1.1/24 dev "$BRIDGE_NAME"
sudo ip link set "$BRIDGE_NAME" up

echo "Custom bridge '$BRIDGE_NAME' created with IP 192.168.1.1/24."