#!/usr/bin/env bash

# Set up test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_TO_TEST="$SCRIPT_DIR/bidir-traffic-check.sh"
FAILED_TESTS=0

# Test checkSudo function
test_checkSudo() {
	local description="checkSudo function"
	echo "Running test: $description"

	# shellcheck source=./bidir-traffic-check.sh
	source "$SCRIPT_TO_TEST"

	# Test as non-root user
	if [ "$EUID" -ne 0 ]; then
		checkSudo
		local result=$?
		if [ $result -eq "$ERROR" ]; then
			echo "Non-root test passed"
		else
			echo "Non-root test failed. Expected: $ERROR, Got: $result"
			FAILED_TESTS=$((FAILED_TESTS + 1))
		fi
	else
		echo "Skipping non-root test (running as root)"
	fi

	# Test as root user
	if [ "$EUID" -eq 0 ]; then
		checkSudo
		local result=$?
		if [ $result -eq "$OK" ]; then
			echo "Root test passed"
		else
			echo "Root test failed. Expected: $OK, Got: $result"
			FAILED_TESTS=$((FAILED_TESTS + 1))
		fi
	else
		echo "Skipping root test (not running as root)"
	fi

	echo "---"
}

# Test getInterfaces function
test_getInterfaces() {
	local description="getInterfaces function"
	echo "Running test: $description"

	# shellcheck source=./bidir-traffic-check.sh
	source "$SCRIPT_TO_TEST"

	# Backup the original INTERFACES array
	local ORIGINAL_INTERFACES=("${INTERFACES[@]}")

	# Test 1: Empty INTERFACES array
	INTERFACES=()
	getInterfaces
	if [ ${#INTERFACES[@]} -gt 0 ]; then
		echo "Empty INTERFACES test passed"
	else
		echo "Empty INTERFACES test failed. Expected non-empty array, got empty"
		FAILED_TESTS=$((FAILED_TESTS + 1))
	fi

	# Test 2: Non-empty INTERFACES array
	INTERFACES=("eth0" "wlan0")
	local INITIAL_COUNT=${#INTERFACES[@]}
	getInterfaces
	if [ ${#INTERFACES[@]} -eq "$INITIAL_COUNT" ]; then
		echo "Non-empty INTERFACES test passed"
	else
		echo "Non-empty INTERFACES test failed. Expected ${INITIAL_COUNT} interfaces, got ${#INTERFACES[@]}"
		FAILED_TESTS=$((FAILED_TESTS + 1))
	fi

	# Restore the original INTERFACES array
	INTERFACES=("${ORIGINAL_INTERFACES[@]}")

	echo "---"
}

# Test ignoreInterfaces function
test_ignoreInterfaces() {
	local description="ignoreInterfaces function"
	echo "Running test: $description"

	# shellcheck source=./bidir-traffic-check.sh
	source "$SCRIPT_TO_TEST"

	# Backup the original INTERFACES and IGNORE_INTERFACES arrays
	local ORIGINAL_INTERFACES=("${INTERFACES[@]}")
	local ORIGINAL_IGNORE_INTERFACES=("${IGNORE_INTERFACES[@]}")

	# Test case 1: Remove single interface
	INTERFACES=("eth0" "wlan0" "lo" "docker0")
	IGNORE_INTERFACES=("lo")
	ignoreInterfaces
	if [[ " ${INTERFACES[*]} " != *" lo "* ]] && [[ ${#INTERFACES[@]} -eq 3 ]]; then
		echo "Single interface removal test passed"
	else
		echo "Single interface removal test failed"
		FAILED_TESTS=$((FAILED_TESTS + 1))
	fi

	# Test case 2: Remove multiple interfaces
	INTERFACES=("eth0" "wlan0" "lo" "docker0" "virbr0")
	IGNORE_INTERFACES=("lo" "docker0" "virbr0")
	ignoreInterfaces
	if [[ " ${INTERFACES[*]} " != *" lo "* ]] &&
		[[ " ${INTERFACES[*]} " != *" docker0 "* ]] &&
		[[ " ${INTERFACES[*]} " != *" virbr0 "* ]] &&
		[[ ${#INTERFACES[@]} -eq 2 ]]; then
		echo "Multiple interface removal test passed"
	else
		echo "Multiple interface removal test failed"
		FAILED_TESTS=$((FAILED_TESTS + 1))
	fi

	# Test case 3: No interfaces to remove
	INTERFACES=("eth0" "wlan0")
	IGNORE_INTERFACES=("lo" "docker0")
	ignoreInterfaces
	if [[ ${#INTERFACES[@]} -eq 2 ]]; then
		echo "No interfaces to remove test passed"
	else
		echo "No interfaces to remove test failed"
		FAILED_TESTS=$((FAILED_TESTS + 1))
	fi

	# Restore the original INTERFACES and IGNORE_INTERFACES arrays
	INTERFACES=("${ORIGINAL_INTERFACES[@]}")
	IGNORE_INTERFACES=("${ORIGINAL_IGNORE_INTERFACES[@]}")

	echo "---"
}

# Test removeDownInterfaces function
test_removeDownInterfaces() {
	local description="removeDownInterfaces function"
	echo "Running test: $description"

	local TEMP_DIR

	# shellcheck source=./bidir-traffic-check.sh
	source "$SCRIPT_TO_TEST"

	# Backup the original INTERFACES and AUTO_INTERFACES arrays
	local ORIGINAL_INTERFACES=("${INTERFACES[@]}")
	local ORIGINAL_AUTO_INTERFACES=("${AUTO_INTERFACES[@]}")

	# Create temporary directory for mock interfaces
	TEMP_DIR=$(mktemp -d)
	trap 'rm -rf "${TEMP_DIR}"' EXIT

	# Create mock interface files
	echo "up" >"${TEMP_DIR}/eth0"
	echo "down" >"${TEMP_DIR}/eth1"
	echo "up" >"${TEMP_DIR}/wlan0"

	# Test case
	INTERFACES=("eth0" "eth1" "wlan0" "nonexistent")
	AUTO_INTERFACES=()

	# Override the /sys/class/net path for testing
	SYS_CLASS_NET="${TEMP_DIR}"
	export SYS_CLASS_NET

	removeDownInterfaces

	# Check results
	if [[ ${#AUTO_INTERFACES[@]} -eq 2 ]] &&
		[[ " ${AUTO_INTERFACES[*]} " == *" eth0 "* ]] &&
		[[ " ${AUTO_INTERFACES[*]} " == *" wlan0 "* ]] &&
		[[ " ${AUTO_INTERFACES[*]} " != *" eth1 "* ]] &&
		[[ " ${AUTO_INTERFACES[*]} " != *" nonexistent "* ]]; then
		echo "removeDownInterfaces test passed"
	else
		echo "removeDownInterfaces test failed"
		echo "Expected: eth0 and wlan0 in AUTO_INTERFACES"
		echo "Got: ${AUTO_INTERFACES[*]}"
		FAILED_TESTS=$((FAILED_TESTS + 1))
	fi

	# Restore the original INTERFACES and AUTO_INTERFACES arrays
	INTERFACES=("${ORIGINAL_INTERFACES[@]}")
	AUTO_INTERFACES=("${ORIGINAL_AUTO_INTERFACES[@]}")

	echo "---"
}

# Test checkTraffic function
test_checkTraffic() {
	local description="checkTraffic function"
	echo "Running test: $description"

	# shellcheck source=./bidir-traffic-check.sh
	source "$SCRIPT_TO_TEST"

	# Backup and set test variables
	local ORIGINAL_AUTO_INTERFACES=("${AUTO_INTERFACES[@]}")
	local ORIGINAL_PACKETS=$PACKETS
	AUTO_INTERFACES=("eth0" "eth1")
	PACKETS=2

	# Capture function output
	output=$(checkTraffic)

	# Test case 1: Bi-directional traffic on eth0
	if echo "$output" | grep -q "Bi-Directional communication found on 'eth0'"; then
		echo "Bi-directional traffic on eth0 test passed"
	else
		echo "Bi-directional traffic on eth0 test failed"
		FAILED_TESTS=$((FAILED_TESTS + 1))
	fi

	# Test case 2: No bi-directional traffic on eth1
	if echo "$output" | grep -q "Bi-Directional communication not found on 'eth1'"; then
		echo "No bi-directional traffic on eth1 test passed"
	else
		echo "No bi-directional traffic on eth1 test failed"
		FAILED_TESTS=$((FAILED_TESTS + 1))
	fi

	# Restore original variables
	AUTO_INTERFACES=("${ORIGINAL_AUTO_INTERFACES[@]}")
	PACKETS=$ORIGINAL_PACKETS

	# Unset mock function
	unset -f tcpdump

	echo "---"
}

# Mock tcpdump function
tcpdump() {
	case "$2" in
	"eth0")
		echo "10.0.0.1.12345 > 192.168.1.1.80"
		echo "192.168.1.1.80 > 10.0.0.1.12345"
		;;
	"eth1")
		echo "10.0.0.2.54321 > 172.16.0.1.443"
		echo "172.16.0.1.443 > 10.0.0.3.65432"
		;;
	esac
}

test_checkTraffic
test_removeDownInterfaces
test_ignoreInterfaces
test_getInterfaces
test_checkSudo

echo "All tests completed."

if [ $FAILED_TESTS -gt 0 ]; then
	echo "Test suite failed with $FAILED_TESTS error(s)."
	exit 1
else
	echo "All tests passed successfully."
	exit 0
fi
