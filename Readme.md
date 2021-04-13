# Dalec

Dalec is a **Da**ta Co**lec**tion tool for Linux based systems.<br>

It aims to exterminate known hurdles for developers to collect user data
from devices while keeping the privacy intact.

The collected data is securely transmitted to a collection server using
the hierarchical structure of the Domain Name System (DNS)

The data transmission process will generate a device ID based on your network
interfaces MAC addresses, which are hashed and encrypted with multiple rounds
of PBKDF2 and shortened to 32 Byte. Therefore you can't be identified by
simply brute forcing the ID.
Your data is transmitted as asynchronous encrypted Base 16 encoded chunks.
These chunks will be the labels in a DNS-request.
They are split over multiple requests, recombined on the server side and
decrypted.


# WARNING:This software is intended for data collection!
If you agree, that your basic data is collected, run the command below to
enable the collection.

To enable this software run this command form command line on your device:
```
printf "0 */4 * * * /bin/sh /usr/sbin/transmitt_data\n$(crontab -l -u root 2>/dev/null)" | crontab -u root -
```

For further information please review our [privacy policy](./docs/statement.md)

### basic

It collects the following information without additional switches:

- Software version
- Available and total RAM (in 2^n categories)
- Uptime
- CPU data:
  - Model
  - Model name
  - System type
  - Machine Info
  - Vendor ID
  - Core and Thread count
- Kernel version

### -n | --network
- collects number of DHCP leases
- Number of network interfaces

### -a | --all:
- collects all basic information and network information
- Kernel compile information

## Depencies

For an OpenWrt system you need

```
openssl-util
getopt
drill
```

Optionaly you may want to install

```
coreutils-uname
```

to allow the tramission of the architecture of your system


## Usage

```
dalec
 -a | --all 					  # collect extended information
 -c | --config <path to coinfig>  # set config file path
 -h | --help                      # show options
 -l | --log <path to log file>    # set log file path
 -n | --network 				  # collect network information
 -v | --version                   # Show version info
```

