#!/bin/bash

# Copyright (c) Joakim Reinert. All rights reserved.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

API_URL='https://api.domrobot.com/xmlrpc/'
TMPDIR='/tmp/inwx-acme'

echo $BASEDIR/inwx-acme.auth
source "$BASEDIR/inwx-acme.auth" # contains user and pass variables

USER=$user
PASS=$pass

build_method_call() {
    local method_name=$1
    shift
    echo -n "<?xml version=\"1.0\"?>"
    echo -n "<methodCall>"
    echo -n "<methodName>$method_name</methodName>"
    echo -n "<params><param><value><struct>"

    for param in "$@"; do
        echo -n "$param"
    done

    echo -n "$(build_param "user" "$USER")"
    echo -n "$(build_param "pass" "$PASS")"

    echo -n "</struct></value></param></params>"
    echo -n "</methodCall>"
}

build_param() {
    local name=$1
    local value=$2
    local type=${3:-string}
    echo -n '<member>'
    echo -n "<name>$name</name>"
    echo -n "<value><$type>"
    if [[ "$type" = 'string' ]]; then
        echo -n "<![CDATA[$value]]>"
    else
        echo -n "$value"
    fi
    echo -n "</$type></value>"
    echo -n "</member>"
}

build_create_record_call() {
    local domain=$1
    local name=$2
    local type=$3
    local content=$4
    local ttl=3600

    build_method_call 'nameserver.createRecord' \
        "$(build_param 'domain' $domain)" \
        "$(build_param 'name' $name)" \
        "$(build_param 'type' $type)" \
        "$(build_param 'content' $content)" \
        "$(build_param 'ttl' $ttl 'int')"
}

build_list_call() {
    build_method_call 'nameserver.list'
}

build_delete_record_call() {
    local id=$1
    build_method_call 'nameserver.deleteRecord' \
        "$(build_param 'id' $id)"
}

method_call() {
    local call=$1

    # Uncomment this for debugging to log each request.
    #echo "$1" >> $TMPDIR/request.log

    local result=$(curl -s -c "$TMPDIR/cookies" -d "$call" -H 'Content-Type: text/xml' "$API_URL")
    local xpath='//methodResponse//params//member/name[text()="code"]/../value/int/text()'
    local code=$(echo "$result" | xmllint --xpath "$xpath" -)
    if [ $code = 1000 ]; then
        echo "$result"
        return 0
    else
        echo "$result" >&2
        return 1
    fi
}

deploy_challenge() {
    local domain
    local subdomain
    if [[ -z "${1/*.*.*/}" ]]; then
        domain=${1#*.}
        subdomain=${1%%.*}
        while [[ -z "${domain/*.*.*/}" ]]; do
            local olddomain=${domain}
            local oldsubdomain=${subdomain}
            domain=${olddomain#*.}
            subdomain=${oldsubdomain}.${olddomain%%.*}
        done
    else
        domain=$1
        subdomain=''
    fi
    local token=$2

    local result=$(method_call \
        "$(build_create_record_call "$domain" "_acme-challenge.$subdomain" 'TXT' "$token")")
    local code=$?
    local xpath='//methodResponse//params//member/name[text()="id"]/../value/int/text()'
    echo "$result" | xmllint --xpath "$xpath" -

    # Wait some time to make sure the new record is present in the DNS.
    sleep 60

    return $code
}

clean_challenge() {
    local record_id=$1
    method_call \
        "$(build_delete_record_call "$record_id")" > /dev/null
}

mkdir -p "$TMPDIR"

case $1 in
'deploy_challenge')
    deploy_challenge "$2" "$4" > "$TMPDIR/$2.id"
    ;;
'clean_challenge')
    clean_challenge "$(cat "$TMPDIR/$2.id")" || exit 1
    rm "$TMPDIR/$2.id"
    ;;
esac
