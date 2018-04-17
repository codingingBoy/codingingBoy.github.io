#!/usr/bin/env bash
#
# This script can be used to sync the wiki submodule
# in case you're using github internal wiki option
#

cd ~/Blog
git add --all
git commit -m "update blog"
git push

