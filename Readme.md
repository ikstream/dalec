# Da-lec

Da-lec is a **Da**ta-Co**lec**tion tool for linux based systems and part of my
master thesis.<br>

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
- collects number of dhcp leases

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

