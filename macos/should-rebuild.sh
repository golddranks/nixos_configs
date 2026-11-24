# Run daily by the should_rebuild agent (configuration.nix), with jq on PATH.
# Usage: should-rebuild.sh <running NixOS release, e.g. 26.05>
release=$1

ran=$(jq -r .nixpkgsRevision /run/current-system/darwin-version.json)
/usr/bin/curl -sf "https://api.github.com/repos/NixOS/nixpkgs/activity?ref=nixpkgs-$release-darwin&per_page=100" |
  jq -e --arg ran "$ran" '
    (now - 7 * 86400 | todate) as $cutoff
    | (map(select(.after == $ran))[0].timestamp // "") as $ran_at
    | any(.[]; .timestamp > $ran_at and .timestamp <= $cutoff)' >/dev/null &&
  /usr/bin/osascript -e 'display notification "Running nixpkgs predates a channel release over a week old" with title "Run upgrade.sh"'

# A heads-up as soon as a newer release is out, and a warning once this
# one is past end of life: its channel then stops moving, so the check
# above passes forever.
msg=$(/usr/bin/curl -sf https://endoflife.date/api/v1/products/nixos |
  jq -r --arg ran "$release" '
    (now | todate[:10]) as $today
    | .result.releases
    | (map(select(.name == $ran))[0] // empty) as $cur
    | (map(select(.name > $ran and .releaseDate <= $today))[0].name) as $new
    | if $cur.isEol then "NixOS \($ran) is past its end of life"
      elif $new then "NixOS \($new) is out; \($ran) reaches end of life on \($cur.eolFrom)"
      else empty end')
[ -n "$msg" ] && /usr/bin/osascript -e 'on run argv' \
  -e 'display notification (item 1 of argv) with title "Move macos/flake.nix to the next release"' \
  -e 'end run' "$msg"

ver=$(/nix/var/nix/profiles/default/bin/nix --version)
/usr/bin/curl -sf 'https://api.github.com/repos/DeterminateSystems/nix-src/releases?per_page=100' |
  jq -e --arg ver "$ver" '
    (now - 7 * 86400 | todate) as $cutoff
    | ($ver | "v" + capture("Determinate Nix (?<v>[0-9.]+)").v) as $tag
    | (map(select(.tag_name == $tag))[0].published_at // "") as $ver_at
    | any(.[]; .prerelease == false and .published_at > $ver_at and .published_at <= $cutoff)' >/dev/null &&
  /usr/bin/osascript -e 'display notification "Determinate Nix predates a release over a week old" with title "Run sudo determinate-nixd upgrade"'
