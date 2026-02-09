# VirtualBox VM Creation with VBoxManage

This guide explains how to create a VirtualBox virtual machine using the `VBoxManage` command-line interface.

## Prerequisites

- VirtualBox installed on your system
- An ISO file for the operating system you want to install
- Sufficient disk space and system resources

## Creating the Debian VM

### Step 1: Create the VM

```bash
VBoxManage createvm --name "Debian" --ostype "Debian_64" --register
```

### Step 2: Configure RAM and CPUs

```bash
VBoxManage modifyvm "Debian" --memory 6144 --cpus 2
```

### Step 3: Create Virtual Hard Disk

```bash
VBoxManage createhd --filename "$HOME/VirtualBox VMs/Debian/Debian.vdi" --size 122880 --format VDI
```

### Step 4: Add Storage Controller

```bash
VBoxManage storagectl "Debian" --name "SATA Controller" --add sata --bootable on
```

### Step 5: Attach Hard Disk

```bash
VBoxManage storageattach "Debian" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/Debian/Debian.vdi"
```

### Step 6: Attach ISO

```bash
VBoxManage storageattach "Debian" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium /path/to/debian.iso
```

### Step 7: Configure Network

```bash
# Adapter 1: Host-only for static IP (192.168.56.10)
VBoxManage modifyvm "Debian" --nic1 hostonly --hostonlyadapter1 vboxnet0

# Adapter 2: NAT for internet access
VBoxManage modifyvm "Debian" --nic2 nat
```

### Step 8: Additional Settings

```bash
# Enable I/O APIC (required for multiple CPUs)
VBoxManage modifyvm "Debian" --ioapic on

# Configure boot order
VBoxManage modifyvm "Debian" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Enable clipboard and drag-and-drop (optional)
VBoxManage modifyvm "Debian" --clipboard bidirectional --draganddrop bidirectional

# Configure serial port for text console access
VBoxManage modifyvm "Debian" --uart1 0x3F8 4 --uartmode1 server /tmp/debian-serial
```

### Step 9: Start the VM (Headless Mode)

```bash
# Start VM without GUI (headless mode)
VBoxManage startvm "Debian" --type headless
```

### Step 10: Connect to Serial Console

In a separate terminal, connect to the VM's serial console:

```bash
# Using socat (recommended)
socat UNIX-CONNECT:/tmp/debian-serial -,raw,echo=0

# Alternative: using screen
# screen /tmp/debian-serial

# To disconnect from socat: Ctrl+C
# To disconnect from screen: Ctrl+A then K
```

## Creating the Proxmox VM

### Step 1: Create the VM

```bash
VBoxManage createvm --name "Proxmox" --ostype "Debian_64" --register
```

### Step 2: Configure RAM and CPUs

```bash
VBoxManage modifyvm "Proxmox" --memory 6144 --cpus 2
```

### Step 3: Create Virtual Hard Disk

```bash
VBoxManage createhd --filename "$HOME/VirtualBox VMs/Proxmox/Proxmox.vdi" --size 122880 --format VDI
```

### Step 4: Add Storage Controller

```bash
VBoxManage storagectl "Proxmox" --name "SATA Controller" --add sata --bootable on
```

### Step 5: Attach Hard Disk

```bash
VBoxManage storageattach "Proxmox" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/Proxmox/Proxmox.vdi"
```

### Step 6: Attach ISO

```bash
VBoxManage storageattach "Proxmox" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium /path/to/proxmox.iso
```

### Step 7: Configure Network

```bash
# Adapter 1: Host-only for static IP (192.168.56.11)
VBoxManage modifyvm "Proxmox" --nic1 hostonly --hostonlyadapter1 vboxnet0

# Adapter 2: NAT for internet access
VBoxManage modifyvm "Proxmox" --nic2 nat
```

### Step 8: Enable Nested Virtualization

```bash
# Essential for Proxmox to run VMs inside
VBoxManage modifyvm "Proxmox" --nested-hw-virt on
```

### Step 9: Additional Settings

```bash
# Enable I/O APIC (required for multiple CPUs)
VBoxManage modifyvm "Proxmox" --ioapic on

# Configure boot order
VBoxManage modifyvm "Proxmox" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# PAE/NX for 64-bit support
VBoxManage modifyvm "Proxmox" --pae on

# Configure serial port for text console access
VBoxManage modifyvm "Proxmox" --uart1 0x3F8 4 --uartmode1 server /tmp/proxmox-serial
```

### Step 10: Start the VM (Headless Mode)

```bash
# Start VM without GUI (headless mode)
VBoxManage startvm "Proxmox" --type headless
```

