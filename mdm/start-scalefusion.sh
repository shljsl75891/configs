#!/usr/bin/env bash
sudo launchctl load /Library/LaunchDaemons/com.promobitech.scalefusion.service.plist
sudo launchctl load /Library/LaunchDaemons/com.promobitech.scalefusion.jitadmin.plist
sudo launchctl load /Library/LaunchDaemons/com.promobitech.scalefusion.mac.secure-vpn-util.plist
launchctl load /Library/LaunchAgents/com.promobitech.scalefusion.mac.agent.plist
sudo launchctl load /Library/LaunchDaemons/com.promobitech.mac.veltar.proxyserver.plist
launchctl load /Library/LaunchAgents/com.promobitech.mac.veltar.agent.plist
sudo launchctl load /Library/LaunchDaemons/com.promobitech.remotecast.kickstarter.plist
sudo launchctl load /Library/LaunchDaemons/com.promobitech.remotecast.service.plist
launchctl load /Library/LaunchAgents/com.promobitech.remotecast.notification.plist
open -a '/Applications/Scalefusion-MDM Client.app' --hide
