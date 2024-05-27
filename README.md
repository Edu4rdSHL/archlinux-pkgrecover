# archlinux-pkgrecover
Recover your ArchLinux installation after a mid-upgrade crash

# Purpose
This script is intended to be used when your ArchLinux system crashes during a system upgrade, leaving your system in an inconsistent state. The script will attempt to recover your system by reinstalling all packages that were installed before the crash. Here, before the crash means the date that **you** specify.

**Note:** You don't need a very specific date, just a date that is close to the date of the crash. The script will then look for all packages that were installed after that date and will reinstall them.

# How it works

The script have two modes of operation:

1. **Using the pacman log file**: The script will look for the pacman log file and will extract the list of packages that were installed after the specified date using paclog from `pacutils`. This option is activated using the `--paclog` option.
2. **Using the package database**: If the pacman log file is not available, is corrupted, or you don't have `pacutils` installed, the script can look for the package database and will extract the list of packages that were installed after the specified date. This option is activated using the `--pacman-db` option.

# Usage

**Important:** Quote the date argument if it contains spaces or special characters.

1. Get a shell on your system. You can use a live CD + a chroot environment (recommended) or simply a shell on the crashed system.
2. Download the script.
3. Run the script with the date of the last successful upgrade as an argument. For example, if the last successful upgrade was on the 27th of May 2024, you would run the script as follows:
```bash
# Check first what packages will be reinstalled using the --dry-run option
archlinux-pkgrecover.sh --pacman-db/--paclog "2024-05-27" --dry-run

# If you are happy with the list of packages that will be reinstalled
archlinux-pkgrecover.sh --pacman-db/--paclog "2024-05-27"
```