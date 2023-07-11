#!/bin/bash

interface="eth0"

# Lấy danh sách các địa chỉ IPv6 trên giao diện
ipv6_addresses=$(ip -6 addr show dev $interface | grep -oP '(?<=inet6\s)[0-9a-f:/]+')

# Duyệt qua từng địa chỉ IPv6 và xóa chúng
for ipv6_address in $ipv6_addresses; do
    ifconfig $interface inet6 del $ipv6_address
done
