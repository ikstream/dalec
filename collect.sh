#!/bin/sh

VERSION='0.0.1'

LOG="/tmp/collect.log"

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
get_nic_data()
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

  printf "NIC_COUNT=%s\n" "$(echo $addr | tr ' ' '\n' | sort -u | wc -l)"  >> $log
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
  vendor_id="$(awk -F '[[:space:]]+:[[:space:]]' '/vendor_id/ {print $2;exit}' /proc/cpuinfo)"
  num_cores=$(grep "core id" /proc/cpuinfo  | sort -u | wc -l)
  num_proc=$(grep process /proc/cpuinfo  | uniq  - | wc -l)
  { printf "MODEL=%s\n" "$model"; \
  printf "MODEL_NAME=%s\n" "$model_name"; \
  printf "SYSTEM_TYPEi=%s\n" "$systype"; \
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


# Start basic scanning
#
# This includes only most basic, not personal identifieable information:
#   - Uptime
#   - kernel version
#   - release string
#   - Ram size
#   - number of Cores
#   - disk size
#   - Architecture
#   - wifi chip
#
collect_basics()
{
  log="$1"
  get_uptime $log
  get_cpu_data $log
  get_nic_data $log
  get_memdata $log
}


# collect extensive system information
#
# includes basic and ...
# in addition to this all also collects:
#
collect_all()
{
  log="$1"
  echo "collect all"
  collect_basics $log
}


# print help
#
call_help()
{
  printf "Collect data from linux systems\n"
  printf "\t -a, --all:\t collect all information\n"
  printf "\t -b, --basic:\t collect basic information\n"
  printf "\t -h, --help:\t print this help\n"
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
  options=abc:hl:v
  loptions=all,basic,config:,help,version
  command='basic'


  ! parsed=$(getopt --options=$options --longoptions=$loptions "$args")
  eval set -- "$parsed"

  while true; do
    case "$args" in
      -a | --all)
        command='all'
        shift
        ;;
      -b | --basic)
        command='basic'
        shift
        ;;
      -c | --config)
        read_config "$2"
        shift 2
        ;;
      -h | --help)
        call_help
        exit
        ;;
      -l | --log)
        c_log="$2"
        shift 2
        ;;
      -v | --version)
        printf "Version: $VERSION\n"
        exit
        ;;
      --)
        break
        ;;
      *)
        printf "Error: Wrong or missing input! Usage:\n"
        call_help
        exit $FAILURE
        ;;
    esac
  done

  if [ -z $c_log ]; then
    log=$LOG
  fi

  if [ -f "$log" ]; then
    rm $log
  fi

  case "$command" in
    basic)
      echo "collecting basics"
      collect_basics "$log"
      ;;
    all)
      echo "collecting all"
      collect_all "$log"
      ;;
  esac
}

main "$@"
