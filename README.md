# DNSMasq Demo with Hosts Manager

A demonstration environment with a running DNSMasq server and a Python application for managing /etc/hosts entries.

## Features

- **DNSMasq Server**: Running in Docker with web UI
- **Hosts Manager**: Python application to add custom DNS entries
- **Auto-generated IPs**: Randomly assigns private IPs (192.168.x.x) to hostnames
- **Easy Setup**: Simple Docker Compose deployment

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### 1. Start the DNSMasq Server

```bash
docker-compose up -d dnsmasq
```

This will start the DNSMasq server with:
- DNS server on port 53 (UDP/TCP)
- Web UI on port 8080

### 2. Run the Hosts Manager

Add custom hosts (Alex, Ben, Bob, Alice with random IPs):

```bash
docker-compose run --rm hosts-manager
```

Or run it directly with Python:

```bash
sudo python3 hosts_manager.py
```

### 3. Access the DNSMasq Web UI

Open your browser and navigate to:
```
http://localhost:8080
```

## Using the Hosts Manager

The `hosts_manager.py` script provides a simple interface for managing DNS entries:

### Add Single Host

```python
from hosts_manager import HostsManager

manager = HostsManager('/etc/hosts')
manager.add_host_entry('Alex')  # Auto-generates random IP
# or
manager.add_host_entry('Alex', '192.168.1.100')  # Specific IP
```

### Add Multiple Hosts

```python
manager.add_multiple_hosts(['Alex', 'Ben', 'Bob', 'Alice'])
```

### List Custom Entries

```python
manager.list_custom_entries()
```

### Remove Host Entry

```python
manager.remove_host_entry('Alex')
```

### Backup Hosts File

```python
manager.backup_hosts()
```

## Testing DNS Resolution

Once the hosts are added and DNSMasq is running, you can test DNS resolution:

### Using dig

```bash
dig @localhost Alex
```

### Using nslookup

```bash
nslookup Alex localhost
```

### Using host

```bash
host Alex localhost
```

## Configuration

### DNSMasq Configuration

The DNSMasq configuration is in `dnsmasq.conf`. Key settings:

- **Upstream DNS**: Google DNS (8.8.8.8, 8.8.4.4)
- **Additional Hosts**: Reads from `/etc/hosts`
- **Cache Size**: 1000 entries
- **Query Logging**: Enabled for debugging

### Hosts File

The `hosts` file contains the DNS mappings. It's shared between the DNSMasq container and the hosts-manager.

## Architecture

```
┌─────────────────────┐
│  hosts-manager      │
│  (Python App)       │
└──────────┬──────────┘
           │
           │ writes to
           ▼
    ┌─────────────┐
    │   hosts     │
    │   file      │
    └──────┬──────┘
           │
           │ reads from
           ▼
    ┌──────────────┐
    │   dnsmasq    │
    │   server     │
    └──────────────┘
           │
           │ serves DNS
           ▼
    ┌──────────────┐
    │   Clients    │
    └──────────────┘
```

## Files

- `docker-compose.yml`: Docker Compose configuration
- `Dockerfile`: Container definition for hosts-manager
- `dnsmasq.conf`: DNSMasq server configuration
- `hosts_manager.py`: Python application for managing hosts
- `hosts`: Shared hosts file

## Stopping the Environment

```bash
docker-compose down
```

## Troubleshooting

### Port 53 already in use

If you get a port binding error, another DNS service (like systemd-resolved) might be using port 53:

```bash
# Check what's using port 53
sudo lsof -i :53

# Stop systemd-resolved (Ubuntu/Debian)
sudo systemctl stop systemd-resolved
```

### Permission Denied

The hosts manager needs write access to `/etc/hosts`. Run with `sudo` or as root.

### DNS Not Resolving

1. Check if DNSMasq is running: `docker-compose ps`
2. Check DNSMasq logs: `docker-compose logs dnsmasq`
3. Verify hosts file: `cat hosts`

## License

MIT
