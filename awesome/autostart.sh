#!/usr/bin/env bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

# programs
run "picom"
run "nitrogen --set-scaled --random $HOME/gitprojects/wallpapers"
run "nm-applet"
run "copyq"

# for remembering to punch in
xinput set-prop 'DELL0A20:00 06CB:CE65 Touchpad' 'libinput Tapping Enabled' 1
xinput set-prop 'DELL0A20:00 06CB:CE65 Touchpad' 'libinput Natural Scrolling Enabled' 1
brave-browser --profile-directory='Profile 1' https://sourcefuse.peoplestrong.com/oneweb/#/home
