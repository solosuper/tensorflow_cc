#!/bin/bash
set -e
# This file recursively traverses a directory and replaces each
# link by a copy of its target.

echo "Replacing links with the copies of their targets."
echo "This may take a while..."
rsync -amL ${1}/ __tmp__
