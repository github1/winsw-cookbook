#!/usr/bin/env bash

instance_info=.kitchen/default-windows-2019.yml

if [[ ! -f "${instance_info}" ]]; then
  >&2 echo "[ERROR] ${instance_info} not found"
  exit 1
fi

pass=$(aws ec2 get-password-data \
  --instance-id $(cat "${instance_info}" | grep server_id | awk '{print $2}') \
  --priv-launch-key $(cat "${instance_info}" | grep ssh_key | awk '{print $2}' | tr -d '"') | jq -r .PasswordData)

result=$(osascript -e "display dialog \"${pass}\"" 2>&1)
if [[ "${result}" =~ .*OK$ ]]; then
  echo 'auto connect:i:1' > instance.rdp
  echo "full address:s:$(cat "${instance_info}" | grep hostname | awk '{print $2}')" >> instance.rdp
  echo 'username:s:Administrator' >> instance.rdp
  open /Applications/Microsoft\ Remote\ Desktop.app/ instance.rdp
fi