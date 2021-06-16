#!/usr/bin/env bash

# add path to tcpdump (if empty defaults to $PATH)
TCPDUMP_PATH=

# set the network interfaces automatically found and are in status up
AUTO_INTERFACES=()

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

# removes network interfaces that are in the ignore array from the interfaces array
function ignoreInterfaces() {
    if (( ${#IGNORE_INTERFACES[@]} >= 1 )); then
        for iface in "${IGNORE_INTERFACES[@]}"; do
            INTERFACES=( "${INTERFACES[@]/*$iface/}" )
        done
    fi
}

# finds interfaces marked as down and removes them from the interfaces array
function removeDownInterfaces () {
    for iface in "${INTERFACES[@]}"; do
        if [[ -n "${iface}" ]]; then
            if grep -q up "$iface/operstate"; then
                AUTO_INTERFACES+=("$iface")
            fi
        fi
    done
}

function checkTraffic () {
    for iface in "${AUTO_INTERFACES[@]}"; do
        tcpdump -n -m $iface tcp -c 50 2> /dev/null | awk '{{src[NR]=$3} {dst[NR]=substr($5, 1, length($5)-1)}};END \
                                                           {for (i=1;i<=NR;i++) \
                                                               {for (j=1;j<=NR;j++) \
                                                                   {if (src[i] == dst[j] && src[i] != "") \
                                                                       { if (dst[i] == src[j]) \
                                                                           { print "Bi-Directional communication found on '$iface'\n" \
                                                                    src[i] " -> " dst[i] "\n" src[j] " -> " dst[j]; exit}}}} \
                                                                    print "Bi-Directional communication not found on '$iface'"}'
    done
}

checkSudo
getInterfaces
ignoreInterfaces
removeDownInterfaces
checkTraffic
