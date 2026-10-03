#!/bin/sh
# Rebuilds sources.json from the release manifests. A unique query string
# makes the CDN fetch them anew, so a run right after a release sees it.
set -eu

cd "$(dirname "$0")"

manifests=https://cdn.web-artisan.pro/manifest
fresh=$(date +%s)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo '{}' > "$work/sources.json"
for channel in stable beta; do
  status=$(curl -sS -o "$work/manifest.json" -w '%{http_code}' "$manifests/$channel.json?$fresh")
  case $status in
    200) ;;
    # Spaces answers 403 for a missing file, as for an access error. A channel
    # is never removed, so a miss for one that sources.json has is an error.
    403 | 404)
      if jq -e --arg channel "$channel" 'has($channel)' sources.json > /dev/null; then
        echo "update: $channel.json: HTTP $status" >&2
        exit 1
      fi
      continue
      ;;
    *)
      echo "update: $channel.json: HTTP $status" >&2
      exit 1
      ;;
  esac

  version=$(jq -r .version "$work/manifest.json")
  jq -r '.files[] | select(.os == "linux") | "\(.arch) \(.url) \(.sha256)"' \
    "$work/manifest.json" > "$work/files"
  while read -r arch url sha256; do
    case $arch in
      x64) system=x86_64-linux ;;
      arm64) system=aarch64-linux ;;
      *)
        echo "update: $channel.json: unknown arch $arch" >&2
        exit 1
        ;;
    esac
    hash=$(nix hash convert --hash-algo sha256 --to sri "$sha256")
    jq --arg channel "$channel" --arg version "$version" --arg system "$system" \
      --arg url "$url" --arg hash "$hash" \
      '.[$channel].version = $version | .[$channel][$system] = {$url, $hash}' \
      "$work/sources.json" > "$work/next.json"
    mv "$work/next.json" "$work/sources.json"
  done < "$work/files"
done
mv "$work/sources.json" sources.json
