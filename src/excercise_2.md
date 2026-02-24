# OpenTofu Installation and Proxmox LXC Provisioning

This guide explains how to install OpenTofu on a Debian VM and use it to provision a Debian LXC container in Proxmox.

## Prerequisites

- Debian VM running and accessible (192.168.56.10)
- Proxmox VE running and accessible (192.168.56.11)
- SSH access to both systems
- Network connectivity between Debian VM and Proxmox

## Part 1: Install OpenTofu on Debian VM

### Step 1: SSH into Debian VM

```bash
ssh user@192.168.56.10
```

### Step 2: Install Required Dependencies

```bash
sudo apt update
sudo apt install -y curl gnupg unzip
```

### Step 3: Install OpenTofu

#### Using Official Script (Recommended)

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
./install-opentofu.sh --install-method deb
rm -f install-opentofu.sh
```

### Step 4: Verify OpenTofu Installation

```bash
tofu --version
```

Expected output should show the OpenTofu version.

## Part 2: Prepare Proxmox for API Access

### Step 1: Create API Token in Proxmox

#### Option A: Via Web UI

1. Access Proxmox web interface: `https://192.168.56.11:8006`
2. Navigate to **Datacenter** → **Permissions** → **API Tokens**
3. Click **Add** button
4. Configure token:
   - User: `root@pam`
   - Token ID: `opentofu`
   - Privilege Separation: Uncheck (for full permissions)
5. Click **Add**
6. **Important**: Copy and save the token secret (shown only once)

#### Option B: Via Command Line

SSH into Proxmox and run:

```bash
pveum user token add root@pam opentofu --privsep=0
```

Save the output containing the token secret.

### Step 2: Download LXC Template

SSH into Proxmox and download a Debian container template:

```bash
# Update available templates list
pveam update

# List available Debian templates
pveam available | grep debian

# Download Debian 12 template (adjust version as needed)
pveam download local debian-13-standard_13.1-2_amd64.tar.zst

# Verify download
pveam list local
```

### Step 3: Verify Proxmox Node Name

```bash
# Get node name (usually 'pve' by default)
pvesh get /nodes
```

Note the node name for use in OpenTofu configuration.

### Step 4: Check Network Bridge

```bash
# Verify network bridge exists (usually vmbr0)
ip link show | grep vmbr
```

## Part 3: Create OpenTofu Project

### Step 1: Create Project Directory

On the Debian VM:

```bash
mkdir -p ~/opentofu-proxmox
cd ~/opentofu-proxmox
```

### Step 2: Create Provider Configuration

Create `versions.tf`:

```bash
cat > versions.tf << 'EOF'
terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 7.18.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
EOF
```

### Step 3: Create Provider Settings

Create `provider.tf`:

```bash
cat > provider.tf << 'EOF'
provider "proxmox" {
  pm_api_url          = "https://192.168.56.11:8006/api2/json"
  pm_api_token_id     = "root@pam!opentofu"
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}
EOF
```

### Step 4: Create Variables File

Create `variables.tf`:

```bash
cat > variables.tf << 'EOF'
variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "lxc_template" {
  description = "LXC container template"
  type        = string
  default     = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
}

variable "lxc_hostname" {
  description = "Hostname for the LXC container"
  type        = string
  default     = "debian-lxc"
}

variable "lxc_memory" {
  description = "Memory allocation in MB"
  type        = number
  default     = 1024
}

variable "lxc_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "lxc_rootfs_size" {
  description = "Root filesystem size"
  type        = string
  default     = "8G"
}
EOF
```

### Step 5: Create Main Configuration

Create `main.tf`:

```bash
cat > main.tf << 'EOF'
resource "proxmox_lxc" "debian_container" {
  target_node  = var.proxmox_node
  hostname     = var.lxc_hostname
  ostemplate   = var.lxc_template
  unprivileged = true

  # Resource allocation
  cores  = var.lxc_cores
  memory = var.lxc_memory
  swap   = var.lxc_memory

  # Root filesystem
  rootfs {
    storage = "local-lvm"
    size    = var.lxc_rootfs_size
  }

  # Network configuration
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.56.110/24"
    gw     = "192.168.56.110"
  }

  # Features
  features {
    nesting = true
  }

  # Start settings
  onboot = true
  start  = true

  # Set root password (optional, use SSH keys instead in production)
  # password = "your-secure-password"
}
EOF
```

### Step 6: Create Outputs File

Create `outputs.tf`:

```bash
cat > outputs.tf << 'EOF'
output "container_id" {
  description = "The VMID of the created container"
  value       = proxmox_lxc.debian_container.vmid
}

output "container_hostname" {
  description = "The hostname of the container"
  value       = proxmox_lxc.debian_container.hostname
}

output "container_status" {
  description = "The status of the container"
  value       = "Check with: pct status ${proxmox_lxc.debian_container.vmid}"
}
EOF
```

### Step 7: Create Values File

Create `terraform.tfvars`:

```bash
cat > terraform.tfvars << 'EOF'
# Replace with your actual Proxmox API token secret
proxmox_api_token_secret = "your-token-secret-here"

# Adjust these values as needed
proxmox_node   = "pve"
lxc_hostname   = "debian-lxc"
lxc_memory     = 512
lxc_cores      = 1
lxc_rootfs_size = "8G"
EOF
```

**Important**: Edit `terraform.tfvars` and replace `your-token-secret-here` with your actual Proxmox API token secret.

### Step 8: Create .gitignore

