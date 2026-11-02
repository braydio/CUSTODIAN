# Vault Storage Runtime Sprites

This is the permanent runtime home for vault construction and resource-storage prop sprites used by gameplay scenes.

Runtime scripts and scenes should reference this folder, not scattered source or review folders such as:

- `res://content/props/gothic/vault_storage/`
- `res://content/props/gothic/vault_dressing/`
- `res://content/props/gothic/vault_dressing/source/`

Current state sprites:

- `vault_storage__chest_small__empty__1f__160x128.png`
- `vault_storage__chest_small__stored__1f__160x128.png`
- `vault_storage__chest_small__open__1f__160x128.png`
- `vault_storage__chest_small__damaged__1f__160x128.png`

Source/review art can remain in owner-specific prop folders. Promote only the concrete state sprites consumed by runtime storage scenes into this folder.
