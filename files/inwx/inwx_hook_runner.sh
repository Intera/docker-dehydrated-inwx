#!/usr/bin/env bash

./inwx_acme_hook.sh "$@" # Hook for automatic DNS-01 challenge deployment on inwx.de
./dehydrated_hook.sh "$@" # Creates /tmp/dehydrated_cert_generated when certs where refreshed
