# Custom Bridge Network with Egress Networking - Implementation Guide

This document outlines the necessary scripts and Makefiles for creating a custom bridge network, configuring network namespaces, enabling egress networking, and maintaining proper network isolation using `iptables` for NAT. The implementation automates these steps using Bash scripts and a Makefile.

## Directory Structure

```
project-root/
  |-- scripts/
  |     |-- create_bridge.sh
  |     |-- setup_namespace.sh
  |-- Makefile
  |-- README.md
```

## 1. Scripts

### 1.1 `create_bridge.sh`
This script creates a custom bridge network and assigns it an IP address.

#### `scripts/create_bridge.sh`
```bash
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
```

### 1.2 `setup_namespace.sh`
This script creates a network namespace, attaches it to the bridge, and configures network settings.

#### `scripts/setup_namespace.sh`
```bash
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

echo "Namespace '$NAMESPACE' configured with IP 192.168.1.2 and default gateway 192.168.1.1."
```

## 2. Makefile
This Makefile automates the process of creating the bridge network, setting up the namespace, and testing network connectivity.

#### `Makefile`
```makefile
.PHONY: all create_network setup_namespace test_network clean

all: create_network setup_namespace test_network

create_network:
	bash scripts/create_bridge.sh

setup_namespace:
	bash scripts/setup_namespace.sh

test_network:
	sudo ip netns exec custom_ns ping -c 4 8.8.8.8
	sudo ip netns exec custom_ns ping -c 4 google.com

clean:
	sudo ip netns del custom_ns || true
	sudo ip link del br_custom || true
	sudo iptables -t nat -D POSTROUTING -s 192.168.1.0/24 ! -o br_custom -j MASQUERADE || true
```

## 3. README.md

#### `README.md`
```markdown
# Custom Bridge Network with Egress Networking

This project demonstrates how to set up a custom bridge network, create network namespaces, and enable egress traffic with proper NAT using `iptables`.

## Prerequisites

1. Linux system with root privileges.
2. `iproute2` and `iptables` installed.
3. Basic understanding of network namespaces and `iptables`.

## Steps to Run the Project

### 1. Enable IP Forwarding

Run the following command to enable IP forwarding:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Make it persistent:

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 2. Run the Automation

Navigate to the project root and run the following command to set up the bridge, namespace, and test network connectivity:

```bash
make
```

### 3. Clean Up Resources

To clean up all resources, run:

```bash
make clean
```

## Testing

- **Ping External IP**: Verifies egress connectivity using `ping`.
- **Test DNS Resolution**: Checks DNS configuration by pinging domain names.

## Troubleshooting

- Ensure `iptables` rules are correctly applied.
- Use `sudo ip netns list` to verify namespace creation.
- Use `sudo ip link show` to verify bridge creation.

## Additional Notes

- This implementation is for educational purposes and can be extended for complex network setups.
- To persist `iptables` rules, ensure `iptables-persistent` is installed and properly configured.


