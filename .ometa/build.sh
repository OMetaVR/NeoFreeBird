#!/usr/bin/env bash
# Upstream's release.yml: build.sh in all four modes, then Twitter-branded copies of the
# IPAs via rebrand.sh with upstream's default icon pack.
source "$PIPELINE/lib/helpers.sh"
setup_theos 16.5 master   # NeoFreeBird is developed against current Theos/Logos
install_cyan

sed -i '' 's/^TARGET.*$/TARGET := iphone:clang:16.5:15.0/' Makefile   # upstream workflow's defaults
export BUILD_DIR="$SRC/.ometa-ffmpeg-build"                          # ffmpeg build dir (cached)
NAME=$(sed -n 's/^Name: *//p' control)
VERSION=$(awk '/^Version:/ {print $2}' control)
mkdir -p packages
cp "$BASE_IPA" packages/com.atebits.Tweetie2.ipa

./build.sh --sideloaded
./build.sh --trollstore
./build.sh --rootless
./build.sh --rootfull
cp packages/*.deb "$OUT/"

curl -fsSL --retry 3 https://files.catbox.moe/p63f20.zip -o resource-pack.zip || rm -f resource-pack.zip
for mode in sideloaded trollstore; do
  ext=ipa; [ "$mode" = trollstore ] && ext=tipa
  X="$OUT/$NAME-$mode-X_${VERSION}_$BASE_VERSION.$ext"
  mv "packages/NeoFreeBird-$mode.$ext" "$X"
  ./rebrand.sh --twitter-branding $( [ -f resource-pack.zip ] && echo --resource-pack resource-pack.zip ) \
    -o "$OUT/$NAME-$mode-Twitter_${VERSION}_$BASE_VERSION.$ext" "$X"
done
