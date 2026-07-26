import re
import os

with open('/tmp/head.html', 'r') as f: head_html = f.read().strip()
with open('/tmp/styles.css', 'r') as f: styles = f.read()
with open('/tmp/script.js', 'r') as f: script = f.read()
with open('/tmp/body.html', 'r') as f: body = f.read()

# Separate styles
login_css_match = re.search(r'/\* --- LOGIN SCREEN \(GLASSMORPHISM\) ---\s*\*/(.*?)/\* --- DASHBOARD HEADER ---\s*\*/', styles, re.DOTALL)
login_css = login_css_match.group(1) if login_css_match else ""

dashboard_css_match = re.search(r'/\* --- DASHBOARD HEADER ---\s*\*/(.*)', styles, re.DOTALL)
dashboard_css = dashboard_css_match.group(1) if dashboard_css_match else ""

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

login_html = re.search(r'(<div id="space-background">.*?</div>\s*<!-- PANTALLA DE LOGIN -->\s*<div id="login-screen">.*?</div>)', body, re.DOTALL).group(1)
dashboard_html = re.search(r'(<div id="header".*)', body, re.DOTALL).group(1)

login_html = login_html.replace('style="display:none;"', '') 

with open('src/layouts/Layout.astro', 'w') as f:
    f.write(f"""---
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
""")

login_js = f"""
  let authenticated = false;
  let turnstileToken = "direct_auth_token";
  window.onTurnstileSuccess = function(token) {{ turnstileToken = token; }};
  
  window.addEventListener('DOMContentLoaded', async () => {{
    const loader = document.getElementById('session-loader');
    if (loader) loader.style.display = 'flex';
    try {{
      const res = await fetch('/soporte/agentes', {{ credentials: 'include' }});
      if (res.ok) {{
        window.location.href = '/dashboard';
        return;
      }}
    }} catch (e) {{}}
    if (loader) loader.style.display = 'none';
    
    const savedUser = localStorage.getItem('remembered_user');
    const savedPass = localStorage.getItem('remembered_pass');
    if (savedUser && savedPass) {{
      const uEl = document.getElementById('login-user');
      const pEl = document.getElementById('login-pass');
      const rEl = document.getElementById('login-remember');
      if (uEl) uEl.value = savedUser;
      if (pEl) pEl.value = savedPass;
      if (rEl) rEl.checked = true;
    }}
  }});

  function togglePasswordVisibility() {{
    const pInput = document.getElementById('login-pass');
    const icon = document.getElementById('eye-icon');
    if (!pInput || !icon) return;
    if (pInput.type === 'password') {{
      pInput.type = 'text';
      icon.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line>';
    }} else {{
      pInput.type = 'password';
      icon.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle>';
    }}
  }}

  function attemptLogin() {{
    const u = document.getElementById('login-user').value;
    const p = document.getElementById('login-pass').value;
    const errEl = document.getElementById('login-error');
    if (errEl) errEl.textContent = '';
    const btnSubmit = document.getElementById('btn-login-submit');
    if (btnSubmit) {{
      btnSubmit.disabled = true;
      btnSubmit.innerHTML = '<span style="display:inline-flex; align-items:center; gap:8px;"><svg class="animate-spin" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10" stroke-dasharray="32" stroke-dashoffset="12"></circle></svg> Autenticando...</span>';
    }}
    
    fetch('/soporte/login', {{
      method: 'POST',
      headers: {{ 'Content-Type': 'application/json' }},
      body: JSON.stringify({{ user: u, pass: p, turnstileToken }})
    }})
    .then(r => r.json())
    .then(data => {{
      if (btnSubmit) {{
        btnSubmit.disabled = false;
        btnSubmit.innerHTML = 'Autenticar Credenciales';
      }}
      if (data.success) {{
        const rememberEl = document.getElementById('login-remember');
        if (rememberEl && rememberEl.checked) {{
          localStorage.setItem('remembered_user', u);
          localStorage.setItem('remembered_pass', p);
        }} else {{
          localStorage.removeItem('remembered_user');
          localStorage.removeItem('remembered_pass');
        }}
        window.location.href = '/dashboard';
      }} else {{
        if (errEl) errEl.innerHTML = '<div class="alert-glass-error"><span>⚠️</span><span>' + (data.error || 'Credenciales incorrectas') + '</span></div>';
      }}
    }})
    .catch(() => {{
      if (btnSubmit) {{
        btnSubmit.disabled = false;
        btnSubmit.innerHTML = 'Autenticar Credenciales';
      }}
      if (errEl) errEl.innerHTML = '<div class="alert-glass-error"><span>⚠️</span><span>Error de conexión con el servidor.</span></div>';
    }});
  }}
"""

