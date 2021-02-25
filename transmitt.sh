#!bin/sh

generate_data()
{
  tmp_file='/tmp/gen.data'
  data=$(find /dev/ -name 'mtd?ro')

  for i in $(seq 0 8);
  do
    data_file="/dev/mtd${i}ro"
    if [ -c $data_file ]; then
      openssl dgst -sha512 $data_file | awk '{print $2}' >> $tmp_file
    fi
  done
  data=$(openssl dgst -sha512 $tmp_file | awk '{print $2}')
  echo "$data"
  # rm $tmp_file
}

generate_id()
{
  if_list='';
  uid=''
  for interface in $(ls /sys/class/net/);
  do
    if [ "$interface" != 'lo' ]; then
      if_list="${if_list} $(cat /sys/class/net/$interface/address)"
    fi
  done;
  if_list=$(echo $if_list | tr ' ' '\n' | sort -u)

  for mac in $if_list;
  do
    uid=${uid}$(echo $mac | awk -F: '{print $1 $2 $3 $4 $5 $6}')
  done

  hash="$(echo $uid | openssl dgst -sha512)"
  #printf "UID=%s\n" $hash
  echo $hash
  unset uid
}

encrypt_id()
{
  mtd="$(find /dev/ -name 'mtd?ro')"
  id="$(generate_id)"
  salt_length=16

  if [ -z "$mtd" ]; then
    key=$(echo $id | tail -c $(( ${#id} - $salt_length )))
    salt=$(echo $id | head -c $salt_length)
  else
    crypt_data="$(generate_data)"
    key="$(echo $crypt_data | tail -c $(( ${#crypt_data} - $salt_length )))"
    salt="$(echo $crypt_data | head -c $salt_length)"
  fi
  echo "CD: $crypt_data"
  echo "Salt: $salt"

  enc_id=$(echo $id | \
           openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 \
           -k "$key" -S "$salt" -base64 | \
           sed 's;[+/];;g' | head -c 32)
  echo $enc_id
}
encrypt_id
