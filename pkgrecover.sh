#!/usr/bin/bash

VERSION="1.0.0"
USE_PACMAN_STATIC=${USE_PACMAN_STATIC:-"false"}
RED='\033[0;31m'
YELLOW='\033[1;33m'

directory_check() {
    #checks to make sure that all the important directories are mounted properly
    if [[ ! -d /proc ]]; then
        echo -e "${RED} ERROR: /proc is not mounted. upgrading without /proc mounted can cause damage."
        exit 1
    fi

    if [[ ! -d /sys ]]; then
        echo -e "${RED} ERROR: /sys is not mounted. upgrading without /sys mounted can cause damage."
        exit 1
    fi

    if [[ ! -d /boot ]]; then
        echo -e "${RED} ERROR: /boot is not mounted. upgrading without /boot mounted can cause damage."
        exit 1
    fi
}

install_pacman_static() {
    if [[ ! -f /tmp/pacman-static.installed ]]; then
        echo "Downloading and installing pacman-static. In case that curl fails, you can download the binary from:"
        echo "https://pkgbuild.com/~morganamilo/pacman-static/x86_64/bin/pacman-static"
        echo "and then move it to /usr/bin/pacman"

        mv /usr/bin/pacman /usr/bin/pacman.bak
        curl -Lo /usr/bin/pacman https://pkgbuild.com/~morganamilo/pacman-static/x86_64/bin/pacman-static
        chmod +x /usr/bin/pacman
        touch /tmp/pacman-static.installed
    fi
}

check_dependencies() {
    if [[ $USE_PACMAN_STATIC == "true" ]]; then
        install_pacman_static
    fi

    if ! command -v pacman &>/dev/null; then
        echo "pacman is not installed."
        exit 1
    fi

    if [[ "$1" == "paclog" ]] && ! command -v paclog &>/dev/null; then
        echo "paclog is not installed. Use the --pacman-db option instead or install the pacutils package."
        exit 1
    fi

    directory_check
}

cleanup() {
    echo "Cleanup..."

    if [[ -f /usr/bin/pacman.bak ]]; then
        mv /usr/bin/pacman.bak /usr/bin/pacman
    fi

    if [[ -f /tmp/pacman-static.installed ]]; then
        rm /tmp/pacman-static.installed
    fi
}

check_date_format() {
    if ! date -d "$1" &>/dev/null; then
        echo "Please provide a date in the format 'YYYY-MM-DD HH:MM:SS'. See --help for more information."
        exit 1
    fi
}

using_pacman_db() {
    if [[ ! -d /var/lib/pacman/local ]]; then
        echo "The directory /var/lib/pacman/local does not exist."
        exit 1
    fi

    # $1 is the date in a valid format. i.e "2024-05-26 00:00:00"
    check_date_format "$1"

    # Get the list of modified db directories into an array
    mapfile -t modified_db_dirs < <(find /var/lib/pacman/local -maxdepth 1 -type d -newermt "$1" | awk -F '/' '{print $NF}')

    # Get the list of installed packages into an array
    mapfile -t installed_packages < <(pacman -Qq)

    matching_packages=()

    # Find the common elements between the two arrays
    for db_dir in "${modified_db_dirs[@]}"; do
        for pkg in "${installed_packages[@]}"; do
            if [[ "$db_dir" == $pkg-* ]]; then
                matching_packages+=("$pkg")
            fi
        done
    done

    mapfile -t matching_packages < <(echo "${matching_packages[@]}" | tr ' ' '\n' | sort -u)

    # $2 is the dry-run flag, if set, just print the packages, else reinstall them piped to pacman
    if [[ $2 == "--dry-run" ]]; then
        echo "The following packages will be reinstalled:"
        for pkg in "${matching_packages[@]}"; do
            echo "$pkg"
        done
    else
        echo "Reinstalling the following packages:"
        pacman -S "${matching_packages[@]}" --overwrite='*'
    fi

    cleanup
}

using_paclog() {
    if [[ ! -f /var/log/pacman.log ]]; then
        echo "The file /var/log/pacman.log does not exist."
        exit 1
    fi

    # $1 is the date in a valid format. i.e "2024-05-26 00:00:00"
    check_date_format "$1"

    # Get the list of packages upgraded after the given date
    mapfile -t paclog_matching_packages < <(paclog --after "$1" | grep -oE "(upgraded|installed) (\S+)" | cut -d ' ' -f 2 | sort -u)

    matching_packages=()

    if [[ $2 == "--no-db" ]] || [[ $3 == "--no-db" ]]; then
        matching_packages=("${paclog_matching_packages[@]}")
    else
        mapfile -t installed_packages < <(pacman -Qq)
        # Find the common elements between the two arrays
        for pkg in "${paclog_matching_packages[@]}"; do
            for installed_pkg in "${installed_packages[@]}"; do
                if [[ "$pkg" == "$installed_pkg" ]]; then
                    matching_packages+=("$pkg")
                fi
            done
        done
    fi

    # $2 is the dry-run flag, if set, just print the packages, else reinstall them piped to pacman
    if [[ $3 == "--dry-run" ]] || [[ $2 == "--dry-run" ]]; then
        echo "The following packages will be reinstalled:"
        for pkg in "${matching_packages[@]}"; do
            echo "$pkg"
        done
    else
        echo "Reinstalling the following packages:"
        pacman -S "${matching_packages[@]}" --overwrite='*'
    fi

    cleanup
}

usage() {
    echo "$0 v$VERSION"
    echo "Usage: [ENVIRONMENT] $0 [OPTIONS]"
    echo "ENVIRONMENT:"
    echo "USE_PACMAN_STATIC=true $0 [OPTIONS]  Use pacman-static instead of the default pacman. Useful in cases that pacman is broken. Default is false."
    echo "Options:"
    echo "  --pacman-db \"<date>\" [--dry-run]  Reinstall packages upgraded after the given date using pacman database. Please quote the date in the format 'YYYY-MM-DD HH:MM:SS'"
    echo "  --paclog \"<date>\" [--no-db] [--dry-run]     Reinstall packages upgraded after the given date using pacman log. Please quote the date in the format 'YYYY-MM-DD HH:MM:SS'"
    exit 1
}

# Check that we have at least 2 arguments
if [[ $# -le 1 ]]; then
    usage
fi

# Check that we are running as root
if [[ $EUID -ne 0 ]]; then
    if [[ $3 == "--dry-run" ]] || [[ $2 == "--dry-run" ]]; then
        echo -e "${YELLOW}WARNING: This script must be run as root in order to install pacman packages. Proceeding because it's a dry-run operation."
    else
        echo -e "${RED}ERROR: This script must be run as root in order to install pacman packages."
        exit 1
    fi
fi

# Parse the command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --pacman-db)
        check_dependencies
        using_pacman_db "$2" "$3"
        exit 0
        ;;
    --paclog)
        check_dependencies "paclog"
        using_paclog "$2" "$3" "$4"
        exit 0
        ;;
    *)
        usage
        ;;
    esac
done
