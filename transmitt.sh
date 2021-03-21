#!/bin/sh

DOMAIN="ikstream.net"


# Retrieve the public key from server for encryption
#
# Returns:
#       key: public key of server for encryption of messages
#
get_key()
{
  key=""
  for i in {1..2};
  do
    key=$key$(dig $DOMAIN TXT | awk -F = "/pass$i/ { print $2 }")
  done
  echo $key
}

get_statistics()
{
  logfile=$1
  echo "$(awk -F = '{print $2}' $logfile | tr '\n' ';')"
}

# Generate entropic data from memory technnology devices for salt and pass
#
# Returns:
#       hash of all mtd devices
#
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

# Generate the ID for the device based on it's available MAC addresses
#
# Returns:
#       hash: the sha512 hash of available MAC-addresses
#
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
    uid=${uid}$(echo $mac | awk -F: '{print $1 $2 $3 $4 $5 $6}'| openssl dgst -sha512 )
  done

  hash="$(echo $uid | openssl dgst -sha512 | awk '{print $2}')"
  #printf "UID=%s\n" $hash
  echo $hash
  unset uid
}

# Encrypt the generated id, which is DNS conform and cropped to 32 byte
#
# Returns:
#       enc_id: encrpted, dns conform and cropped id
#
encrypt_id()
{
  mtd="$(find /dev/ -name 'mtd?ro')"
  id="$(generate_id)"
  salt_length=16
  echo "$id"
  if [ -z "$mtd" ]; then
    key=$(echo $id | tail -c $(( ${#id} - $salt_length )))
    salt=$(echo $id | head -c $salt_length)
  else
    crypt_data="$(generate_data)"
    key="$(echo $crypt_data | tail -c $(( ${#crypt_data} - $salt_length )))"
    salt="$(echo $crypt_data | head -c $salt_length)"
  fi

  enc_id=$(echo $id | \
           openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 \
           -k "$key" -S "$salt" -base64 | \
           sed 's;[+/];;g' | head -c 32)
  echo $enc_id
}

encrypt_id
