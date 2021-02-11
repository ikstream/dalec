#!/bin/sh
#
# TODO:
#     Add more error checking. Always check if file exist before reading it
#

VERSION='0.0.1'

LOG="/tmp/da-lec"

FAILURE=1
SUCCESS=0

# Collect version string with build infos
#
#   Arguments:
#         log = Path to log file
#
get_version()
{
  log=$1

  printf "VERSION=%s\n" "$(cat /proc/version)"  >> $log
}

# Collect network interface data
#
#   Arguments:
#         log - Path to log file
#
get_nic_count()
{
  log="$1"

  net_dir="/sys/class/net/"
  interface_list="$(ls "$net_dir")"
  addr=''
  for intf in $interface_list
  do
    if [ -z "$intf" ]; then
      addr=0
      break
    fi

    if [ ! "$intf" == "lo" ]; then
      addr="$addr $(cat /sys/class/net/$intf/address)"
    fi
  done

  printf "INTERFACE_COUNT=%s\n" "$(echo $addr | tr ' ' '\n' | sort -u | wc -l)"  >> $log
}


# Collect Data on CPU
#
#   Arguemnts:
#         log - Path to log file
#
get_cpu_data()
{
  log=$1

  model="$(awk -F '[[:space:]]+:[[:space:]]' '/model/ {print $2;exit}' /proc/cpuinfo)"
  model_name="$(awk -F '[[:space:]]+:[[:space:]]' '/model name/ {print $2;exit}' /proc/cpuinfo)"
  systype="$(awk -F '[[:space:]]+:[[:space:]]' '/system/ {print $2;exit}' /proc/cpuinfo)"
  machine="$(awk -F '[[:space:]]+:[[:space:]]' '/machine/ {print $2;exit}' /proc/cpuinfo)"
  vendor_id="$(awk -F '[[:space:]]+:[[:space:]]' '/vendor_id/ {print $2;exit}' /proc/cpuinfo)"
  num_cores=$(awk '/^core/ {print $0}' /proc/cpuinfo  | sort -u | wc -l)
  num_proc=$(awk '/^process/ {print $0}' /proc/cpuinfo  | sort -u | wc -l)
  { printf "MODEL=%s\n" "$model"; \
  printf "MODEL_NAME=%s\n" "$model_name"; \
  printf "SYSTEM_TYPE=%s\n" "$systype"; \
  printf "MACHINE=%s\n" "$machine"; \
  printf "VENDOR_ID=%s\n" "$vendor_id"; \
  printf "CORE_THREADS=%s:%s\n" "$num_cores" "$num_proc"; } >> $log
}


# Generate ID
#
#  Arguments:
#         log - Path to log file
#
generate_uid()
{
  if_list='';
  uid=''
  for interface in $(ls /sys/class/net/);
  do
      if_list="${if_list} $(cat /sys/class/net/$interface/address)"
  done;
  if_list=$(echo $interface | tr ' ' '\n' | sort -u)

  for mac in $if_list;
  do
    if [ "$mac" == "00:00:00:00:00:00" ]; then
      continue
    fi

    uid=${uid}$(echo $mac | awk -F: '{print $2 $3 $4 $5 $6}')
  done
  printf "UID=%s\n" "$(echo $uid | sha256 | cut -c -32)" >> $log
  unset uid
}


# Collect Memory data
#
#   Arguments:
#         log - Path to log file
#
get_memdata()
{
  log="$1"
  printf "TOTALMEM=%d\n" $(awk '/MemTotal:/{print $2}' /proc/meminfo) >> $log
  printf "AVAILMEM=%d\n" $(awk '/MemAvaila/{print $2}' /proc/meminfo) >> $log
}


# Get the uptime of a system
#
# Arguments:
#         log - Path to log file
#
get_uptime()
{
  log=$1
  time="$(awk '{print $1}' /proc/uptime)"
  printf "UPTIME=%s\n" $time >> $log
}

# Get the number of dhcp leases
#
# Arguments:
#       log - Path to logfile
#
get_lease_count()
{
  log=$1
  printf "LEASE_COUNT=%s\n" "$(awk 'END{print NR}' /tmp/dhcp.leases)" >> $log
}

# Collect information about the network parameter
#
# This includes:
#   - number of dhcp leases
#   - nic vendor
#
# Arguments:
#         log - Path to log file
#
collect_network()
{
  log="$1"
  network_log="$1/network.log"

  if [ ! -f $network_log ]; then
    touch $network_log
  else
    echo '' > $network_log
  fi

  get_lease_count $network_log
}


# Start basic scanning
#
# This includes only most basic, no personal identifieable information:
#   - Uptime
#   - kernel version
#   - release string
#   - Ram size
#   - number of Cores
#   - disk size
#   - Architecture
#
# Arguments:
#         log - Path to log directory
#
collect_basics()
{
  log="$1"
  basic_log="$log/basic.log"

  if [ ! -f $basic_log ]; then
    touch $basic_log
  else
    echo '' > $basic_log
  fi

  get_uptime $basic_log
  get_cpu_data $basic_log
  get_nic_count $basic_log
  get_memdata $basic_log
}


# collect extensive system information
#
# includes basic and ...
# in addition to this all also collects:
#
collect_all()
{
  echo "collect all"
  collect_basics $1
  collect_network $1
}


# print help message
#
call_help()
{
  printf "Collect data from linux systems\n"
  printf "\t -a, --all:\t collect all information\n"
  printf "\t -c, --config:\t provide path to config file\n"
  printf "\t -h, --help:\t print this help\n"
  printf "\t -l, --log:\t set path for logfile\n"
  printf "\t -n, --network:\t collect network information\n"
  printf "\t -v, --version:\t print version of script\n"
}

# include config file
#
read_config()
{
  conf_path="$1"
  echo "reading config"
  source $conf_path
}


# main function
#
# Arguments:
# args - command line arguments
#
main()
{
  args="$@"
  options=ac:hl:nv
  loptions=all,config:,help,log:,network,version
  command='basic'


  parsed=$(getopt -a -o $options --long $loptions -- $args)
  if [ "$?" != "0" ]; then
    call_help
    exit $FAILURE
  fi

  eval set -- "$parsed"

  while true; do
    echo "\$1:$1 \$2:$2"
    case "$1" in
      "-a" | "--all")
        command='all';
        shift
        ;;
      "-c" | "--config")
        read_config "$2";
        shift 2
        ;;
      "-h" | "--help")
        call_help;
        exit
        ;;
      "-l" | "--log")
        c_log="$2";
        shift 2
        ;;
      "-n" | "--network")
        command="$command network"
        shift
        ;;
      "-v" | "--version")
        printf "Version: $VERSION\n"
        exit
        ;;
      " ")
        shift
        ;;
      --)
        shift
        break
        ;;
      *)
        printf "Error: Wrong or missing input ($1)! Usage:\n"
        call_help
        exit $FAILURE
        ;;
    esac
  done

  if [ -z $c_log ]; then
    log=$LOG
  else
    log=$c_log
  fi

  if [ ! -d "$log" ]; then
    mkdir -p $log
  fi

  for c in $(echo $command | tr ' ' '\n'); do
    case "$c" in
      basic)
        echo "collecting basics"
        collect_basics "$log"
        ;;
      network)
        echo "collecting network information"
        ;;
      all)
        echo "collecting all"
        collect_all "$log"
        ;;
    esac
  done
}

main "$@"
