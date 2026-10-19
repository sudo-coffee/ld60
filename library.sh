#!/usr/bin/env bash
cd "$(dirname "$0")"
set -e

CPML_ADDRESS=https://github.com/excessive/cpml
CPML_TARGET=9edd67236be2e38be585783b61c704fc72d5df29

mkdir -p library/build/linux
mkdir -p library/build/windows
mkdir -p library/source

## \ -------- \ ---------------------------------------------------------- \ ##
## | download | ---------------------------------------------------------- | ##
## \ -------- \ ---------------------------------------------------------- \ ##

# love2d
printf '\n\x1b[36mDownloading Love2D...\x1b[0m\n'
wget $(printf '%s%s' 'https://github.com/love2d/love' \
  '/releases/download/11.5/love-11.5-x86_64.AppImage') \
  -nv -O library/build/linux/love
wget $(printf '%s%s' 'https://github.com/love2d/love' \
  '/releases/download/11.5/love-11.5-win64.zip') \
  -nv -O library/build/windows/love.zip
chmod +x library/build/linux/love

# cpml
printf '\n\x1b[36mDownloading CPML...\x1b[0m\n'
mkdir -p main/cpml
mkdir -p library/source/cpml
cd library/source/cpml
git init
git fetch --depth 1 "$CPML_ADDRESS" "$CPML_TARGET"
git -c advice.detachedhead=false checkout FETCH_HEAD
cp init.lua ../../../main/cpml/init.lua
cp LICENSE.md ../../../main/cpml/LICENSE.md
cp -r modules ../../../main/cpml/modules
cd ../../..

## \ --------------------------------------------------------------------- \ ##
## | --------------------------------------------------------------------- | ##
## \ --------------------------------------------------------------------- \ ##

printf '\n'
