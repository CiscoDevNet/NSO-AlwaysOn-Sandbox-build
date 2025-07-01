#!/usr/bin/env bash

# The MIT License (MIT)
#
# Copyright (c) 2016-present Kevin Newton
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


shopt -s nullglob
dir_count=0
file_count=0

traverse() {
  dir_count=$(($dir_count + 1))
  local directory=$1
  local prefix=$2

  local children=("$directory"/*)
  local child_count=${#children[@]}

  for idx in "${!children[@]}"; do
    local child=${children[$idx]}

    local child_prefix="│   "
    local pointer="├── "

    if [ $idx -eq $((child_count - 1)) ]; then
      pointer="└── "
      child_prefix="    "
    fi

    echo "${prefix}${pointer}${child##*/}"
    [ -d "$child" ] &&
      traverse "$child" "${prefix}$child_prefix" ||
      file_count=$((file_count + 1))
  done
}

root="."
[ "$#" -ne 0 ] && root="$1"
echo $root

traverse $root ""
echo
echo "$(($dir_count - 1)) directories, $file_count files"
shopt -u nullglob
