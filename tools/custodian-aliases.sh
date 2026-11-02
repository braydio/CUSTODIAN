# Compatibility entrypoint for the hyphenated filename.
# The canonical command definitions remain in custodian_aliases.sh.
_custodian_alias_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${_custodian_alias_dir}/custodian_aliases.sh"
unset _custodian_alias_dir
