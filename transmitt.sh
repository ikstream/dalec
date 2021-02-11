#!bin/sh


ecnrypt_mac()
{
 test=''
}

tmp_file='/tmp/gen.data'
data=$(find /dev/ -name 'mtd?ro')

for i in $(seq 0 8);
do
  data_file="/dev/mtd${i}ro"
  echo $data_file
  if [ -c $data_file ]; then
    sha256sum $data_file | awk '{print $1}' >> $tmp_file
  fi
done
uid=$(sha256sum $tmp_file | awk '{print $1}')
echo $uid
# rm $tmp_file

generate_id()
{
  if_list='';
  uid=''
  for interface in $(ls /sys/class/net/);
  do
    if [ "interface" != 'lo' ]; then
      if_list="${if_list} $(cat /sys/class/net/$interface/address)"
    fi
  done;
  if_list=$(echo $interface | tr ' ' '\n' | sort -u)

  for mac in $if_list;
  do
    uid=${uid}$(echo $mac | awk -F: '{print $1 $2 $3 $4 $5 $6}')
  done
  printf "UID=%s\n" "$(echo $uid | sha256sum | cut -c -32)"
  unset uid
}

