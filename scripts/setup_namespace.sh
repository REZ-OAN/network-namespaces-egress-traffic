#!/bin/bash
set -e

NAMESPACE="custom_ns"
VETH0="veth0"
VETH1="veth1"

# Check if the namespace already exists
if ip netns list | grep -q "$NAMESPACE"; then
    echo "Namespace '$NAMESPACE' already exists. Skipping creation."
    exit 0
fi

# Create the namespace
sudo ip netns add "$NAMESPACE"

# Create a veth pair
sudo ip link add "$VETH0" type veth peer name "$VETH1"

# Attach one end to the namespace
sudo ip link set "$VETH1" netns "$NAMESPACE"

# Attach the other end to the bridge
sudo ip link set "$VETH0" master br_custom
sudo ip link set "$VETH0" up

# Configure namespace network
sudo ip netns exec "$NAMESPACE" ip addr add 192.168.1.2/24 dev "$VETH1"
sudo ip netns exec "$NAMESPACE" ip link set "$VETH1" up
sudo ip netns exec "$NAMESPACE" ip route add default via 192.168.1.1

echo "Namespace '$NAMESPACE' configured with IP 192.168.1.2 and default gateway 192.168.1.1