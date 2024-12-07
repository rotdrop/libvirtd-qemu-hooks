#!/usr/bin/env bash

#
# Original author: Rokas Kupstys <rokups@zoho.com>
# Heavily modified by: Danny Lin <danny@kdrag0n.dev>
#
# This hook uses the `cset` tool to dynamically isolate and unisolate CPUs using
# the kernel's cgroup cpusets feature. While it's not as effective as
# full kernel-level scheduler and timekeeping isolation, it still does wonders
# for VM latency as compared to not isolating CPUs at all. Note that vCPU thread
# affinity is a must for this to work properly.
#
# Original source: https://rokups.github.io/#!pages/gaming-vm-performance.md
#
# Target file locations:
#   - $SYSCONFDIR/hooks/qemu.d/vm_name/prepare/begin/cset.sh
#   - $SYSCONFDIR/hooks/qemu.d/vm_name/release/end/cset.sh
# $SYSCONFDIR is usually /etc/libvirt.
#

TOTAL_CORES='0-23'
TOTAL_CORES_MASK=FFFFFF         # 0-7, bitmask 0b11111111
HOST_CORES='0-7,12-19'          # Cores reserved for host
HOST_CORES_MASK=0FF0FF          # 0,4, bitmask 0b00010001
VIRT_CORES='8-11,20-23'         # Cores reserved for virtual machine(s)
# VIRT_CORES_MASK='F00F00'

VM_NAME="$1"
VM_ACTION="$2/$3"

IRQS="$(grep -E '^\s+[0-9]+:' /proc/interrupts|cut -d: -f 1|sort -n)"

function shield_vm() {
    # cset does no longer work
    # cset -m set -c $TOTAL_CORES -s machine.slice
    # cset -m shield --kthread on --cpu $VIRT_CORES
    systemctl set-property --runtime machine.slice AllowedCPUs=$TOTAL_CORES
    systemctl set-property --runtime init.scope AllowedCPUs=$HOST_CORES
    systemctl set-property --runtime user.slice AllowedCPUs=$HOST_CORES
    systemctl set-property --runtime system.slice AllowedCPUs=$HOST_CORES
    # Migrate irqs to HOST_CORES (see https://www.suse.com/c/cpu-isolation-practical-example-part-5/)
    for I in $IRQS; do
        if [[ -d /proc/irq/$I ]]; then
            # some affinities cannot be changed.
            echo $HOST_CORES > "/proc/irq/$I/smp_affinity_list" 2> /dev/null
        fi
    done
}

function unshield_vm() {
    # cset does no longer work
    # cset -m shield --reset
    systemctl set-property --runtime machine.slice AllowedCPUs=$TOTAL_CORES
    systemctl set-property --runtime init.scope AllowedCPUs=$TOTAL_CORES
    systemctl set-property --runtime user.slice AllowedCPUs=$TOTAL_CORES
    systemctl set-property --runtime system.slice AllowedCPUs=$TOTAL_CORES
    for I in $IRQS; do
        if [[ -d /proc/irq/$I ]]; then
            # some affinities cannot be changed.
            echo $TOTAL_CORES > "/proc/irq/$I/smp_affinity_list" 2> /dev/null
        fi
    done
}

# For convenient manual invocation
if [[ "$VM_NAME" == "shield" ]]; then
    shield_vm
    exit
elif [[ "$VM_NAME" == "unshield" ]]; then
    unshield_vm
    exit
fi

if [[ "$VM_ACTION" == "prepare/begin" ]]; then
    echo "libvirt-qemu cset: Reserving CPUs $VIRT_CORES for VM $VM_NAME" > /dev/kmsg 2>&1
    shield_vm > /dev/kmsg 2>&1

    # the kernel's dirty page writeback mechanism uses kthread workers. They introduce
    # massive arbitrary latencies when doing disk writes on the host and aren't
    # migrated by cset. Restrict the workqueue to use only cpu 0.
    echo $HOST_CORES_MASK > /sys/bus/workqueue/devices/writeback/cpumask
    # echo 0 > /sys/bus/workqueue/devices/writeback/numa

    echo "libvirt-qemu cset: Successfully reserved CPUs $VIRT_CORES" > /dev/kmsg 2>&1
elif [[ "$VM_ACTION" == "release/end" ]]; then
    echo "libvirt-qemu cset: Releasing CPUs $VIRT_CORES from VM $VM_NAME" > /dev/kmsg 2>&1
    unshield_vm > /dev/kmsg 2>&1

    # Revert changes made to the writeback workqueue
    echo $TOTAL_CORES_MASK > /sys/bus/workqueue/devices/writeback/cpumask
    # echo 1 > /sys/bus/workqueue/devices/writeback/numa

    echo "libvirt-qemu cset: Successfully released CPUs $VIRT_CORES" > /dev/kmsg 2>&1
fi
