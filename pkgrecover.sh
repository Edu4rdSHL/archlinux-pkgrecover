#!/usr/bin/bash

check_dependencies() {
    if ! command -v pacman &>/dev/null; then
        echo "pacman is not installed."
        exit 1
    fi

    if ! command -v paclog &>/dev/null; then
        echo "paclog is not installed."
        exit 1
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
        sudo pacman -S "${matching_packages[@]}" --noconfirm
    fi
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
    mapfile -t installed_packages < <(pacman -Qq)

    matching_packages=()

    # Find the common elements between the two arrays
    for pkg in "${paclog_matching_packages[@]}"; do
        for installed_pkg in "${installed_packages[@]}"; do
            if [[ "$pkg" == "$installed_pkg" ]]; then
                matching_packages+=("$pkg")
            fi
        done
    done

    # $2 is the dry-run flag, if set, just print the packages, else reinstall them piped to pacman
    if [[ $2 == "--dry-run" ]]; then
        echo "The following packages will be reinstalled:"
        for pkg in "${matching_packages[@]}"; do
            echo "$pkg"
        done
    else
        echo "Reinstalling the following packages:"
        sudo pacman -S "${matching_packages[@]}" --noconfirm
    fi
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --pacman-db \"<date>\" [--dry-run]  Reinstall packages upgraded after the given date using pacman database. Please quote the date in the format 'YYYY-MM-DD HH:MM:SS'"
    echo "  --paclog \"<date>\" [--dry-run]     Reinstall packages upgraded after the given date using pacman log. Please quote the date in the format 'YYYY-MM-DD HH:MM:SS'"
    exit 1
}

if [[ $# -eq 0 ]]; then
    usage
fi

# Parse the command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --pacman-db)
        check_dependencies
        using_pacman_db "$2" "$3"
        shift 3
        ;;
    --paclog)
        check_dependencies
        using_paclog "$2" "$3"
        shift 3
        ;;
    *)
        usage
        ;;
    esac
done
