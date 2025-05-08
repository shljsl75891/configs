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
brave-browser --profile-directory='Profile 1' https://sourcefuse.peoplestrong.com/oneweb/#/home
