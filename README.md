# archlinux-pkgrecover
Recover your ArchLinux installation after a mid-upgrade crash, power loss, etc.

# Purpose
This script is intended to be used when your ArchLinux system crashed, a power outage happens, etc, during a system upgrade, leaving your system in an inconsistent state. The script will attempt to recover your system by reinstalling all packages that were installed before the crash. Here, before the crash means the date that **you** specify.

**Note:** You don't need a very specific date, just a date that is close to the date of the crash. The script will then look for all packages that were installed after that date and will reinstall them.

# How it works

The script have two modes of operation:

1. **Using the pacman log file**: The script will look for the pacman log file and will extract the list of packages that were installed after the specified date using paclog from `pacutils`, and then compare that to `pacman -Qq` to make sure it's installing only packages that were present at the moment of the crash. In case that your pacman database is not working, just pass the `--no-db` flag. This option is activated using the `--paclog` option.
2. **Using the package database**: If the pacman log file is not available, is corrupted, or you don't have `pacutils` installed, the script can look for the package database and will extract the list of packages that were installed after the specified date. This option is activated using the `--pacman-db` option.

## Considerations

- The script tries to be as safe and accurate as possible, but it's always a good idea to check the list of packages that will be reinstalled using the `--dry-run` option.
- When using the `--paclog` option among with the `--no-db` flag, the script will reinstall **all** packages that were installed/upgraded after the specified date. This means that packages that were removed after the specified date will be reinstalled. It's because the script doesn't know if any package was removed after the specified date because it doesn't have access to the pacman database for checking the current state of the system.

# Dependencies

- `pacutils` (optional): Required if you want to use the `--paclog` option. You can install it from the official repositories.
- `pacman` (required): Required for the script to work. It's installed by default on ArchLinux systems. In case that your pacman got corrupted, you can use the [pacman-static](https://aur.archlinux.org/packages/pacman-static/) package from the AUR by installing it manually or simply setting the `USE_PACMAN_STATIC=true` environment variable when launching the script.

# Usage

**Important:** Quote the date argument if it contains spaces or special characters.

**Tip:** If your local pacman installation is broken, use the `USE_PACMAN_STATIC=true` environment variable when launching the script.

1. Get a shell on your system. You can use a live CD + a chroot environment (recommended) or simply a shell on the crashed system.
2. Download the script.
3. Run the script with the date of the last successful upgrade as an argument. For example, if the last successful upgrade was on the 27th of May 2024, you would run the script as follows:
```bash
# Check first what packages will be reinstalled using the --dry-run option
./pkgrecover.sh --pacman-db/--paclog "2024-05-27" [--no-db] --dry-run

# If you are happy with the list of packages that will be reinstalled
./pkgrecover.sh --pacman-db/--paclog "2024-05-27" [--no-db]
```

# Examples

1. Using the pacman log file among with the pacman database:
```bash
# Check first what packages will be reinstalled using the --dry-run option
./pkgrecover.sh --paclog "2024-05-27" --dry-run

# If you are happy with the list of packages that will be reinstalled
./pkgrecover.sh --paclog "2024-05-27"
```

2. Using the pacman log file without the pacman database:
```bash
# Check first what packages will be reinstalled using the --dry-run option
./pkgrecover.sh --paclog "2024-05-27" --no-db --dry-run

# If you are happy with the list of packages that will be reinstalled
./pkgrecover.sh --paclog "2024-05-27" --no-db
```

3. Using the package database:
```bash
# Check first what packages will be reinstalled using the --dry-run option
./pkgrecover.sh --pacman-db "2024-05-27" --dry-run

# If you are happy with the list of packages that will be reinstalled
./pkgrecover.sh --pacman-db "2024-05-27"
```

# License

This script is licensed under the MIT license. See the [LICENSE](LICENSE) file for more information.
