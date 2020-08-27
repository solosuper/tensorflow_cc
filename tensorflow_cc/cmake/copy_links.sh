#!/bin/bash
set -euxo pipefail
# This file recursively traverses a directory and replaces each
# link by a copy of its target.
# But keep symlinks for the so-files

echo "Replacing links with the copies of their targets."
echo "This may take a while..."
rsync -amL --exclude="libtensorflow_cc.so*" ${1}/ __tmp__
rsync -aml --include="libtensorflow_cc.so*" --include="*/" --exclude="*" "${1}/" __tmp__

rm -rf "${1}"
mv __tmp__ bazel-bin
