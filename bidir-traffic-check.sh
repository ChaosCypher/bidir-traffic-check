#!/usr/bin/env bash

# add path to tcpdump (if empty defaults to $PATH)
TCPDUMP_PATH=

# set the network interfaces to check (if empty defaults to all interfaces)
INTERFACES=()

# set the network interface ignore array (useful when defaulting to all interfaces)
IGNORE_INTERFACES=("lo" "docker0" "virbr0")

# set return codes
OK=0
ERROR=1
WARNING=2
UNKNOWN=3

# makes sure were runnig with escalated privlidges
function checkSudo () {
    if (( $(id -u) != 0 )); then
        echo "ERROR - This must be run with root privlidges!"
        return $ERROR
    fi
}

# populates an array of network interfaces
function getInterfaces () {
    if (( ${#INTERFACES[@]} < 1 )); then
        for iface in /sys/class/net/*; do
            INTERFACES+=("$iface")
        done
    fi
}

# removes network interfaces that are in the ignore array
function ignoreInterfaces() {
    if (( ${#IGNORE_INTERFACES[@]} >= 1 )); then
        for iface in "${IGNORE_INTERFACES[@]}"; do
            INTERFACES=( "${INTERFACES[@]/*$iface/}" )
        done
    fi
}

# function removeDownInterfaces () {}

# function checkTraffic () {
# }

# function main () {
#     checkSudo()
# }

# main()

checkSudo
getInterfaces
ignoreInterfaces
