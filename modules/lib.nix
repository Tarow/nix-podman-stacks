# General purpose helpers that are not tied to a single stack.
# Usage: (import ../lib.nix lib).<function>
lib:
with lib; rec {
  # Merges a list of attribute sets into a single one:
  # - attribute sets are merged recursively
  # - lists are concatenated and deduplicated
  # - for anything else the last value wins
  recursiveMerge = attrList: let
    f = zipAttrsWith (
      _: values:
        if tail values == []
        then head values
        else if all isList values
        then unique (concatLists values)
        else if all isAttrs values
        then f values
        else last values
    );
  in
    f attrList;
}
