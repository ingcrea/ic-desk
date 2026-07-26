import re
import os

os.makedirs('src/layouts', exist_ok=True)
os.makedirs('src/pages', exist_ok=True)

with open('/tmp/head.html', 'r') as f: head_html = f.read().strip()
with open('/tmp/styles.css', 'r') as f: styles = f.read()
with open('/tmp/script.js', 'r') as f: script = f.read()
with open('/tmp/body.html', 'r') as f: body = f.read()

# SPLIT CSS
# Common CSS:
common_css = """
:root {
  --bg: #060913;
  --surface: rgba(17, 24, 39, 0.7);
  --surface-card: rgba(31, 41, 55, 0.4);
  --border: rgba(255, 255, 255, 0.08);
  --border-active: rgba(0, 102, 204, 0.6);
  --accent: #0066cc;
  --accent-glow: rgba(0, 102, 204, 0.35);
  --success: #10b981;
  --danger: #ef4444;
  --warning: #f59e0b;
  --text: #f9fafb;
  --text-muted: #9ca3af;
  --radius: 16px;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: 'Outfit', sans-serif;
  background: radial-gradient(circle at 50% 0%, #111a2e 0%, var(--bg) 70%);
  color: var(--text);
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
"""

login_css_match = re.search(r'/\* --- LOGIN SCREEN \(GLASSMORPHISM\) ---\s*\*/(.*?)/\* --- DASHBOARD HEADER ---\s*\*/', styles, re.DOTALL)
login_css = login_css_match.group(1) if login_css_match else ""

dashboard_css_match = re.search(r'/\* --- DASHBOARD HEADER ---\s*\*/(.*)', styles, re.DOTALL)
dashboard_css = dashboard_css_match.group(1) if dashboard_css_match else ""

# SPLIT JS
# Common JS could be anything, but we'll try to split.
# Let's extract login logic vs dashboard logic.
# The user wants exact code, no React, Vanilla JS.

# Let's create Layout.astro
layout_code = f"""---
const {{ title = "IC-Desk — Soporte Remoto Enterprise" }} = Astro.props;
---
<!DOCTYPE html>
<html lang="es">
<head>
  {head_html}
  <title>{{title}}</title>
  <slot name="head" />
</head>
<body>
  <slot />
  <style is:global>
    {common_css}
  </style>
</body>
</html>
"""

with open('src/layouts/Layout.astro', 'w') as f: f.write(layout_code)

# We will just put the entire script in dashboard, except the login part.
# But it's easier to put the entire script in both and remove unused, or just split them safely.
# Wait, let's keep all styles and JS in their respective pages. 
# It's better to just manually split the JS to avoid breaking WS and throttling.
