#!/usr/bin/env bash
# =============================================================================
# Add the missing symbol-namespace import to the aircrack-ng rtl8188eus fork.
#
#   bash nethunter/patch-rtl8188eus.sh <path-to-cloned-driver>
#
# Run 32571447245 built the driver cleanly and still ended with:
#
#   WARNING: module 8188eu uses symbol kernel_read from namespace
#   VFS_internal_I_am_really_a_filesystem_and_am_NOT_a_driver,
#   but does not import it.
#
# That is a modpost WARNING, so the build succeeds and the .ko looks fine. It
# is not fine. Since 5.4 the module loader enforces namespace imports, and
# CONFIG_MODULE_ALLOW_MISSING_NAMESPACE_IMPORTS is off on this device (checked
# against the stock config recovered from boot_backup_a.img), so insmod would
# refuse the module at runtime with no useful message.
#
# The driver calls kernel_read() from rtw_retrieve_from_file() in
# os_dep/linux/os_intfs.c, so that is where the import belongs.
#
# Guarded on the macro itself rather than on LINUX_VERSION_CODE: MODULE_IMPORT_NS
# either exists in linux/module.h or it does not, and #ifdef answers that
# question without assuming which backport a vendor tree happens to carry.
# =============================================================================
set -euo pipefail

SRC="${1:?usage: patch-rtl8188eus.sh <driver-source-dir>}"
F="$SRC/os_dep/linux/os_intfs.c"

if [ ! -f "$F" ]; then
  echo "::error::$F not found - the driver layout changed"
  exit 1
fi

if grep -q 'MODULE_IMPORT_NS' "$F"; then
  echo "  ok      MODULE_IMPORT_NS already present in os_intfs.c"
  exit 0
fi

{
  printf '\n'
  printf '/* NetHunter: rtw_retrieve_from_file() calls kernel_read(), which lives in\n'
  printf ' * the VFS symbol namespace since Linux 5.4. Without this import modpost\n'
  printf ' * only warns, and the module is then REFUSED at insmod time because\n'
  printf ' * CONFIG_MODULE_ALLOW_MISSING_NAMESPACE_IMPORTS is not set on oscar. */\n'
  printf '#ifdef MODULE_IMPORT_NS\n'
  printf 'MODULE_IMPORT_NS(VFS_internal_I_am_really_a_filesystem_and_am_NOT_a_driver);\n'
  printf '#endif\n'
} >> "$F"

echo "  ok      appended MODULE_IMPORT_NS to os_intfs.c"
echo "=== tail of os_intfs.c ==="
tail -n 9 "$F"
