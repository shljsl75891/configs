#!/usr/bin/env bash
sudo launchctl load /Library/LaunchDaemons/com.zscaler.service.plist
sudo launchctl load /Library/LaunchDaemons/com.zscaler.tunnel.plist
launchctl load /Library/LaunchAgents/com.zscaler.tray.plist
open -a /Applications/Zscaler/Zscaler.app --hide
