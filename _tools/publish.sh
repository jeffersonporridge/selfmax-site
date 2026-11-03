#!/bin/zsh
# Rebuilds sitemap.xml from the pages' real last-edit dates (their last git
# commit), then tells search engines which pages changed via IndexNow.
#
#   _tools/publish.sh            rebuild the sitemap only
#   _tools/publish.sh --ping     rebuild, then ping IndexNow for every page
#
# Run it after committing page edits; commit and push the new sitemap, then
# ping. Add a page to PAGES when it should be in search (about.html stays
# out until its founder section is real).
set -euo pipefail
cd "$(dirname "$0")/.."

SITE="https://selfmaxapp.com"
KEY="33af76b6b87cb1dadf0478be9346f648"
# file:public path
PAGES=(
  "index.html:/"
  "pricing.html:/pricing.html"
  "privacy.html:/privacy.html"
)

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  for entry in $PAGES; do
    file=${entry%%:*}; path=${entry#*:}
    lastmod=$(git log -1 --format=%cs -- "$file")
    echo "  <url><loc>$SITE$path</loc><lastmod>$lastmod</lastmod></url>"
  done
  echo '</urlset>'
} > sitemap.xml
echo "sitemap.xml rebuilt"

if [[ "${1:-}" == "--ping" ]]; then
  urls=""
  for entry in $PAGES; do urls+="\"$SITE${entry#*:}\","; done
  curl -sS -o /dev/null -w "IndexNow: %{http_code}\n" -X POST https://api.indexnow.org/indexnow \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "{\"host\":\"selfmaxapp.com\",\"key\":\"$KEY\",\"keyLocation\":\"$SITE/$KEY.txt\",\"urlList\":[${urls%,}]}"
fi
