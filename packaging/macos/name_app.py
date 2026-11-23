"""Apply the public app name to a Godot macOS export before code signing."""
import plistlib
import re
import sys
from pathlib import Path

image_dir = Path(sys.argv[1])
app, = image_dir.glob("*.app")
contents = app / "Contents"
plist = contents / "Info.plist"
info = plistlib.loads(plist.read_bytes())
old_name = info["CFBundleExecutable"]
name = "harbortown"
for directory, suffix in [("MacOS", ""), ("Resources", ".pck")]:
    source = contents / directory / (old_name + suffix)
    source.rename(source.with_name(name + suffix))
for key in ("CFBundleExecutable", "CFBundleName", "CFBundleDisplayName"):
    info[key] = name
plist.write_bytes(plistlib.dumps(info))
for path in contents.glob("Resources/*.lproj/InfoPlist.strings"):
    strings = path.read_text(encoding="utf-8")
    strings = re.sub(r'^CFBundleDisplayName = ".*";', 'CFBundleDisplayName = "harbortown";',
                     strings, flags=re.MULTILINE)
    path.write_text(strings, encoding="utf-8")
app.rename(image_dir / (name + ".app"))
