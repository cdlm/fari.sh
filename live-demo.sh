#!/bin/bash -i
#
# Run a small doitlive demo in a temp directory

set -euo pipefail
IFS=$'\n\t'

command -v hub doitlive >/dev/null || exit 1

fari_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
tmp=$(mktemp -d)
[[ -d "$tmp" ]] || exit 1

trap "rm -fr ${tmp}" EXIT

cd "$tmp"
doitlive play --quiet - <<LIVE

#doitlive prompt: {r_angle.bold.white}
#doitlive alias: git=hub
#doitlive alias: fari=$fari_dir/fari

git clone cdlm/clap-st
cd clap-st
fari run -- clap hello

LIVE
