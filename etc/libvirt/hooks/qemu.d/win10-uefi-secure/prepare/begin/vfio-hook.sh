#!/bin/bash

gpu="0000:03:00.0"
aud="0000:03:00.1"
gpu_vd="$(cat /sys/bus/pci/devices/$gpu/vendor) $(cat /sys/bus/pci/devices/$gpu/device)"
aud_vd="$(cat /sys/bus/pci/devices/$aud/vendor) $(cat /sys/bus/pci/devices/$aud/device)"

VIRSH_GPU="pci_$(echo $gpu|tr .: __)"
VIRSH_AUD="pci_$(echo $aud|tr .: __)"

function virsh_dev {
    echo "pci_$(echo $1|tr .: __)"
}

function bind_vfio {
  echo "$gpu" > "/sys/bus/pci/devices/$gpu/driver/unbind"
  echo "$aud" > "/sys/bus/pci/devices/$aud/driver/unbind"
  echo "$gpu_vd" > /sys/bus/pci/drivers/vfio-pci/new_id
  echo "$aud_vd" > /sys/bus/pci/drivers/vfio-pci/new_id
}

function unbind_vfio {
  echo "$gpu_vd" > "/sys/bus/pci/drivers/vfio-pci/remove_id"
  echo "$aud_vd" > "/sys/bus/pci/drivers/vfio-pci/remove_id"
  echo 1 > "/sys/bus/pci/devices/$gpu/remove"
  echo 1 > "/sys/bus/pci/devices/$aud/remove"
  echo 1 > "/sys/bus/pci/rescan"
}

function virsh_bind_vfio {
    for dev in $gpu $aud; do
        virsh nodedev-detach "$(virsh_dev $dev)"
    done
}

function virsh_unbind_vfio {
    for dev in $gpu $aud; do
        virsh nodedev-reattach "$(virsh_dev $dev)"
    done
}

VM_NAME="$1"
VM_ACTION="$2/$3"

# For convenient manual invocation
if [[ "$VM_NAME" == "bind" ]]; then
    virsh_bind_vfio
    exit
elif [[ "$VM_NAME" == "unbind" ]]; then
    virsh_unbind_vfio
    exit
fi

case "$VM_ACTION" in
    "prepare/begin")
        virsh_bind_vfio
        ;;
    "release/end")
        virsh_unbind_vfio
        ;;
esac