### Step 11: Connect to Serial Console

In a separate terminal, connect to the VM's serial console:

```bash
# Using socat (recommended)
socat UNIX-CONNECT:/tmp/proxmox-serial -,raw,echo=0

# Alternative: using screen
# screen /tmp/proxmox-serial

# To disconnect from socat: Ctrl+C
# To disconnect from screen: Ctrl+A then K
```

## Useful Management Commands

List all VMs:
```bash
VBoxManage list vms
```

Show VM info:
```bash
VBoxManage showvminfo "VM_NAME"
```

Power off VM:
```bash
VBoxManage controlvm "VM_NAME" poweroff
```

Delete VM:
```bash
VBoxManage unregistervm "VM_NAME" --delete
```

Check if VM is running:
```bash
VBoxManage list runningvms
```

## Verification Steps

After completing the installation and configuration:

### Test Network Connectivity

From your host machine:

```bash
# Ping the VMs
ping -c 3 192.168.56.10  # Debian
ping -c 3 192.168.56.11  # Proxmox

# Test SSH access
ssh user@192.168.56.10   # Debian
ssh root@192.168.56.11   # Proxmox

# Test Proxmox web UI (in browser)
https://192.168.56.11:8006
```

From inside each VM, test internet access:

```bash
# Test NAT interface provides internet
ping -c 3 8.8.8.8
ping -c 3 google.com

# Update packages (confirms DNS and internet work)
apt update
```

### Verify Network Interface Configuration

Inside the VM:

```bash
# Check interfaces are up
ip addr show

# Check routing table
ip route show

# Should see two interfaces:
# - enp0s3: 192.168.56.10/11 (host-only)
# - enp0s8: 10.0.x.x (NAT, DHCP)
```

## Configuring Network Interfaces

To configure static network settings in Debian-based systems, edit `/etc/network/interfaces`.

### Basic Configuration File Structure

```bash
# Edit the interfaces file
nano /etc/network/interfaces
```

### Example Configuration for Debian VM

```
# Loopback interface
auto lo
iface lo inet loopback

# Host-only adapter (static IP)
auto enp0s3
iface enp0s3 inet static
    address 192.168.56.10
    netmask 255.255.255.0
    network 192.168.56.0
    broadcast 192.168.56.255

# NAT adapter (DHCP for internet access)
auto enp0s8
iface enp0s8 inet dhcp
```

### Example Configuration for Proxmox VM

```
# Loopback interface
auto lo
iface lo inet loopback

# Host-only adapter (static IP)
auto enp0s3
iface enp0s3 inet static
    address 192.168.56.11
    netmask 255.255.255.0
    network 192.168.56.0
    broadcast 192.168.56.255

# NAT adapter (DHCP for internet access)
auto enp0s8
iface enp0s8 inet dhcp
```

### Configuration Options Explained

- `auto <interface>`: Automatically bring up the interface at boot
- `iface <interface> inet static`: Configure interface with static IP
- `iface <interface> inet dhcp`: Configure interface to use DHCP
- `address`: The static IP address for the interface
- `netmask`: Network mask (255.255.255.0 for /24 network)
- `network`: Network address
- `broadcast`: Broadcast address
- `gateway`: Default gateway (optional, typically on one interface only)
- `dns-nameservers`: DNS servers (e.g., `dns-nameservers 8.8.8.8 8.8.4.4`)

### Adding DNS and Gateway

If you need to add DNS servers and a default gateway:

```
# Host-only adapter with gateway
auto enp0s3
iface enp0s3 inet static
    address 192.168.56.10
    netmask 255.255.255.0
    gateway 192.168.56.1
    dns-nameservers 8.8.8.8 8.8.4.4
```

### Applying Network Configuration Changes

After editing `/etc/network/interfaces`, apply the changes:

```bash
# Method 1: Restart networking service
systemctl restart networking

# Method 2: Bring interface down and up
ifdown enp0s3 && ifup enp0s3
```

## Notes

- Disk size is specified in MiB (1 GiB = 1024 MiB)
- RAM is specified in MiB
- For nested virtualization to work, your physical CPU must support VT-x (Intel) or AMD-V (AMD) and it must be enabled in your BIOS/UEFI
- The VM directory path may vary by operating system. On Linux it's typically `~/VirtualBox VMs/`, on Windows it's `%USERPROFILE%\VirtualBox VMs\`
- Host-only network range: 192.168.56.0/24 (host is 192.168.56.1)
- Suggested IPs: Debian=192.168.56.10, Proxmox=192.168.56.11
- Interface names may vary: `enp0s3/enp0s8` (modern) or `eth0/eth1` (older systems)
