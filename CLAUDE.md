# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Stream Weaver (流织者) is a Linux traffic forwarding tool that transparently redirects local system traffic to a remote Clash Verge proxy server using redsocks and iptables. It's designed for transparent proxying without application configuration.

## Architecture

### Core Components

- **sw.sh**: Main bash script (~93KB) implementing all functionality
- **Transparent Proxy Flow**: Local apps → iptables NAT → redsocks → remote Clash Verge → target servers
- **Dual-stack Support**: IPv4 and IPv6 via iptables/ip6tables rules
- **Smart Routing**: Automatic exemption for local/private networks

### Key Technologies

- **redsocks**: SOCKS5 proxy redirector for transparent proxying
- **iptables/ip6tables**: NAT rules for traffic redirection
- **systemd**: Service management (optional installation)
- **Bash**: Primary implementation language with comprehensive error handling

## Known Issues Fixed

### GitHub One-Command Installation Issues (Fixed)
- **System Detection Bug**: Fixed case statement mismatch where `detect_system()` set `SYSTEM_TYPE="redhat"` but `install_dependencies()` expected specific values (`fedora`, `centos`)
- **Interactive Menu Call**: Fixed `interactive_menu` function visibility issue in pipe mode by using saved script execution
- **Script Save Logic**: Enhanced `save_script()` function to properly handle content saving in curl-to-bash scenarios

## Development Commands

### Basic Operations
```bash
# Traffic forwarding control
sudo ./sw.sh start          # Start traffic forwarding
sudo ./sw.sh stop           # Stop traffic forwarding
sudo ./sw.sh restart        # Restart traffic forwarding
sudo ./sw.sh status         # Check detailed status

# Configuration
sudo ./sw.sh config <IP> <PORT>    # Set proxy server
sudo ./sw.sh menu           # Interactive menu
sudo ./sw.sh test           # Test connectivity to foreign sites

# Exemption management
sudo ./sw.sh add-exemption ip 192.168.1.100        # Add IP exemption
sudo ./sw.sh add-exemption domain example.com      # Add domain exemption
sudo ./sw.sh add-exemption port 8080               # Add port exemption
sudo ./sw.sh remove-exemption ip 192.168.1.100     # Remove specific exemption
sudo ./sw.sh remove-all-exemptions                 # Clear all exemptions
sudo ./sw.sh list-exemptions                       # List all exemptions
```

### System Service Management
```bash
# Install as system service
sudo ./sw.sh install-service

# After installation, use 'sw' command directly
sudo sw config 192.168.1.100 7890
sudo sw start
sudo sw stop
sudo sw restart
sw status
sw test

# Uninstall service
sudo ./sw.sh uninstall-service
```

### Reset Operations
```bash
sudo ./sw.sh reset                          # Complete reset (deletes all configs)
sudo ./sw.sh reset -k                       # Partial reset (keeps exemptions)
sudo ./sw.sh reset -u                       # Reset and uninstall service
sudo ./sw.sh reset -k -u                    # Partial reset with service uninstall
```

### Command Aliases
- `start` → `s`
- `stop` → `x`
- `restart` → `r`
- `status` → `t`
- `config` → `c`
- `add-exemption` → `a`
- `remove-exemption` → `rm`
- `remove-all-exemptions` → `ra`
- `list-exemptions` → `l`
- `menu` → `m`

## File Structure

- **sw.sh**: Main executable script (93KB)
- **README.md**: Comprehensive documentation in Chinese
- **EXAMPLES.md**: Usage examples and scenarios
- **LICENSE**: MIT license

## Configuration Files

- **/etc/clash_forward/config**: Proxy server configuration
- **/etc/clash_forward/exemptions**: Custom exemption rules
- **/etc/redsocks.conf**: redsocks configuration (auto-generated)
- **/etc/systemd/system/stream-weaver.service**: System service file (optional)

## Important Notes

1. **Root Privileges**: Most commands require `sudo` for iptables/systemd operations
2. **Network Impact**: Script modifies system iptables rules and enables IP forwarding
3. **Automatic Cleanup**: Includes error recovery and automatic rule restoration
4. **IPv6 Support**: Detects and configures ip6tables if available
5. **Service Mode**: Optional systemd integration for persistent operation
6. **Testing**: Built-in connectivity test for 10 major foreign websites

## Development Context

This is a single-file bash implementation focused on system-level networking. Changes should maintain compatibility with Ubuntu/Debian and CentOS/RedHat systems, handle edge cases gracefully, and preserve the existing user interface patterns.

### Code Structure

- **Pipe Mode Detection**: Script detects if running via `curl | bash` using `${BASH_SOURCE[0]}` check
- **Dual Main Functions**: Separate main functions for pipe mode (top) and normal execution (bottom)
- **System Detection**: Uses package manager detection (apt-get/dnf/yum) for system identification
- **Error Handling**: Comprehensive logging with color-coded output and strict mode (`set -euo pipefail`)

### Testing Commands

```bash
# Test one-command installation locally
cat sw.sh | sudo bash                    # Basic installation
cat sw.sh | sudo bash -s install-service # Install with service

# Test script functionality
sudo ./sw.sh test                        # Run connectivity tests
sudo ./sw.sh status                      # Check detailed status
bash -n sw.sh                           # Syntax check
```

### Critical Functions

- **detect_system()**: Determines OS type for package management
- **save_script()**: Handles curl-to-bash installation scenarios  
- **interactive_menu()**: Main user interface (defined at line ~1737)
- **install_dependencies()**: System-specific package installation
- **check_root()**: Permission validation with special handling for pipe mode