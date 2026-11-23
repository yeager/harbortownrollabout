#!/bin/sh
# Run from any directory with GNU gettext installed.
set -eu
cd "$(dirname "$0")/../l10n"

# English is the source language and has no PO file.
for locale in en *.po; do
    logo="../branding/rollabout-${locale%.po}.png"
    if [ ! -s "$logo" ]; then
        echo "Missing game logo: $logo" >&2
        exit 1
    fi
done

for catalog in *.po; do
    printf '%s\n' "$catalog"
    msgcmp --no-fuzzy-matching "$catalog" messages.pot
    # gettext accepts positional arguments such as %2$s, but GDScript's % operator does not.
    if grep -nE '^(msgstr(\[[0-9]+\])? |").*%[1-9][0-9]*\$' "$catalog"; then
        echo "$catalog: use placeholders in GDScript argument order" >&2
        exit 1
    fi
    msgfmt --check-format --statistics --output-file=/dev/null "$catalog"
done

python3 - <<'PY'
import configparser
import gettext
import io
from pathlib import Path
import subprocess

desktop = configparser.ConfigParser(interpolation=None)
desktop.optionxform = str
with Path("../packaging/linux/harbortown.desktop").open(encoding="utf-8") as stream:
    desktop.read_file(stream)
entry = desktop["Desktop Entry"]
source_title = "Harbor Town Rollabout"
if entry.get("Name") != "harbortown" or entry.get("GenericName") != source_title or not entry.get("Comment", "").strip():
    raise SystemExit("Check the English desktop name and description")
for catalog in sorted(Path(".").glob("*.po")):
    compiled = subprocess.check_output(["msgfmt", "-o", "-", str(catalog)])
    title = gettext.GNUTranslations(io.BytesIO(compiled)).gettext(source_title)
    if entry.get(f"GenericName[{catalog.stem}]") != title:
        raise SystemExit(f"{catalog}: desktop name must match {title!r}")
    if not entry.get(f"Comment[{catalog.stem}]", "").strip():
        raise SystemExit(f"{catalog}: missing localized desktop description")
PY
