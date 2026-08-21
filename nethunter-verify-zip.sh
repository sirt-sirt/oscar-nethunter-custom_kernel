#!/usr/bin/env bash
# =============================================================================
# Pre-flash verification for the NetHunter oscar kernel zip.
#
#   bash nethunter-verify-zip.sh NetHunter-Kernel-oscar-YYYYmmdd-HHMM.zip
#
# Reads the artifact and nothing else. No phone, no root, no flashing.
# Exit 0 = every hard requirement met.  Non-zero = DO NOT FLASH.
#
# Needs only unzip, tr, grep, find, sort. No binutils. On Windows use WSL.
# =============================================================================
set -u

ZIP="${1:-}"
WANT='5.4.280-qgki-ge408f03a5c42 SMP preempt mod_unload modversions aarch64'
MODS='modules/vendor/lib/modules'

# Absence of any of these is immediately visible to the user.
CRITICAL='camera qca_cld3_wlan btpower bt_fm_slim rmnet_core rmnet_ctl rmnet_offload rmnet_shs'

# The audio stack. Miss one and the phone boots silent.
AUDIO='adsp_loader_dlkm apr_dlkm bolero_cdc_dlkm machine_dlkm mbhc_dlkm native_dlkm
pa_manager_dlkm pinctrl_lpi_dlkm platform_dlkm q6_dlkm q6_notifier_dlkm q6_pdr_dlkm
rx_macro_dlkm snd_event_dlkm stub_dlkm swr_ctrl_dlkm swr_dlkm tx_macro_dlkm
va_macro_dlkm wcd937x_dlkm wcd937x_slave_dlkm wcd938x_dlkm wcd938x_slave_dlkm
wcd9xxx_dlkm wcd_core_dlkm wsa881x_analog_dlkm'

# Realme/oplus amplifier drivers and the QC debug stub. May not exist in this
# tree at all. Reported, never fatal.
OPTIONAL='aw87xxx_dlkm aw882xx_dlkm sia81xx_dlkm tfa98xx-v6_dlkm rdbg'

hard=0; soft=0
ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  WARN  %s\n' "$*"; soft=$((soft+1)); }
die()  { printf '  FAIL  %s\n' "$*"; hard=$((hard+1)); }
hdr()  { printf '\n== %s\n' "$*"; }

[ -n "$ZIP" ] || { echo "usage: bash $0 <NetHunter-Kernel-oscar-*.zip>"; exit 2; }
[ -f "$ZIP" ] || { echo "no such file: $ZIP"; exit 2; }
command -v unzip >/dev/null || { echo 'install unzip first'; exit 2; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
unzip -q -o "$ZIP" -d "$tmp" || { echo 'zip will not extract - it is corrupt'; exit 2; }

vermagic_of() { tr -c '[:print:]' '\n' < "$1" | grep -m1 '^vermagic=' | sed 's/^vermagic=//'; }
have() { [ -f "$tmp/$MODS/$1.ko" ]; }

hdr '1. kernel image'
if [ -s "$tmp/Image" ]; then ok "Image present, $(wc -c < "$tmp/Image" | tr -d ' ') bytes"
else die 'Image missing or empty - this zip cannot boot the phone'; fi

hdr '2. AnyKernel3 flags'
ak="$tmp/anykernel.sh"
if [ -f "$ak" ]; then
  for f in do.modules=1 do.systemless=1 is_slot_device=1; do
    if grep -q "^$f" "$ak"; then ok "$f"
    else die "$f is not set - modules would never be installed"; fi
  done
  if grep -q '^block=boot;' "$ak"; then ok 'block=boot; - slot resolved at runtime'
  else die 'block= is not plain boot; - a hardcoded slot can overwrite the wrong partition'; fi
  if grep -q '^device.name1=oscar' "$ak"; then ok 'device check pinned to oscar'
  else warn 'device.name1 is not oscar'; fi
else die 'anykernel.sh missing'; fi

hdr '3. module placement - the exact bug that made v9 useless'
flat=$(find "$tmp/modules" -maxdepth 1 -name '*.ko' 2>/dev/null | wc -l | tr -d ' ')
if [ "$flat" = 0 ]; then ok 'nothing sitting flat in modules/'
else die "$flat .ko flat in modules/ - AnyKernel3 copies those into the Magisk module root, where nothing ever loads them"; fi
if [ -d "$tmp/$MODS" ]; then
  ok "$MODS exists, $(find "$tmp/$MODS" -name '*.ko' | wc -l | tr -d ' ') modules inside"
else die "$MODS missing - the overlay would not land on /vendor/lib/modules"; fi

hdr '4. vermagic must match the phone byte for byte'
printf '  want: %s\n' "$WANT"
badmagic=0; checked=0; nomagic=0
for ko in $(find "$tmp/$MODS" -name '*.ko' 2>/dev/null | sort); do
  vm="$(vermagic_of "$ko")"; checked=$((checked+1))
  if [ -z "$vm" ]; then nomagic=$((nomagic+1))
  elif [ "$vm" != "$WANT" ]; then
    badmagic=$((badmagic+1))
    if [ "$badmagic" -le 5 ]; then printf '  FAIL  %s\n        got:  %s\n' "$(basename "$ko")" "$vm"; fi
  fi
done
if [ "$checked" = 0 ]; then die 'no modules to check at all'
elif [ "$badmagic" = 0 ]; then ok "$checked of $checked modules carry the exact device vermagic"
else die "$badmagic of $checked modules have the wrong vermagic - they would all be refused"; fi
if [ "$nomagic" != 0 ]; then warn "$nomagic modules exposed no vermagic string"; fi

hdr '5. critical modules'
for m in $CRITICAL; do
  if have "$m"; then ok "$m.ko"; else die "$m.ko MISSING"; fi
done

hdr '6. audio stack - any miss means a silent phone'
miss=''
for m in $AUDIO; do have "$m" || miss="$miss $m"; done
if [ -z "$miss" ]; then ok "all $(echo $AUDIO | wc -w | tr -d ' ') audio modules present"
else for m in $miss; do die "$m.ko MISSING"; done; fi

hdr '7. optional - vendor amps and debug stub'
for m in $OPTIONAL; do
  if have "$m"; then ok "$m.ko"
  else warn "$m.ko absent - affects only that amplifier / QC debug, not boot"; fi
done

hdr '8. Wi-Fi dongle driver'
if have 8188eu; then ok '8188eu.ko - TL-WN722N v2 monitor mode and injection'
else warn '8188eu.ko absent - internal Wi-Fi unaffected, but no monitor mode on the dongle'; fi

hdr 'verdict'
if [ "$hard" = 0 ]; then
  printf '  PASS - 0 hard failures, %d warnings. Safe to flash.\n' "$soft"
  printf '  Back up anyway:\n'
  printf "    su -c 'dd if=/dev/block/by-name/boot\$(getprop ro.boot.slot_suffix) of=/sdcard/boot-backup.img'\n"
  exit 0
else
  printf '  DO NOT FLASH - %d hard failures, %d warnings.\n' "$hard" "$soft"
  exit 1
fi
