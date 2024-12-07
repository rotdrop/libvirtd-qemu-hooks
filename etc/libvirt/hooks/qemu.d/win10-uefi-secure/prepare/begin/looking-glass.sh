#!/bin/bash

VM_NAME="$1"
VM_ACTION="$2/$3"

# For convenient manual invocation
if [[ "$VM_NAME" == "load" ]]; then
    modprobe kvmfr
    exit
elif [[ "$VM_NAME" == "unload" ]]; then
    modprobe -r kvmfr
    exit
fi

case "$VM_ACTION" in
    "prepare/begin")
	modprobe kvmfr
        ;;
    "release/end")
	modprobe -r kvmfr
        ;;
esac
