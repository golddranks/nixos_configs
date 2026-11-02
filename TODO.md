# TODO

## Decide on home-manager (for this Mac)

`kon_home-manager/` is used on another system, not this Mac. Open question
is whether to also adopt it here so SSH config, shell rc, and per-user
packages become reproducible. If yes, wire it into the darwin flake; if
no, leave Mac-side user config out-of-band.
