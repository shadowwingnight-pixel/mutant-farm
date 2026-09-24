# Mutant Farm

Minimal Rojo project for Luau development. No gameplay is implemented.

## Source layout

| Directory | Roblox Studio destination |
| --- | --- |
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared` | `ReplicatedStorage.Shared` |

Use `*.server.luau` for server Scripts, `*.client.luau` for LocalScripts,
and `*.luau` for ModuleScripts. The `.gitkeep` files preserve empty folders
in Git and do not create Roblox instances. Shared code is visible to clients.

## Install Rojo on Windows

Download the Windows ZIP for your architecture from the
[official stable Rojo release](https://github.com/rojo-rbx/rojo/releases/latest).
Extract `rojo.exe` to a dedicated folder such as `C:\Tools\Rojo` and add that
folder to your **user Path** environment variable. Open a new PowerShell
window and run `rojo --version`. No additional toolchain is required.

With Roblox Studio installed and closed, install the matching Studio plugin:

```powershell
rojo plugin install
```

See the [official installation guide](https://rojo.space/docs/v7/getting-started/installation/).

## Connect Roblox Studio

1. In PowerShell, start the local server:

   ```powershell
   Set-Location D:\MutantFarm
   rojo serve default.project.json
   ```

2. Leave that terminal running. Open Roblox Studio and create or open a local
   Baseplate place.
3. In Studio's Plugins toolbar, open **Rojo**. Set the host to `localhost`
   and port to `34872` if prompted, then click **Connect**.
4. If a sync preview or confirmation appears, review it and accept the sync.
5. In Explorer, verify the `Server`, `Client`, and `Shared` folders at the
   destinations listed above. They are intentionally empty.
6. When you later add and save Luau files under `src`, Rojo syncs them into
   Studio while connected. Edit source files in this folder for this workflow;
   Studio script edits are not automatically saved back by live sync.

Use **Disconnect** in the plugin and `Ctrl+C` in PowerShell to stop syncing.
Save your place in Studio to retain Studio-authored objects. This project does
not map Workspace or generate any gameplay objects.

See the [official live-sync guide](https://rojo.space/docs/v7/getting-started/new-game/#live-syncing-into-studio).

## Optional build

Once Rojo is available, validate and build a local place with:

```powershell
rojo build default.project.json -o build.rbxlx
```

Generated place files are ignored by Git. The repository is local only; no
GitHub repository or remote is required for Studio sync.
