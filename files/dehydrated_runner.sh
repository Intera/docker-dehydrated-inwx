#!/usr/bin/env bash

verbose="$DEHYDRATED_DEBUG"
hook="dehydrated_hook.sh"

if [ -z "$DOMAINS" ]; then
  echo "No domains specified! Set DOMAINS env var!"
  exit 1
fi

echo "$DOMAINS" > /opt/dehydrated/domains.txt

if [ -n "$INWX_USER" ]; then
  hook="inwx_hook_runner.sh"
  if [ "$verbose" == "yes" ]; then
    echo "Using inwx hook"
  fi
fi

output=$(cd /opt/dehydrated; ./dehydrated.sh -c --accept-terms --hook "./${hook}")
status=$?

if [ "${status}" -ne "0" ]; then
    echo "${output}"
fi

if [ "$verbose" == "yes" ]; then
  if [ -f /tmp/dehydrated_cert_generated ]; then
      echo "Certificate generated"
  else
      echo "No certificate generation required"
  fi
fi

exit ${status}
