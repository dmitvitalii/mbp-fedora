#!/bin/bash

set -eu -o pipefail

FEDORA_KICKSTARTS_GIT_URL=https://pagure.io/fedora-kickstarts.git
FEDORA_KICKSTARTS_BRANCH_NAME=f31
FEDORA_KICKSTARTS_COMMIT_HASH=8ea142456d5152a864056c48b1e3298eda29037e        # https://pagure.io/fedora-kickstarts/commits/f31
LIVECD_CACHE_PATH=/var/cache/live

### Debug commands
echo "FEDORA_KICKSTARTS_BRANCH_NAME=${FEDORA_KICKSTARTS_BRANCH_NAME}"
echo "FEDORA_KICKSTARTS_COMMIT_HASH=${FEDORA_KICKSTARTS_COMMIT_HASH}"
pwd
ls
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

### Dependencies
dnf install -y git livecd-tools zip

### Copy efibootmgr fix for anaconda
mkdir -p /tmp/kickstart_files/
cp -rfv files/* /tmp/kickstart_files/

### Clone Fedora kickstarts repo
git clone --single-branch --branch ${FEDORA_KICKSTARTS_BRANCH_NAME} ${FEDORA_KICKSTARTS_GIT_URL}
cd fedora-kickstarts
git checkout $FEDORA_KICKSTARTS_COMMIT_HASH

### Copy fedora-mbp kickstart file
cp -rfv ../fedora-mbp.ks ./
mkdir -p ${LIVECD_CACHE_PATH}

### Workaround - travis_wait
while true
do
  date
  sleep 30
done &
bgPID=$!

### Generate LiveCD iso
livecd-creator --verbose --config=fedora-mbp.ks --cache=${LIVECD_CACHE_PATH}
livecd_exitcode=$?

### Zip iso and split it into multiple parts - github max size of release attachment is 2GB, where ISO is sometimes bigger than that
mkdir -p ./output_zip
zip -s 1500m ./output_zip/livecd.zip ./*.iso

### Calculate sha256 sums of built ISO
sha256sum ./*.iso > ./output_zip/sha256

find ./ | grep ".iso"
find ./ | grep ".zip"
kill "$bgPID"

exit $livecd_exitcode
