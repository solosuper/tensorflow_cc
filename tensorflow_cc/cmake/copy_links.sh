#!/bin/bash
set -e
# This file recursively traverses a directory and replaces each
# link by a copy of its target.

echo "Replacing links with the copies of their targets."
echo "This may take a while..."
cp -R "${1}" "${1}.bak"
rsync -amLq "${1}/" "__tmp__/"
rm -rf "${1}"
mv "__tmp__" "${1}"
