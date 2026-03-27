#!/bin/sh

set -eu

git init frappe_docker

cd frappe_docker
git remote | grep -qs origin && git remote remove origin
git remote add origin https://github.com/frappe/frappe_docker.git
git fetch --depth 1 origin 99d9a1dc385d8a0660a67b0cbbfeac3d5229e58c
git config --local advice.detachedHead false
git checkout FETCH_HEAD

[ $? -eq 0 ] && echo "Repository successfully cloned." || echo "Something went wrong."

