# libvirtd-qemu-hooks

Collection of hooks for libvirtd. Just a loose collection for my Win11
virtual machine, doing GPU passthrough on the fly and some
optimizations. There is more to it than just this loose collection of
scripts.

This package is actually not meant to evolve into some pnp installable
helper program project.

## References

- https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
- https://github.com/bryansteiner/gpu-passthrough-tutorial
- https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/

In particular, the hooks are run with the help of
https://github.com/PassthroughPOST/VFIO-Tools, the directory structure
tries to resemble the directory structure of the host.

## Hooks

/etc/libvirt/hooks
 * [qemu](etc/libvirt/hooks/qemu)
 * [qemu.d](etc/libvirt/hooks/qemu.d)
     * [win10-uefi-secure](etc/libvirt/hooks/qemu.d/win10-uefi-secure)
         * [prepare](etc/libvirt/hooks/qemu.d/win10-uefi-secure/prepare)
           * [begin](etc/libvirt/hooks/qemu.d/win10-uefi-secure/prepare/begin)
           * [vfio-hook.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/prepare/begin/vfio-hook.sh)
           * [looking-glass.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/prepare/begin/looking-glass.sh)
           * [cset-hook.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/prepare/begin/cset-hook.sh)
         * [release](etc/libvirt/hooks/qemu.d/win10-uefi-secure/release)
             * [end](etc/libvirt/hooks/qemu.d/win10-uefi-secure/release/end)
                 * [vfio-hook.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/release/end/vfio-hook.sh -> ../../prepare/begin/vfio-hook.sh)
                 * [looking-glass.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/release/end/looking-glass.sh -> ../../prepare/begin/looking-glass.sh)
                 * [cset-hook.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/release/end/cset-hook.sh -> ../../prepare/begin/cset-hook.sh)claus@anaxagoras /net/anaxagoras/usr/local

### Dynamic VFIO Passthrough

[vfio-hook.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/prepare/begin/vfio-hook.sh)
binds the GPU and GPU-audio device at runtime to vfio when the VM
guest starts and binds them again to the standard Linux GPU drivers
when the VM terminates.

### Kernel Module Loading

[looking-glass.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/prepare/begin/looking-glass.sh)
justs loads and removes the Looking-Glas kvmfr module.

### Sort of CPU Isolation

[cset-hook.sh](etc/libvirt/hooks/qemu.d/win10-uefi-secure/prepare/begin/cset-hook.sh)
tries to tune the CPU-affinity of IRQs tries to configure the kernel
such that the CPUs pinned to the VM are not bothered with other (Linux kernel) tasks.

