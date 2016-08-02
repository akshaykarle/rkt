#!/usr/bin/env bash

# Usage:
# ./setup-data-dir.sh [path to rkt data dir]
# The script can take one parameter being a path to the rkt data
# directory. If none is passed, /var/lib/rkt is assumed.

# Please keep it in sync with dist/init/systemd/tmpfiles.d/rkt.conf!

set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

datadir="${1}"

if [[ -z "${datadir}" ]]; then
    datadir="/var/lib/rkt"
fi

# Creates the directory with the given mode and given group
# 1 - directory to create if it does not exist
# 2 - mode to set the directory to
# 3 - group to set the directory ownership to
make_directory() {
    local dir="${1}"
    local mode="${2}"
    local group="${3}"

    if [[ -e "${dir}" ]]; then
        chmod "${mode}" "${dir}"
    else
        mkdir --mode="${mode}" "${dir}"
    fi
    chgrp "${group}" "${dir}"
}

# Creates the file with the given mode and rkt group
# 1 - file to create if it does not exist
# 2 - mode to set the file to
# 3 - group to set the directory ownership to
create_file() {
    local file="${1}"
    local mode="${2}"
    local group="${3}"

    if [[ ! -e "${file}" ]]; then
        touch "${file}"
    fi
    chmod "${mode}" "${file}"
    chgrp "${group}" "${file}"
}

getent group rkt-admin || groupadd --force --system rkt-admin
getent group rkt || groupadd --force --system rkt

if [[ -e /usr/lib/tmpfiles.d/rkt.conf ]]; then
    if which systemd-tmpfiles; then
        systemd-tmpfiles --create /usr/lib/tmpfiles.d/rkt.conf
        exit
    else
        awk '{
            if ($1 == "d") {
                system("bash -c '\''make_directory "$2" "$3" "$5"'\''");
            } else if ($1 == "f") {
                system("bash -c '\''create_file "$2" "$3" "$5"'\''");
            }
        }' dist/init/systemd/tmpfiles.d/rkt.conf
    fi
fi

