#!/usr/bin/env bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

# programs
run "flameshot"
run "picom"
run "nitrogen --restore"
run "nm-applet"
run "blueman-applet"
