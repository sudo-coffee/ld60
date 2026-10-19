#!/usr/bin/env bash
cd "$(dirname "$0")"
set -e

TITLE=stars-and-the-sea
NAME='Stars of the Sea'

## \ ----- \ ------------------------------------------------------------- \ ##
## | build | ------------------------------------------------------------- | ##
## \ ----- \ ------------------------------------------------------------- \ ##

# love
mkdir -p build/love
(cd main && zip -r "../build/love/$TITLE.love" *)

# windows
mkdir -p "build/temp/$TITLE"
mkdir -p build/windows
unzip -j library/build/windows/love.zip -d "build/temp/$TITLE"
mv "build/temp/$TITLE/license.txt" "build/temp/$TITLE/license-love.txt"
cp library/source/cpml/LICENSE.md "build/temp/$TITLE/license-cpml.txt"
rm "build/temp/$TITLE/game.ico"
rm "build/temp/$TITLE/love.ico"
rm "build/temp/$TITLE/readme.txt"
rm "build/temp/$TITLE/changes.txt"
rm "build/temp/$TITLE/lovec.exe"
cat "build/love/$TITLE.love" >> "build/temp/$TITLE/love.exe"
mv "build/temp/$TITLE/love.exe" "build/temp/$TITLE/$TITLE.exe"
(cd "build/temp" && zip -r "../windows/$TITLE-windows.zip" "$TITLE")
rm -r build/temp

# linux
mkdir -p build/linux
mkdir -p build/temp
(cd build/temp && ../../library/build/linux/love --appimage-extract)
rm build/temp/squashfs-root/love.svg
rm build/temp/squashfs-root/love.desktop
touch "build/temp/squashfs-root/$TITLE.png"
echo '[Desktop Entry]
Name='"$NAME"'
MimeType=application/x-love-game
Categories=Game
Exec=love %f
Type=Application
Terminal=false
Icon='"$TITLE"'
NoDisplay=true' > "build/temp/squashfs-root/$TITLE.desktop"
(cd build/temp/squashfs-root && mv license.txt license-love.txt)
cp library/source/cpml/LICENSE.md build/temp/squashfs-root/license-cpml.txt
cat "build/love/$TITLE.love" >> build/temp/squashfs-root/bin/love
appimagetool build/temp/squashfs-root "build/linux/$TITLE-linux"
rm -r build/temp

## \ --------------------------------------------------------------------- \ ##
## | --------------------------------------------------------------------- | ##
## \ --------------------------------------------------------------------- \ ##
