#!/bin/bash
set -euxo pipefail
# This file recursively traverses a directory and replaces each
# link by a copy of its target.

echo "Replacing links with the copies of their targets."
echo "This may take a while..."
rsync -amL ${1}/ __tmp__

# But keep symlinks for the so-files
rsync -al ${1}/tensorflow/libtensorflow_cc.so* __tmp__/tensorflow/

rm -rf "${1}"
mv __tmp__ bazel-bin
