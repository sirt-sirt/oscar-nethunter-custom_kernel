# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=NetHunter Kernel for Realme 9 Pro (oscar)
do.devicecheck=1
do.modules=1
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=oscar
device.name2=RMX3471
device.name3=RMX3472
device.name4=holi
device.name5=RE54CBL1
device.name6=RMX3472 (RE54CBL1)
'; } # end properties

# shell variables
block=/dev/block/by-name/boot_a;
BLOCK=/dev/block/by-name/boot_a;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel boot install
dump_boot;

# write boot
write_boot;
