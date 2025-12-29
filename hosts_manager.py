#!/usr/bin/env python3
"""
Hosts Manager - A simple application to manage /etc/hosts entries
"""

import random
import os
from datetime import datetime


class HostsManager:
    def __init__(self, hosts_file='/etc/hosts'):
        self.hosts_file = hosts_file

    def generate_random_ip(self):
        """Generate a random private IP address (192.168.x.x)"""
        return f"192.168.{random.randint(1, 255)}.{random.randint(1, 254)}"

    def add_host_entry(self, hostname, ip=None):
        """Add a single host entry to /etc/hosts"""
        if ip is None:
            ip = self.generate_random_ip()

        entry = f"{ip}\t{hostname}\n"

        try:
            with open(self.hosts_file, 'a') as f:
                f.write(entry)
            print(f"✓ Added: {ip}\t{hostname}")
            return True
        except PermissionError:
            print(f"✗ Permission denied. Run with sudo or as root.")
            return False
        except Exception as e:
            print(f"✗ Error adding entry: {e}")
            return False

    def add_multiple_hosts(self, hostnames):
        """Add multiple host entries at once"""
        print(f"\n{'='*50}")
        print(f"Adding {len(hostnames)} hosts to {self.hosts_file}")
        print(f"{'='*50}\n")

        added = 0
        for hostname in hostnames:
            if self.add_host_entry(hostname):
                added += 1

        print(f"\n{'='*50}")
        print(f"Summary: {added}/{len(hostnames)} hosts added successfully")
        print(f"{'='*50}\n")

        return added

    def remove_host_entry(self, hostname):
        """Remove a host entry from /etc/hosts"""
        try:
            with open(self.hosts_file, 'r') as f:
                lines = f.readlines()

            new_lines = [line for line in lines if hostname not in line]

            with open(self.hosts_file, 'w') as f:
                f.writelines(new_lines)

            print(f"✓ Removed entries for: {hostname}")
            return True
        except Exception as e:
            print(f"✗ Error removing entry: {e}")
            return False

    def list_custom_entries(self):
        """List all custom entries (192.168.x.x range)"""
        try:
            with open(self.hosts_file, 'r') as f:
                lines = f.readlines()

            print(f"\n{'='*50}")
            print(f"Custom entries in {self.hosts_file}")
            print(f"{'='*50}\n")

            for line in lines:
                if line.strip() and not line.startswith('#'):
                    if '192.168.' in line:
                        print(line.strip())

            print()
        except Exception as e:
            print(f"✗ Error reading hosts file: {e}")

    def backup_hosts(self):
        """Create a backup of the hosts file"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_file = f"{self.hosts_file}.backup_{timestamp}"

        try:
            with open(self.hosts_file, 'r') as src:
                content = src.read()
            with open(backup_file, 'w') as dst:
                dst.write(content)
            print(f"✓ Backup created: {backup_file}")
            return backup_file
        except Exception as e:
            print(f"✗ Error creating backup: {e}")
            return None


def main():
    """Main function to demonstrate the hosts manager"""
    manager = HostsManager('/etc/hosts')

    # List of names to add
    names = ['Alex', 'Ben', 'Bob', 'Alice']

    print("\n" + "="*50)
    print("DNS Hosts Manager")
    print("="*50)

    # Add the hosts
    manager.add_multiple_hosts(names)

    # Display the entries
    manager.list_custom_entries()

    print("\nHosts file updated successfully!")
    print("You can now resolve these names using dnsmasq.\n")


if __name__ == '__main__':
    main()
