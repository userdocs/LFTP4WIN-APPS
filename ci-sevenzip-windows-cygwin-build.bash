#!/usr/bin/env bash

HOME="$(pwd)"

sevenzip="$(curl -sL https://sourceforge.net/projects/sevenzip/best_release.json | jq -r '.platform_releases.windows.filename')"
sevenzip_filename="${sevenzip#/7-Zip/}"
first=${sevenzip_filename%/*} first=${first/\./}

echo "https://www.7-zip.org/a/7z${first}-extra.7z"

curl -L "https://www.7-zip.org/a/7z${first}-extra.7z" -o "sevenzip.7z"
tar xf "sevenzip.7z" -C "$HOME/sevenzip_tmp"

mkdir -p "${HOME}/lftp4win_bin"
cp -f "$HOME/sevenzip_tmp/x64/"* "$HOME/lftp4win_bin"
