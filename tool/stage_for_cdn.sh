#!/usr/bin/env bash

set -e
shopt -s extglob

# This script limits what is pushed to the CDN. Only prod assets
# are included in the bundle that is pushed to the CDN.

rm -rf static

# create static/ directory that will be deployed to CDN
mkdir static/

# stage dart packages
cp -RL build/test/packages static/

# stage compiled Dart parts and source maps
cp build/test/*dart*.+(js|js.map) static/
