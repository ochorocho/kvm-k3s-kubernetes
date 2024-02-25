#!/usr/bin/env bash

qemu="${URI}"
token_file="/var/lib/rancher/k3s/server/node-token"
domain="${DOMAIN}"

function token_command_pid() {
    virsh -c "${qemu}" qemu-agent-command $domain '{"execute": "guest-exec", "arguments": { "path": "sudo", "arg": [ "cat","'${token_file}'" ], "capture-output": true }}' --pretty | jq '.return.pid'
}

while true; do
    pid=$()
    file_exitcode=$(virsh -c "${qemu}" qemu-agent-command $domain '{"execute": "guest-exec-status", "arguments": { "pid": '$(token_command_pid)' }}' --pretty | jq -r '.return.exitcode')

    if [ "$file_exitcode" -eq 0 ]; then
      break
    fi

    sleep 10
done

data=$(virsh -c "${qemu}" qemu-agent-command $domain '{"execute": "guest-exec-status", "arguments": { "pid": '$(token_command_pid)' }}' --pretty | jq '.return')
echo $data | jq -r '."out-data"' | base64 -d > .generated/k3s-token.txt