starfield_script = re.search(r'function initStarfield\(\) \{.*\}\n\s*initStarfield\(\);', script, re.DOTALL)
if starfield_script:
    login_js += "\n" + starfield_script.group(0)

with open('src/pages/index.astro', 'w') as f:
    f.write(f"""---
import Layout from '../layouts/Layout.astro';
---

<Layout title="Login | IC-Desk">
  <div id="session-loader" style="display:none; position:fixed; inset:0; background:radial-gradient(circle at center, #111827 0%, #030712 100%); display:flex; align-items:center; justify-content:center; z-index:2000; flex-direction:column; gap:16px;">
    <div class="sl-spinner" style="width:40px; height:40px; border:3px solid rgba(99,179,237,0.2); border-top-color:#63b3ed; border-radius:50%; animation:spin 0.8s linear infinite;"></div>
    <p style="color:rgba(255,255,255,0.4); font-size:13px;">Verificando sesión...</p>
  </div>
  {login_html}
  <style>
  {login_css}
  </style>
  <script is:inline>
  {login_js}
  </script>
</Layout>
""")


dashboard_js_clean = f"""
  let monitoringInterval = null;
  let activeWs = null;
  let currentAgentId = null;
  const WS_RELAY_URL = window.location.protocol === 'https:' ? `wss://${{window.location.host}}` : `ws://${{window.location.hostname}}:6001`;

  let canvas = null;
  let ctx = null;

  window.addEventListener('DOMContentLoaded', async () => {{
    canvas = document.getElementById('screen-canvas');
    if (canvas) ctx = canvas.getContext('2d');
    
    try {{
      const res = await fetch('/soporte/agentes', {{ credentials: 'include' }});
      if (!res.ok) {{
        window.location.href = '/';
        return;
      }}
      startMonitoring();
    }} catch (e) {{
      window.location.href = '/';
    }}
  }});

"""

# Everything from openSession down, except initStarfield
dashboard_funcs_match = re.search(r'(function openSession.*)', script, re.DOTALL)
if dashboard_funcs_match:
    df = dashboard_funcs_match.group(1)
    df = re.sub(r'function initStarfield\(\) \{.*\}\n\s*initStarfield\(\);', '', df, flags=re.DOTALL)
    dashboard_js_clean += df

dashboard_js_clean = re.sub(r"document\.getElementById\('header'\)\.style\.display\s*=\s*'flex';", "", dashboard_js_clean)
dashboard_js_clean = re.sub(r"document\.getElementById\('main-content'\)\.style\.display\s*=\s*'flex';", "", dashboard_js_clean)
dashboard_js_clean = dashboard_js_clean.replace('window.location.reload();', "window.location.href = '/';")

dashboard_css_clean = dashboard_css
dashboard_html_clean = dashboard_html.replace('style="display: none;"', '')

with open('src/pages/dashboard.astro', 'w') as f:
    f.write(f"""---
import Layout from '../layouts/Layout.astro';
---

<Layout title="Dashboard | IC-Desk">
  {dashboard_html_clean}
  <style>
  {dashboard_css_clean}
  #header {{ display: flex !important; }}
  #main-content {{ display: flex !important; }}
  </style>
  <script is:inline>
  {dashboard_js_clean}
  </script>
</Layout>
""")

