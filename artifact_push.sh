#!/bin/bash
curl -sL https://raw.githubusercontent.com/travis-ci/artifacts/master/install | bash
tar -C dist -zcvf all.tgz .

export ARTIFACTS_PERMISSIONS="public-read"
export ARTIFACTS_TARGET_PATHS="/${TRAVIS_REPO_SLUG}/${TRAVIS_BRANCH}/${TRAVIS_JOB_NUMBER}/centos6/"
export ARTIFACTS_PATHS="all.tgz:dist/"
artifacts upload

echo "$ARTIFACTS_TARGET_PATHS" > latest.txt
export ARTIFACTS_TARGET_PATHS="/${TRAVIS_REPO_SLUG}/${TRAVIS_BRANCH}/centos6/"
export ARTIFACTS_PATHS="all.tgz:latest.txt"
artifacts upload
