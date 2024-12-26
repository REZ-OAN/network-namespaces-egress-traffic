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