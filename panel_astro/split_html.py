import re

with open('/tmp/body.html', 'r') as f: body = f.read()

# We can split by headers
parts = body.split('<!-- HEADER DEL DASHBOARD -->')
login_part = parts[0]
dash_part = parts[1] if len(parts) > 1 else ''

if dash_part:
    dash_part = '<!-- HEADER DEL DASHBOARD -->' + dash_part

# We can remove the style="display:none;" from login and dash
login_part = login_part.replace('style="display:none;"', '')
dash_part = dash_part.replace('style="display: none;"', '')
# also remove it specifically from header and main-content
dash_part = re.sub(r'id="header"\s+style="display:\s*none;"', 'id="header"', dash_part)
dash_part = re.sub(r'id="main-content"\s+style="display:\s*none;"', 'id="main-content"', dash_part)

with open('src/pages/index.astro', 'r') as f: index_astro = f.read()
# Replace everything inside <Layout>...</Layout> (before <style>)
index_top = index_astro.split('<style>')[0]
index_bottom = '<style>' + index_astro.split('<style>')[1]
index_top = index_top.split('<Layout title="Login | IC-Desk">')[0] + '<Layout title="Login | IC-Desk">\n' + login_part

with open('src/pages/index.astro', 'w') as f:
    f.write(index_top + index_bottom)

with open('src/pages/dashboard.astro', 'r') as f: dash_astro = f.read()
dash_top = dash_astro.split('<style>')[0]
dash_bottom = '<style>' + dash_astro.split('<style>')[1]
dash_top = dash_top.split('<Layout title="Dashboard | IC-Desk">')[0] + '<Layout title="Dashboard | IC-Desk">\n' + dash_part

with open('src/pages/dashboard.astro', 'w') as f:
    f.write(dash_top + dash_bottom)

