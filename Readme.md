# Dalec

Dalec is a **Da**ta Co**lec**tion tool for Linux based systems.<br>

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

### basic

It collects the following information without additional switches:

- Available and total RAM (in 2^n categories)
- Uptime
- CPU data:
  - Model
  - Model name
  - System type
  - Machine Info
  - Vendor ID
  - Core and Thread count
- Number of network interfaces

### -n | --network
- collects number of DHCP leases

### -a | --all:
- collects all basic information and network information

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

