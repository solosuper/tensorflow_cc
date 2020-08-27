#!/usr/bin/env bash
set -euxo pipefail

BAZEL_VERSION=$(curl -fsL https://raw.githubusercontent.com/tensorflow/tensorflow/v${TENSORFLOW_TAG}/configure.py | grep -Po "(?<=_TF_MIN_BAZEL_VERSION = ').+(?=')")
sudo apt -qq update && sudo apt install -qqy bazel-${BAZEL_VERSION}
sudo ln -s /usr/bin/bazel-${BAZEL_VERSION} /usr/bin/bazel
