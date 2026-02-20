# arch-null

Scripted Arch Linux workstation installer. AMD hardware, Hyprland, systemd everything.

## Usage

1. Boot the Arch Linux live ISO
2. Connect to the network and clone this repo:
   ```
   ip link set <INTERFACE> up
   ip addr add <IP>/24 dev <INTERFACE>
   ip route add default via <GATEWAY_IP>
   echo "nameserver 1.1.1.1" > /etc/resolv.conf
   pacman -Sy git
   git clone https://github.com/d3ployment/arch-null.git
   cd arch-null
   ```
3. Edit `config.sh` - set your disk, hostname, username, network, timezone
4. Run the installer:
   ```
   ./install.sh
   ```
5. After first boot, enroll your Yubikey:
   ```
   sudo ./scripts/07-yubikey.sh
   ```
