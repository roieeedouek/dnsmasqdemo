# DNSMasq Demo with Hosts Manager

A demonstration environment with a running DNSMasq server and a Python application for managing /etc/hosts entries.

## Features

- **DNSMasq Server**: Running in Docker with web UI
- **Hosts Manager**: Python application to add custom DNS entries
- **Auto-generated IPs**: Randomly assigns private IPs (192.168.x.x) to hostnames
- **Domain Suffix Generator**: Bash script to create FQDN versions of hosts
- **Dual Resolution**: Resolve hosts by short name OR fully qualified domain name
- **Easy Setup**: Simple Docker Compose deployment

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### Option A: Start Everything (Recommended)

Start DNSMasq with automatic domain-suffix generation:

```bash
docker-compose up -d dnsmasq domain-watcher
```

This will start:
- **DNSMasq server** on port 53 (UDP/TCP) with Web UI on port 8080
- **Domain watcher** that automatically generates `hosts.domain` when `hosts` changes

### Option B: Manual Setup

**1. Start the DNSMasq Server**

```bash
docker-compose up -d dnsmasq
```

**2. Run the Hosts Manager**

Add custom hosts (Alex, Ben, Bob, Alice with random IPs):

```bash
docker-compose run --rm hosts-manager
```

Or run it directly with Python:

```bash
sudo python3 hosts_manager.py
```

**3. Generate Domain-Suffixed Hosts**

One-time generation:
```bash
./add_domain_suffix.sh
```

Or run in watch mode for automatic regeneration:
```bash
./add_domain_suffix.sh --watch
```

### Access the DNSMasq Web UI

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

## Using the Domain Suffix Generator

The `add_domain_suffix.sh` script creates fully qualified domain names (FQDNs) from your hosts.

### Basic Usage

**One-time generation:**
```bash
./add_domain_suffix.sh
```

This reads `./hosts` and creates `./hosts.domain` with entries like:
- `Alex` → `Alex.rafael.local`
- `Ben` → `Ben.rafael.local`

**Watch mode (auto-regenerate on changes):**
```bash
./add_domain_suffix.sh --watch
```

This will:
1. Generate the initial `hosts.domain` file
2. Watch for changes to the `hosts` file
3. Automatically regenerate `hosts.domain` when changes are detected
4. Run continuously until stopped with Ctrl+C

The script uses `inotifywait` for efficient file watching, or falls back to polling mode (checking every 5 seconds) if inotify is not available.

### Custom Domain Suffix

```bash
./add_domain_suffix.sh ./hosts .mycompany.local ./hosts.custom
```

Parameters:
1. Input hosts file (default: `./hosts`)
2. Domain suffix (default: `.rafael.local`)
3. Output file (default: `./hosts.domain`)

### Example Output

**Original (hosts):**
```
192.168.156.67	Alex
192.168.209.164	Ben
```

**Generated (hosts.domain):**
```
192.168.156.67 Alex.rafael.local
192.168.209.164 Ben.rafael.local
```

### How It Works

**One-time mode:**
1. Script reads the hosts file line by line
2. Finds entries with private IPs (192.168.x.x)
3. Appends the domain suffix to each hostname
4. Writes to a new file
5. DNSMasq loads both files via `addn-hosts` directives

**Watch mode:**
1. Generates initial domain-suffixed hosts file
2. Monitors the source hosts file for changes (using inotify or polling)
3. Automatically regenerates the output file when changes are detected
4. Logs each regeneration with timestamp

This ensures your domain-suffixed hosts are always in sync with the original hosts file!

### Dual Resolution

With both files configured, DNSMasq will resolve:
- **Short names**: `Alex` → 192.168.156.67
- **FQDNs**: `Alex.rafael.local` → 192.168.156.67

Both resolve to the same IP!

## Testing DNS Resolution

Once the hosts are added and DNSMasq is running, you can test DNS resolution:

### Using dig

```bash
# Short name
dig @localhost Alex

# FQDN
dig @localhost Alex.rafael.local
```

### Using nslookup

```bash
# Short name
nslookup Alex localhost

# FQDN
nslookup Alex.rafael.local localhost
```

### Using host

```bash
# Short name
host Alex localhost

# FQDN
host Alex.rafael.local localhost
```

## Configuration

### DNSMasq Configuration

The DNSMasq configuration is in `dnsmasq.conf`. Key settings:

- **Upstream DNS**: Google DNS (8.8.8.8, 8.8.4.4)
- **Additional Hosts**: Reads from `/etc/hosts` AND `/etc/hosts.domain`
- **Cache Size**: 1000 entries
- **Query Logging**: Enabled for debugging

### Hosts Files

- **hosts**: Contains short name DNS mappings (Alex, Ben, etc.)
- **hosts.domain**: Contains FQDN mappings (Alex.rafael.local, etc.)

Both files are shared with the DNSMasq container and loaded via `addn-hosts` directives.

## Architecture

```
┌─────────────────────┐
│  hosts-manager      │
│  (Python App)       │
└──────────┬──────────┘
           │
           │ writes to
           ▼
    ┌─────────────┐         ┌──────────────────┐
    │   hosts     │────────▶│ add_domain_      │
    │   file      │         │ suffix.sh        │
    └──────┬──────┘         └────────┬─────────┘
           │                         │
           │                         │ generates
           │                         ▼
           │                  ┌─────────────┐
           │                  │ hosts.domain│
           │                  └──────┬──────┘
           │                         │
           │ both read by            │
           └────────┬────────────────┘
                    ▼
             ┌──────────────┐
             │   dnsmasq    │
             │   server     │
             └──────┬───────┘
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
- `add_domain_suffix.sh`: Bash script to generate FQDN hosts
- `hosts`: Shared hosts file (short names)
- `hosts.domain`: Generated hosts file (FQDNs)

## Managing Services

### View Running Services

```bash
docker-compose ps
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f dnsmasq
docker-compose logs -f domain-watcher
```

### Restart a Service

```bash
docker-compose restart dnsmasq
docker-compose restart domain-watcher
```

### Stop a Specific Service

```bash
docker-compose stop domain-watcher
```

## Stopping the Environment

Stop all services:

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
