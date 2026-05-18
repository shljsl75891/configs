#!/usr/bin/env bash
# Unified MDM suppression — runs automatically at login via personal.kill-agents LaunchAgent
# Manually: ~/.local/bin/kill-agents

# Wait for MDM agents to finish loading post-login
sleep 10

# --- Zscaler ---
sudo launchctl unload /Library/LaunchDaemons/com.zscaler.service.plist 2>/dev/null
sudo launchctl unload /Library/LaunchDaemons/com.zscaler.tunnel.plist 2>/dev/null
launchctl unload /Library/LaunchAgents/com.zscaler.tray.plist 2>/dev/null
pkill -f Zscaler 2>/dev/null

# --- ScaleFusion ---
sudo launchctl unload /Library/LaunchDaemons/com.promobitech.scalefusion.service.plist 2>/dev/null
sudo launchctl unload /Library/LaunchDaemons/com.promobitech.scalefusion.jitadmin.plist 2>/dev/null
sudo launchctl unload /Library/LaunchDaemons/com.promobitech.scalefusion.mac.secure-vpn-util.plist 2>/dev/null
launchctl unload /Library/LaunchAgents/com.promobitech.scalefusion.mac.agent.plist 2>/dev/null
pkill -f Scalefusion 2>/dev/null
pkill -f SecureVPNUtil 2>/dev/null

exit 0
