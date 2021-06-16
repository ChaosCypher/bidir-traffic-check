#!/usr/bin/env bash

set -x

# Path to tcpdump (defaults to $PATH if empty)
TCPDUMP_PATH=
# Automatically found network interfaces in 'up' status
AUTO_INTERFACES=()
# Network interfaces to check (defaults to all interfaces if empty)
INTERFACES=()
# Network interface ignore list (useful when defaulting to all interfaces)
IGNORE_INTERFACES=("lo" "docker0" "virbr0")
# Return codes
OK=0
ERROR=1
WARNING=2
UNKNOWN=3
# Check for root privileges
function checkSudo() {
    if (( $(id -u) != 0 )); then
        echo "ERROR - This script must be run with root privileges!"
        return $ERROR
    fi
}
# Populate the network interfaces array
function getInterfaces() {
    if (( ${#INTERFACES[@]} == 0 )); then
        for iface in /sys/class/net/*; do
            INTERFACES+=("${iface}")
        done
    fi
}
# Remove ignored interfaces from the interfaces array
function ignoreInterfaces() {
    for ignored_iface in "${IGNORE_INTERFACES[@]}"; do
        INTERFACES=("${INTERFACES[@]/$ignored_iface}")
    done
}
# Remove interfaces marked as 'down'
function removeDownInterfaces() {
    for iface in "${INTERFACES[@]}"; do
        if [[ -n "$iface" && -f "/sys/class/net/$iface/operstate" ]]; then
            if grep -q 'up' "/sys/class/net/$iface/operstate"; then
                AUTO_INTERFACES+=("$iface")
            fi
        fi
    done
}
# Check for bi-directional traffic on interfaces
function checkTraffic() {
    for iface in "${AUTO_INTERFACES[@]}"; do
        tcpdump -n -i "$iface" tcp -c 50 2> /dev/null | awk '{
            src[NR]=$3;
            dst[NR]=substr($5, 1, length($5)-1)
        }
        END {
            for (i=1; i<=NR; i++) {
                for (j=1; j<=NR; j++) {
                    if (src[i] == dst[j] && src[i] != "") {
                        if (dst[i] == src[j]) {
                            print "Bi-Directional communication found on '"$iface"'\n" src[i]" -> "dst[i]"\n"src[j]" -> "dst[j];
                            exit
                        }
                    }
                }
            }
            print "Bi-Directional communication not found on '"$iface"'"
        }'
    done
}
# Main script execution
checkSudo
getInterfaces
ignoreInterfaces
removeDownInterfaces
checkTraffic
