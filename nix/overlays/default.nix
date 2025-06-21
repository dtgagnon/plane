# Plane overlays
# This default.nix aggregates all overlay functions in this directory so they
# can be imported conveniently from the flake.

[
  (import ./slack-sdk.nix)
]
