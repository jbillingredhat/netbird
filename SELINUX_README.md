# NetBird SELinux Policy

This directory contains the SELinux policy module for the NetBird mesh network client.

## Purpose

Without this policy, netbird runs in an **unconfined domain** on SELinux-enabled systems, giving it broad access to system resources. While netbird functions correctly in this state, it has fewer security restrictions than necessary.

This SELinux policy module **confines the netbird daemon** to only the permissions it actually needs, improving system security through mandatory access control (MAC). The policy follows the principle of least privilege by granting netbird precisely scoped access to:

- WireGuard network interfaces and VPN tunnel management (kernel module preferred, userspace TUN fallback)
- DNS configuration files
- Its own configuration, state, and log files  
- eBPF program loading for packet filtering
- Network communication and routing

By installing this policy, you enhance the security posture of your system by ensuring netbird cannot access resources beyond what's necessary for VPN operation.

## Files

- **netbird.te** - Type Enforcement file (main policy rules)
- **netbird.fc** - File Contexts file (defines file labels)
- **netbird.if** - Interface file (allows other domains to interact with netbird)

## Building the Policy Module

### Prerequisites

Install the SELinux policy development tools:

```bash
sudo dnf install selinux-policy-devel rpm-build
```

### Build the Module

1. Build the policy module:

```bash
make -f /usr/share/selinux/devel/Makefile netbird.pp
```

This will create `netbird.pp`, the compiled SELinux policy package.

## Installing the Policy

### Via RPM Package (Recommended)

If you're using the netbird RPM package, simply install the SELinux subpackage:

```bash
sudo dnf install netbird-selinux
```

The policy will be automatically installed and file contexts will be restored. The netbird-client package has a conditional requirement for this subpackage when SELinux is installed, so it will be automatically installed on SELinux-enabled systems.

### Manual Installation

1. Install the policy module:

```bash
sudo semodule -i netbird.pp
```

2. Restore file contexts for all netbird files:

```bash
sudo restorecon -Rv /usr/bin/netbird
sudo restorecon -Rv /etc/netbird
sudo restorecon -Rv /var/lib/netbird
sudo restorecon -Rv /var/log/netbird
sudo restorecon -Fv /run/netbird.sock 2>/dev/null || true
```

3. Restart the netbird service:

```bash
sudo systemctl restart netbird.service
```

## Verifying the Policy

Check that the netbird service is running in the correct context:

```bash
ps auxZ | grep netbird
```

You should see `system_u:system_r:netbird_t:s0` in the output.

Check file contexts:

```bash
ls -Z /usr/bin/netbird
ls -Z /etc/netbird/
ls -Z /var/lib/netbird/
ls -Z /var/log/netbird/
ls -Z /run/netbird.sock
```

## Troubleshooting

### Check for AVC denials

If the service isn't working correctly, check for SELinux denials:

```bash
sudo ausearch -m avc -ts recent | grep netbird
```

### Generate additional policy rules

If you see denials, you can generate additional policy rules:

```bash
# Collect denials
sudo ausearch -m avc -ts recent | grep netbird | audit2allow -M netbird_local

# Review the suggested rules
cat netbird_local.te

# If they look reasonable, install them
sudo semodule -i netbird_local.pp
```

### eBPF loading issues

If netbird fails to load eBPF programs (check logs for "failed to load ebpf" or XDP errors):

```bash
# Check for eBPF-related denials
sudo ausearch -m avc -ts recent | grep netbird | grep bpf

# Verify access to BPF filesystem
ls -ldZ /sys/fs/bpf
ls -ldZ /sys/kernel/btf

# Generate additional policy if needed
sudo ausearch -m avc -ts recent | grep netbird | grep -E '(bpf|xdp)' | audit2allow -M netbird_ebpf
```

Common issues:
- Missing `bpf` or `sys_admin` capability
- Denied access to BPF filesystem or BTF information
- Inability to attach XDP programs to network interfaces

### Firewall and routing issues

If netbird fails to configure firewall rules or routing tables (check logs for "failed to create firewall" or routing errors):

```bash
# Check for firewall/routing-related denials
sudo ausearch -m avc -ts recent | grep netbird | grep -E '(iptables|nftables|netlink|sysctl)'

# Verify netbird can execute iptables/nftables
sudo -u root iptables -L -n
sudo -u root nft list tables

# Check routing table file permissions
ls -lZ /etc/iproute2/rt_tables

# Generate additional policy if needed
sudo ausearch -m avc -ts recent | grep netbird | grep -E '(firewall|route)' | audit2allow -M netbird_firewall
```

