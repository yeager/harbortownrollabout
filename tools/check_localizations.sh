#!/bin/sh
# Run from any directory with GNU gettext installed.
set -eu
cd "$(dirname "$0")/../l10n"

for catalog in *.po; do
    printf '%s\n' "$catalog"
    msgcmp --no-fuzzy-matching "$catalog" messages.pot
    msgfmt --check-format --statistics --output-file=/dev/null "$catalog"
done
