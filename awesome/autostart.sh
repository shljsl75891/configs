#!/usr/bin/env bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

# programs
run "picom"
run "nitrogen --set-scaled --random /home/sahil.jassal/gitprojects/gruvbox-wallpapers/"
run "nm-applet"
