#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir="$script_dir/operator_live_bridge"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
extensions_dir="$config_root/aseprite/extensions"
target_path="$extensions_dir/custodian-operator-live-bridge"

mkdir -p -- "$extensions_dir"

if [[ -L "$target_path" ]]; then
  current_target=$(readlink -f -- "$target_path")
  if [[ "$current_target" == "$source_dir" ]]; then
    echo "Operator Live Bridge extension is already linked: $target_path"
    exit 0
  fi
  echo "Refusing to replace symlink with a different target: $target_path" >&2
  exit 1
fi

if [[ -e "$target_path" ]]; then
  echo "Refusing to replace existing extension path: $target_path" >&2
  exit 1
fi

ln -s -- "$source_dir" "$target_path"
echo "Installed Operator Live Bridge extension symlink: $target_path"
echo "Restart Aseprite to load or reload the plugin."
