#!/usr/bin/env bash

cd

downloadUrl=`curl -s https://api.github.com/repos/dehydrated-io/dehydrated/releases/latest | grep -E '.*https.*dehydrated.*.tar.gz"' | cut -d '"' -f 4`

echo "Downloading $downloadUrl"

curl -L -o dehydrated.tar.gz "$downloadUrl"

mkdir /root/dehydrated

tar --strip-components=1 -xzf dehydrated.tar.gz -C /root/dehydrated

rm dehydrated.tar.gz

mkdir -p /opt/dehydrated
cp /root/dehydrated/dehydrated /opt/dehydrated/dehydrated.sh
chmod +x /opt/dehydrated/dehydrated.sh