Common issues:
- Missing iptables/nftables domain transition permissions
- Denied write access to `/etc/iproute2/rt_tables`
- Denied sysctl write access to `/proc/sys/net/`
- Denied netlink operations for route/rule management

### DNS management issues

If netbird cannot modify `/etc/resolv.conf`, check:

```bash
# Verify resolv.conf has the correct context
ls -Z /etc/resolv.conf

# Should show net_conf_t, if not restore it:
sudo restorecon -v /etc/resolv.conf
```

If netbird creates backup files (e.g., `resolv.conf.backup`) and you see denials, you may need to add:

```bash
# Generate and review additional policy
sudo ausearch -m avc -ts recent | grep netbird | grep resolv | audit2allow -M netbird_dns_backup

# Review the generated policy
cat netbird_dns_backup.te

# If acceptable, install it
sudo semodule -i netbird_dns_backup.pp
```

### Temporarily disable SELinux (for testing only)

```bash
# Put SELinux in permissive mode for netbird domain only
sudo semanage permissive -a netbird_t

# Later, remove permissive mode
sudo semanage permissive -d netbird_t
```

### View loaded policy version

```bash
sudo semodule -l | grep netbird
```

## Uninstalling the Policy

1. Remove the policy module:

```bash
sudo semodule -r netbird
```

2. Restore default file contexts (if needed):

```bash
sudo restorecon -Rv /usr/bin/netbird
sudo restorecon -Rv /etc/netbird
sudo restorecon -Rv /var/lib/netbird
sudo restorecon -Rv /var/log/netbird
```

## Policy Details

The policy confines netbird to a restricted domain (`netbird_t`) with the following scoped permissions:

- **Network capabilities**: `net_admin`, `net_raw`, `sys_admin`, `bpf`, `dac_override` for managing WireGuard network interfaces
- **WireGuard interface creation**: Creates native WireGuard kernel interfaces (preferred) or userspace TUN devices (fallback via `/dev/net/tun`)
- **Configuration files**: Read access to `/etc/netbird/` and `/etc/sysconfig/netbird`
- **State files**: Read/write access to `/var/lib/netbird/`
- **Log files**: Write access to `/var/log/netbird/`
- **Unix socket**: Create and manage socket at `/run/netbird.sock`
- **Network operations**: Full network connectivity, routing table modifications
- **DNS management**: Read and write access to `/etc/resolv.conf` and network configuration
- **systemd-resolved**: Optional integration to detect and communicate with systemd-resolved
- **DNS resolution**: Name resolution capabilities
- **Firewall management**: Execute iptables/nftables commands for ACL and routing rules
  - Netlink netfilter socket access for firewall operations
  - Transition to iptables/nftables domains for rule management
- **Routing configuration**: 
  - Read/write access to `/etc/iproute2/rt_tables` for custom routing table registration
  - Netlink route socket operations for route and rule management
  - Sysctl modifications to `/proc/sys/net/` (ip_forward, rp_filter, src_valid_mark)
- **eBPF operations**: Load and run eBPF programs for DNS forwarding and WireGuard proxy
  - `sys_admin`, `bpf` capabilities for loading eBPF programs
  - Access to `/sys/fs/bpf/` and `/sys/kernel/btf/` for BPF filesystem and type information
  - XDP program attachment to network interfaces (loopback)
  - Memory lock limit management for eBPF maps

## Integration with RPM Packaging

The SELinux policy is fully integrated with the netbird RPM package as the `netbird-selinux` subpackage. The netbird.spec file includes:

- **BuildRequires**: `selinux-policy-devel` for building the policy module
- **SELinux subpackage**: `netbird-selinux` with proper dependencies on SELinux base policy
- **Conditional Requires**: The `netbird-client` package uses a rich dependency (`Requires: (%{name}-selinux if selinux-policy-targeted)`) to automatically install the SELinux policy only on systems with SELinux enabled
- **Automatic installation**: Policy is installed and file contexts restored on package install
- **Automatic cleanup**: Policy is removed on package uninstall

The spec file handles:
1. Building the policy module during package build
2. Installing the compressed policy package to `/usr/share/selinux/packages/`
3. Using SELinux macros (`%selinux_modules_install`, `%selinux_modules_uninstall`, etc.) for proper lifecycle management
4. Restoring file contexts on first installation

## License

This SELinux policy follows the same license as the NetBird project (AGPL-3.0).
