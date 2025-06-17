#!/bin/sh
echo -ne '\033c\033]0;Taggable\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/image_tagger_linux_01.x86_64" "$@"
