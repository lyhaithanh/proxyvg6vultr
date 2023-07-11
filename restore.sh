restore_configuration() {
    # Khôi phục tệp tin /etc/sysctl.conf từ bản sao đã sao lưu
    cp /etc/sysctl.conf.backup /etc/sysctl.conf
    
    # Xóa 3proxy và các tệp tin liên quan
    rm -rf /3proxy /usr/local/etc/3proxy /usr/lib/systemd/system/3proxy.service
    
    # Xóa các quy tắc iptables đã cấu hình
    sed -i '/iptables -I INPUT -p tcp --dport/d' /etc/rc.local
    
    # Xóa địa chỉ IPv6 đã thêm cho giao diện chính
    sed -i '/ifconfig '$main_interface' inet6 add/d' /etc/rc.local
    
    # Xóa các dòng cấu hình iptables và ifconfig khỏi /etc/rc.local
    sed -i '/bash \/home\/proxy-installer\/boot_iptables.sh/d' /etc/rc.local
    sed -i '/bash \/home\/proxy-installer\/boot_ifconfig.sh/d' /etc/rc.local
    
    # Xóa tệp tin proxy.txt
    rm -f /home/proxy-installer/proxy.txt
    
    # Đặt lại quyền giới hạn file mặc định
    sed -i '/\* hard nofile/d' /etc/security/limits.conf
    sed -i '/\* soft nofile/d' /etc/security/limits.conf
    
    # Đặt lại cấu hình IPv6 và sysctl
    sed -i '/net.ipv6.conf.$main_interface.proxy_ndp=1/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.all.proxy_ndp=1/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.forwarding=1/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.all.forwarding=1/d' /etc/sysctl.conf
    sed -i '/net.ipv6.ip_nonlocal_bind = 1/d' /etc/sysctl.conf
    
    # Đặt lại giới hạn số file mở tối đa
    ulimit -n 4096
}
