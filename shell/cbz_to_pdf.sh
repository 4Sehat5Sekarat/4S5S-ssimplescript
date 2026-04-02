#!/usr/bin/env bash

TEMP_PATH="."
TEMP_FOLDER="${TEMP_PATH}/.temp_${RANDOM}"
FILENAME="$(basename "$1" .cbz)"

if [[ -z $1 ]]; then
  echo "Need one argument"
  exit 1
fi 

if [[ ! -f "$1" ]]; then
  echo "File [$1] not found"
  exit 1
fi

mkdir -p "$TEMP_FOLDER" || {
  echo "Fail create folder"
  exit 1
}

unzip "$1" -d "$TEMP_FOLDER" > /dev/null || exit 1

shopt -s nullglob nocaseglob

images=(
  "$TEMP_FOLDER"/*.png
  "$TEMP_FOLDER"/*.jpg
  "$TEMP_FOLDER"/*.jpeg
  "$TEMP_FOLDER"/*.webp
)

if ((${#images[@]} == 0)); then
  echo "No images found"
  rm -r "$TEMP_FOLDER"
  exit 1
fi

magick "${images[@]}" "${FILENAME}.pdf"

rm -r "$TEMP_FOLDER" && echo "Delete Oke!" || echo "Delete temp fail"
