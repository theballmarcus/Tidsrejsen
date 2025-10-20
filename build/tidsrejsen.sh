#!/bin/sh
echo -ne '\033c\033]0;Tidsrejse Projekt Teknik\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/tidsrejsen.x86_64" "$@"
