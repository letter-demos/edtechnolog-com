#!/bin/sh
# Sets each <lastmod> in sitemap.xml to the date its page file last changed:
# the date of the file's last commit, or today if the file has uncommitted
# changes (so it is right when run from the pre-commit hook).
set -e
cd "$(git rev-parse --show-toplevel)"

site="https://edtechnolog.com/"
tmp="$(mktemp)"
today="$(date -u +%F)"

while IFS= read -r line; do
  loc="$(printf '%s\n' "$line" | sed -n 's|.*<loc>\([^<]*\)</loc>.*|\1|p')"
  if [ -n "$loc" ]; then
    file="${loc#"$site"}"
    [ -z "$file" ] && file="index.html"
    case "$file" in */) file="${file}index.html" ;; esac
    if [ -n "$(git status --porcelain -- "$file")" ]; then
      date="$today"
    else
      date="$(git log -1 --format=%cs -- "$file")"
    fi
    [ -z "$date" ] && date="$today"
    line="$(printf '%s\n' "$line" | sed -e 's|<lastmod>[^<]*</lastmod>||' -e "s|</loc>|</loc><lastmod>$date</lastmod>|")"
  fi
  printf '%s\n' "$line" >> "$tmp"
done < sitemap.xml

cat "$tmp" > sitemap.xml
rm -f "$tmp"
