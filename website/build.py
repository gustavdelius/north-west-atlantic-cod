#!/usr/bin/env python3
"""Build the policy explorer page from one source (standard library only).

    python3 website/build.py            # from the repository root (or anywhere)

Reads   website/src/page.src.html  (the page: head part, <!--BODY--> marker, body part)
        website/data/site_data.json (written by R/08_website_data.R)
Writes  website/page.html   fragment for a claude.ai Artifact (no doctype/html/head/body)
        website/index.html  the same content as a standalone document (GitHub Pages, file://)

Text placeholders {{key}} or {{key:spec}} are replaced by facts[key] from the
JSON, formatted with Python's format spec (e.g. {{hindA_cod_ratio:.1f}},
{{forage_share_cod_deaths:.1%}}, {{ssb_peak_kt:,.0f}}). A missing key stops the
build, so every number in the text comes from the data file. The marker
/*__SITE_DATA__*/ in the inline script is replaced by the JSON itself.
"""
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
SRC = HERE / "src" / "page.src.html"
DATA = HERE / "data" / "site_data.json"


def fmt_fact(facts, key, spec):
    if key not in facts:
        sys.exit(f"build.py: no fact named '{key}' in site_data.json")
    v = facts[key]
    if v is None:
        sys.exit(f"build.py: fact '{key}' is null")
    if spec == "x":                      # multiplier, e.g. x7.9 / x0.10
        s = f"{v:.2f}" if v < 0.995 else f"{v:.1f}"
        return "×" + s
    if spec == "pct":                    # share of something, adaptive precision
        p = 100 * v
        s = f"{p:.0f}" if p >= 10 else (f"{p:.1f}" if p >= 0.1 else f"{p:.2g}")
        return s + "%"
    if spec == "int":
        return f"{round(v):,}"
    if spec:
        return format(v, spec)
    if isinstance(v, bool):
        return "yes" if v else "no"
    if isinstance(v, float) and v.is_integer():
        return str(int(v))
    return str(v)


def main():
    data = json.loads(DATA.read_text(encoding="utf-8"))
    facts = data["facts"]
    src = SRC.read_text(encoding="utf-8")
    used = set()

    def sub(m):
        used.add(m.group(1))
        return fmt_fact(facts, m.group(1), m.group(2) or "")

    src = re.sub(r"\{\{([A-Za-z0-9_]+)(?::([^}]+))?\}\}", sub, src)
    blob = json.dumps(data, separators=(",", ":"), ensure_ascii=False)
    blob = blob.replace("</", "<\\/").replace("<!--", "<\\!--")
    if "/*__SITE_DATA__*/" not in src:
        sys.exit("build.py: data marker missing from template")
    src = src.replace("/*__SITE_DATA__*/", "const SITE = " + blob + ";")
    if "<!--BODY-->" not in src:
        sys.exit("build.py: <!--BODY--> marker missing from template")
    head, body = src.split("<!--BODY-->", 1)
    head, body = head.strip(), body.strip()
    if not head.startswith("<title>"):
        sys.exit("build.py: the template must start with <title>")

    (HERE / "page.html").write_text(head + "\n" + body + "\n", encoding="utf-8")
    standalone = (
        "<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n"
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, viewport-fit=cover\">\n"
        "<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}"
        "body{margin:0}[hidden]{display:none!important}img{max-width:100%}</style>\n"
        + head + "\n</head>\n<body>\n" + body + "\n</body>\n</html>\n")
    (HERE / "index.html").write_text(standalone, encoding="utf-8")
    unused = sorted(set(facts) - used)
    print(f"page.html {len((HERE / 'page.html').read_bytes()) / 1024:.0f} KB, "
          f"index.html {len((HERE / 'index.html').read_bytes()) / 1024:.0f} KB, "
          f"{len(used)} facts used" + (f"; not used in text: {', '.join(unused)}" if unused else ""))


if __name__ == "__main__":
    main()
