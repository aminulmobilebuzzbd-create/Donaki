"""uiautomator dump থেকে লেবেল খুঁজে তার মাঝখানের x y প্রিন্ট করে।"""
import re
import sys
import xml.etree.ElementTree as ET

path, label = sys.argv[1], sys.argv[2]
pick_last = len(sys.argv) > 3 and sys.argv[3] == "last"
found = None
for node in ET.parse(path).iter("node"):
    text = (node.get("content-desc") or "") + " " + (node.get("text") or "")
    if label in text:
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
        found = ((x1 + x2) // 2, (y1 + y2) // 2)
        if not pick_last:
            break
if found is None:
    sys.exit(f"label not found: {label}")
print(*found)
