#!/bin/sh
# Renew the Zellij web certificate for sleipnir.z42.work.
# Token lives in ~/.config/lego/env (chmod 600, never committed).
. "$HOME/.config/lego/env"
export CF_DNS_API_TOKEN
exec "$HOME/go/bin/lego" --accept-tos --email plkvnk@gmail.com --dns cloudflare \
  --domains sleipnir.z42.work --path "$HOME/.certs" \
  renew --days 30 --renew-hook "launchctl kickstart -k gui/501/dev.zellij.web"
