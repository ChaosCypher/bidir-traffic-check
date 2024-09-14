# Bi-Directional Traffic Check

This project provides a script to check for bi-directional network traffic on specified interfaces.

## Table of Contents

- [Description](#description)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Description

The Bi-Directional Traffic Check script is designed to monitor network interfaces for bi-directional TCP traffic. It's useful for network administrators and security professionals who need to verify active two-way communications on their networks.

## Features

- Automatic detection of active network interfaces
- Configurable interface ignore list
- Customizable packet capture count

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/bidir-traffic-check.git
   ```
2. Navigate to the project directory:
   ```bash
   cd bidir-traffic-check
   ```
3. Ensure the script has execute permissions:
   ```bash
   chmod +x bidir-traffic-check.sh
   ```

## Usage

Run the script with root privileges:

```bash
sudo ./bidir-traffic-check.sh
```

The script will output whether bi-directional communication was found on each active interface.

## Configuration

You can configure the script by editing the following variables:

- `TCPDUMP_PATH`: Set the path to tcpdump if it's not in your system PATH
- `INTERFACES`: Specify network interfaces to check (empty array checks all interfaces)
- `IGNORE_INTERFACES`: List interfaces to ignore
- `PACKETS`: Number of packets to capture when checking for bi-directional traffic

## Testing

To run the test suite:

1. Ensure the test script has execute permissions:
   ```bash
   chmod +x test-bidir-traffic-check.sh
   ```
2. Run the test script with root privileges:
   ```bash
   sudo ./test-bidir-traffic-check.sh
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
