#!/usr/bin/env python3
"""Render Etsy listing images (2000x2000) from product sheet screenshots.
Usage: _mockup.py <product-dir> <headline> <subhead> <out-name> <sheet1.png> [sheet2.png ...]
"""
import sys, os, subprocess, json, html

def build(outdir, name, headline, sub, badges, shots, layout):
    imgs = ''.join(f'<div class="p p{i+1}"><img src="file://{os.path.abspath(s)}"></div>' for i,s in enumerate(shots))
    bd = ''.join(f'<span>{html.escape(b)}</span>' for b in badges)
    css_layout = layout
    doc = f'''<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800;900&display=swap" rel="stylesheet">
<style>
*{{box-sizing:border-box;margin:0}}
body{{width:2000px;height:2000px;background:linear-gradient(150deg,#eef1f6 0%,#e3e8f0 55%,#dde3ec 100%);font-family:Inter,sans-serif;position:relative;overflow:hidden}}
.wrap{{position:absolute;inset:0;padding:96px 104px;display:flex;flex-direction:column}}
h1{{font-size:112px;line-height:.97;font-weight:900;letter-spacing:-3.5px;color:#14213d;max-width:1500px}}
h1 em{{font-style:normal;color:#1f3a5f;display:block}}
.sub{{font-size:42px;color:#4b5468;margin-top:26px;font-weight:600;max-width:1400px;line-height:1.3}}
.badges{{display:flex;gap:16px;margin-top:34px;flex-wrap:wrap}}
.badges span{{background:#14213d;color:#fff;font-size:27px;font-weight:700;padding:15px 28px;border-radius:999px;letter-spacing:.2px}}
.stage{{position:absolute;left:0;right:0;top:620px;bottom:0}}
.p{{position:absolute;box-shadow:0 40px 90px rgba(20,33,61,.30);background:#fff;overflow:hidden;border-radius:6px}}
.p img{{width:100%;display:block}}
{css_layout}
.tag{{position:absolute;right:104px;top:96px;background:#b8860b;color:#fff;font-size:34px;font-weight:800;padding:20px 34px;border-radius:10px;transform:rotate(3deg);box-shadow:0 14px 34px rgba(184,134,11,.4)}}
</style></head><body>
<div class="wrap"><h1>{headline}</h1><p class="sub">{html.escape(sub)}</p><div class="badges">{bd}</div></div>
<div class="tag">INSTANT DOWNLOAD</div>
<div class="stage">{imgs}</div>
</body></html>'''
    src = os.path.join(outdir, f'_{name}.html')
    open(src,'w').write(doc)
    CH='/opt/pw-browsers/chromium-1194/chrome-linux/chrome'
    out = os.path.join(outdir, name)
    subprocess.run([CH,'--headless','--disable-gpu','--no-sandbox','--hide-scrollbars',
                    f'--screenshot={out}','--window-size=2000,2000',f'file://{os.path.abspath(src)}'],
                   capture_output=True, timeout=120)
    os.remove(src)
    return out, os.path.getsize(out) if os.path.exists(out) else 0
