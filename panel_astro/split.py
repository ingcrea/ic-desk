import re
import os

with open('/home/ingcrea/github/ic-desk/panel/index.html', 'r') as f:
    html = f.read()

head = re.search(r'<head>(.*?)</head>', html, re.DOTALL).group(1)
head = re.sub(r'<style>.*?</style>', '', head, flags=re.DOTALL)
styles = re.search(r'<style>(.*?)</style>', html, re.DOTALL).group(1)

# Extract scripts (there might be multiple, get the main one which has no src)
scripts = re.findall(r'<script\b[^>]*>(.*?)</script>', html, re.DOTALL)
script = next(s for s in scripts if s.strip()) # get first non-empty script body

body = re.search(r'<body.*?>(.*?)</body>', html, re.DOTALL).group(1)
body = re.sub(r'<script.*?</script>', '', body, flags=re.DOTALL)

with open('/tmp/head.html', 'w') as f: f.write(head)
with open('/tmp/styles.css', 'w') as f: f.write(styles)
with open('/tmp/script.js', 'w') as f: f.write(script)
with open('/tmp/body.html', 'w') as f: f.write(body)

