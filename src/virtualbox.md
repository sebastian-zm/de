# VirtualBox with CLI

## Delete data

### Delete VMs

Unregister and delete all associated files (disks, snapshots, etc.):

```bash
VBoxManage unregistervm myvm --delete
```

To unregister without deleting files on disk:

```bash
VBoxManage unregistervm myvm
```

### Delete disks

```bash
VBoxManage closemedium disk /path/to/disk.vdi --delete
```

To find registered disks:

```bash
VBoxManage list hdds
```

### Delete networks

```bash
VBoxManage hostonlyif remove vboxnet0
```

For internal networks and NAT networks:

```bash
VBoxManage natnetwork remove --netname mynatnet
```

Internal networks are removed automatically when no VM references them.

## Create data

### Create disks

```bash
VBoxManage createmedium disk --filename /path/to/disk.vdi --size 20480 --variant Standard
```

`--size` is in MB (20480 = 20 GB). Use `--variant Fixed` for a fixed-size disk instead of dynamically allocated.

### Create networks

VirtualBox supports several network modes:

| Mode | VM to Host | Host to VM | VM to VM | VM to Internet |
|---|---|---|---|---|
| NAT | No | Port forwarding | No | Yes |
| NAT Network | No | Port forwarding | Yes | Yes |
| Bridged | Yes | Yes | Yes | Yes |
| Internal | No | No | Yes (same net) | No |
| Host-Only | Yes | Yes | Yes | No |

- **NAT** — Each VM gets its own isolated NAT router. Simplest way to give a VM internet access. VMs cannot see each other. The default mode.
- **NAT Network** — Like NAT, but multiple VMs share a single NAT router, so they can communicate with each other while still reaching the internet.
- **Bridged** — The VM appears as a physical device on the host's real network. Full visibility in both directions. Requires a physical interface on the host.
- **Internal** — A private network that exists only between VMs. The host cannot access it at all. Useful for isolated lab environments.
- **Host-Only** — A private network between the host and VMs. No internet access. Good for management interfaces.

Create a NAT network:

```bash
VBoxManage natnetwork add --netname mynatnet --network "10.0.2.0/24" --enable --dhcp on
```

Create a host-only interface:

```bash
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
```

Internal networks don't need explicit creation — just reference the same name in each VM's NIC config.

### Create VMs

```bash
VBoxManage createvm --name myvm --ostype Debian_64 --register
```

To list available OS types:

```bash
VBoxManage list ostypes
```

#### Assign RAM and CPUs

```bash
VBoxManage modifyvm myvm --memory 2048 --cpus 2
```

#### Storage controllers and attaching ISOs

Add an IDE controller for optical media and a SATA controller for disks:

```bash
VBoxManage storagectl myvm --name "IDE" --add ide
VBoxManage storagectl myvm --name "SATA" --add sata --controller IntelAhci
```

Attach an ISO to the IDE controller:

```bash
VBoxManage storageattach myvm --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium /path/to/installer.iso
```

#### Attach disks

```bash
VBoxManage storageattach myvm --storagectl "SATA" --port 0 --device 0 --type hdd --medium /path/to/disk.vdi
```

#### Configure networks

Attach a NIC using any of the available modes:

```bash
# NAT (default)
VBoxManage modifyvm myvm --nic1 nat

# NAT Network
VBoxManage modifyvm myvm --nic1 natnetwork --nat-network1 mynatnet

# Bridged
VBoxManage modifyvm myvm --nic1 bridged --bridgeadapter1 eth0

# Internal
VBoxManage modifyvm myvm --nic1 intnet --intnet1 myintnet

# Host-Only
VBoxManage modifyvm myvm --nic1 hostonlyadapter --hostonlyadapter1 vboxnet0
```

Add port forwarding on a NAT NIC (e.g. SSH):

```bash
VBoxManage modifyvm myvm --natpf1 "ssh,tcp,,2222,,22"
```

#### Additional settings

##### I/O APIC

Required for multi-CPU VMs and 64-bit guests:

```bash
VBoxManage modifyvm myvm --ioapic on
```

##### PAE/NX

Enable Physical Address Extension and NX bit support:

```bash
VBoxManage modifyvm myvm --pae on
```

##### Boot order

Set the boot order (up to 4 slots: `dvd`, `disk`, `net`, `none`):

```bash
VBoxManage modifyvm myvm --boot1 dvd --boot2 disk --boot3 none --boot4 none
```

##### Serial port (UART Server)

On a headless machine there is no graphical console. Configure a serial port so the VM's output is accessible over a Unix socket, then connect to it from the host:

```bash
VBoxManage modifyvm myvm --uart1 0x3F8 4 --uartmode1 server /tmp/myvm_serial
```

This creates a Unix socket at `/tmp/myvm_serial`. Connect to it with:

```bash
socat - UNIX-CONNECT:/tmp/myvm_serial
```

For this to be useful the guest OS must output to the serial console. On a Debian/Ubuntu installer, append the following to the kernel boot parameters:

```
console=ttyS0,115200n8
```

### Manage VMs

#### List VMs

```bash
VBoxManage list vms          # all registered VMs
VBoxManage list runningvms   # only running VMs
```

#### Show VM info

```bash
VBoxManage showvminfo myvm
```

#### Start and stop VMs

Start headless (no GUI window):

```bash
VBoxManage startvm myvm --type headless
```

Graceful ACPI shutdown (like pressing the power button):

```bash
VBoxManage controlvm myvm acpipowerbutton
```

Save state (hibernate):

```bash
VBoxManage controlvm myvm savestate
```

Hard power off (last resort):

```bash
VBoxManage controlvm myvm poweroff
```
