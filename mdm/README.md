# MDM Suppression

Automatically kills Zscaler and ScaleFusion at login. Selective re-enable via shell aliases.

## How it works

A user LaunchAgent (`personal.kill-agents`) runs `kill-agents.sh` at every login with a 10s delay (to let MDM agents finish loading first). The script unloads all MDM-related launch daemons/agents using passwordless `sudo` scoped to only those specific plists.

```
kill-agents.sh              ← unified kill (auto at login + manual)
start-zscaler.sh            ← re-enable Zscaler selectively
start-scalefusion.sh        ← re-enable ScaleFusion selectively
personal.kill-agents.plist  ← LaunchAgent that triggers kill at login
sudoers-mdm                 ← sudoers drop-in for passwordless launchctl
```

## Setup

Replace `YOUR_USERNAME` with your macOS username (`whoami`) in:
- `personal.kill-agents.plist` — line with `/Users/YOUR_USERNAME/.local/bin/kill-agents`
- `sudoers-mdm` — last line (`%USERNAME%`)

Then run:

```sh
# 1. sudoers drop-in (scoped NOPASSWD for launchctl only)
sudo cp sudoers-mdm /etc/sudoers.d/mdm-suppression
sudo chmod 440 /etc/sudoers.d/mdm-suppression
sudo visudo -c  # validate — must print "parsed OK"

# 2. scripts
chmod +x kill-agents.sh start-zscaler.sh start-scalefusion.sh
ln -sf "$(pwd)/kill-agents.sh"     ~/.local/bin/kill-agents
ln -sf "$(pwd)/start-zscaler.sh"   ~/.local/bin/start-zscaler
ln -sf "$(pwd)/start-scalefusion.sh" ~/.local/bin/start-scalefusion

# 3. LaunchAgent
ln -sf "$(pwd)/personal.kill-agents.plist" ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/personal.kill-agents.plist
```

Run setup commands from inside the `mdm/` directory.

## Shell aliases

Add to your shell config (`.zshrc` / `.bashrc`):

```zsh
alias start-zscaler="~/.local/bin/start-zscaler"
alias start-scalefusion="~/.local/bin/start-scalefusion"
```

## Uninstall / re-enable permanently

```sh
launchctl unload ~/Library/LaunchAgents/personal.kill-agents.plist
rm ~/Library/LaunchAgents/personal.kill-agents.plist
sudo rm /etc/sudoers.d/mdm-suppression
```

## Caveats

- **ScaleFusion tamperlock** — ScaleFusion ships an Endpoint Security system extension (`com.promobitech.scalefusion.mac.tamperlock.esextension`) running as root. It may detect and revive killed processes. If that happens, the 10s sleep in `kill-agents.sh` may need to be increased, or the script may need to run periodically (add `StartInterval` to the plist).
- **macOS updates** — plist paths are hardcoded. Verify after OS or MDM agent updates.
- **`visudo -c` must pass** — a broken sudoers file can lock you out of sudo. Always validate.