```bash
cat > .gitignore << 'EOF'
# OpenTofu/Terraform files
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
crash.log
crash.*.log
terraform.tfvars
*.tfvars
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc
EOF
```

## Part 4: Deploy the LXC Container

### Step 1: Initialize OpenTofu

```bash
tofu init
```

This downloads the Proxmox provider plugin.

### Step 2: Validate Configuration

```bash
tofu validate
```

### Step 3: Format Configuration Files

```bash
tofu fmt
```

### Step 4: Review the Execution Plan

```bash
tofu plan
```

Review the output to ensure it matches your expectations.

### Step 5: Apply the Configuration

```bash
tofu apply
```

Type `yes` when prompted to confirm.

### Step 6: View Created Resources

```bash
tofu show
```

## Part 5: Verification

### Verify from Proxmox Host

SSH into Proxmox:

```bash
# List all containers
pct list

# Check container status (replace 100 with your container ID)
pct status 100

# View container configuration
pct config 100

# Enter the container
pct enter 100
```

### Verify from Debian VM

```bash
# Check OpenTofu state
tofu output

# Show full state
tofu state list
tofu state show proxmox_lxc.debian_container
```

### Test Container Connectivity

Once inside the container:

```bash
# Check network interfaces
ip addr show

# Test internet connectivity
ping -c 3 8.8.8.8
ping -c 3 google.com

# Update package list
apt update
```

## Part 6: Managing the LXC Container

### Start Container

```bash
# From Proxmox
pct start 100

# From OpenTofu (if stopped manually)
tofu apply
```

### Stop Container

```bash
# From Proxmox
pct stop 100
```

### Destroy Container

```bash
# From OpenTofu project directory
tofu destroy
```

Type `yes` when prompted to confirm deletion.

### Modify Container Configuration

1. Edit the relevant `.tf` files
2. Run `tofu plan` to preview changes
3. Run `tofu apply` to apply changes

Note: Some changes may require container recreation.

## Troubleshooting

### Issue: "SSL certificate problem"

If you encounter SSL certificate errors:

```bash
# In provider.tf, ensure you have:
pm_tls_insecure = true
```

### Issue: "401 Unauthorized"

Check your API token:
- Verify token ID format: `root@pam!opentofu`
- Ensure token secret is correct
- Verify token has necessary permissions

### Issue: "Template not found"

```bash
# On Proxmox, verify template exists
pveam list local

# Download if missing
pveam download local debian-12-standard_12.2-1_amd64.tar.zst
```

### Issue: "Storage 'local-lvm' does not exist"

```bash
# Check available storage
pvesm status

# Update main.tf with correct storage name
```

### Issue: "Network bridge not found"

```bash
# Check available bridges
ip link show | grep vmbr

# Update main.tf with correct bridge name
```

## Advanced Configuration Options

### Using SSH Keys Instead of Passwords

Add to `main.tf`:

```hcl
resource "proxmox_lxc" "debian_container" {
  # ... other settings ...

  ssh_public_keys = <<-EOT
    ssh-rsa AAAAB3NzaC1yc2E... user@hostname
  EOT
}
```

### Static IP Configuration

Replace DHCP with static IP in `main.tf`:

```hcl
network {
  name   = "eth0"
  bridge = "vmbr0"
  ip     = "192.168.56.20/24"
  gw     = "192.168.56.1"
}
```

### Multiple Network Interfaces

Add additional network blocks:

```hcl
network {
  name   = "eth0"
  bridge = "vmbr0"
  ip     = "192.168.56.20/24"
}

network {
  name   = "eth1"
  bridge = "vmbr1"
  ip     = "10.0.0.20/24"
}
```

### Mount Points

Add additional storage to the container:

```hcl
mountpoint {
  slot    = "0"
  storage = "local-lvm"
  size    = "10G"
  mp      = "/mnt/data"
}
```

## Security Best Practices

1. **Use API tokens instead of passwords** for Proxmox authentication
2. **Enable privilege separation** in production (set `--privsep=1`)
3. **Use SSH keys** instead of password authentication
4. **Never commit `terraform.tfvars`** to version control
5. **Use environment variables** for sensitive data:
   ```bash
   export TF_VAR_proxmox_api_token_secret="your-secret"
   tofu apply
   ```
6. **Enable firewall rules** in Proxmox for the container
7. **Use unprivileged containers** when possible (already configured)

## Alternative: Using the BPG Provider

For the newer Proxmox provider, modify `versions.tf`:

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.38"
    }
  }
}
```

Note: This provider has a different resource syntax. Consult the [provider documentation](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) for details.

## Useful Commands Reference

```bash
# OpenTofu commands
tofu init          # Initialize project
tofu validate      # Validate configuration
tofu fmt           # Format configuration files
tofu plan          # Preview changes
tofu apply         # Apply changes
tofu destroy       # Destroy resources
tofu output        # Show outputs
tofu state list    # List resources in state
tofu state show    # Show resource details
tofu refresh       # Update state from real infrastructure

# Proxmox LXC commands
pct list           # List containers
pct start <id>     # Start container
pct stop <id>      # Stop container
pct status <id>    # Show container status
pct config <id>    # Show container config
pct enter <id>     # Enter container shell
pct destroy <id>   # Destroy container
```

## Notes

- OpenTofu is a fork of Terraform and uses the same HCL syntax
- The Telmate provider works with both Terraform and OpenTofu
- Container IDs (VMIDs) are automatically assigned by Proxmox
- Changes to some container properties require recreation
- Always test in a non-production environment first
- Keep your OpenTofu state file secure (contains resource information)
