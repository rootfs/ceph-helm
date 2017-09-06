#!/bin/bash

set -e
set -x 

git remote add openstack-helm https://github.com/openstack/openstack-helm  || true
git fetch openstack-helm


git branch -D helm-sync || true
git checkout openstack-helm/master -b helm-sync || true
git reset --hard openstack-helm/master

# this command rewrite git history to *only* include ceph, helm-toolkit, Makefile, README.rst
# Prune all other files in every commit
keep_pattern="^ceph|^helm-toolkit|^Makefile|^README.rst"
pruner="git ls-files | egrep -v \"$keep_pattern\" | git update-index --force-remove --stdin; git ls-files > /dev/stderr"
# Filter out commits for unrelated files
echo "Pruning commits for unrelated files..."
git filter-branch --index-filter "$pruner"  HEAD
# Filter out some merge commits
git filter-branch -f --commit-filter '
if [ "$GIT_AUTHOR_NAME" = "Jenkins" ];
then
skip_commit "$@";
else
git commit-tree "$@";
fi' helm-sync


git checkout master 
git branch ceph  || true
git checkout ceph 
# add it to incubator subtree
git subtree add --squash --prefix ceph refs/heads/helm-sync
