#!/bin/sh
# Find all Matchbox directories
echo "Installing SyLens Matchbox. I will need your sudo password for this (or run the script as root if your IFFS user is not a sudoer)."

find /usr/discreet/* -name "matchbox" -maxdepth 1 | \
while read line
do
  echo "Copying the shaders to $line/"
  sudo cp SyLens.glsl.p SyLens.glsl SyLens.xml $line/
done