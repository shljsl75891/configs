#!/usr/bin/env bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

# programs
run "picom"
run "nitrogen --set-scaled $HOME/personal/configs/LearnAndEarnWallpaper.png"
run "nm-applet"
run "copyq"
