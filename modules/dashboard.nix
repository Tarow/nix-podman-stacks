lib:
with lib; let
  # Homepage has no `di-` prefix, a bare name is a dashboard-icons name there
  prefixes = {
    "di" = {
      homepage = "";
      glance = "di:";
    };
    "si" = {
      homepage = "si-";
      glance = "si:";
    };
    "sh" = {
      homepage = "sh-";
      glance = "sh:";
    };
    "mdi" = {
      homepage = "mdi-";
      glance = "mdi:";
    };
  };

  # URLs and absolute paths are passed through as they are
  isUrl = icon: builtins.match "^(https?://.*|/.*)$" icon != null;

  # Both syntaxes are accepted, an unknown prefix is part of the name
  parse = icon:
    if icon == null
    then null
    else if builtins.match "^auto-invert (.*)$" icon != null
    then (parse (head (builtins.match "^auto-invert (.*)$" icon))) // {autoInvert = true;}
    else if isUrl icon
    then {url = icon;}
    else let
      parsed = builtins.match "^([a-z0-9]+)[:-](.+)$" icon;
    in
      if parsed != null && hasAttr (head parsed) prefixes
      then {
        prefix = head parsed;
        name = elemAt parsed 1;
        autoInvert = false;
      }
      else {
        prefix = "di";
        name = icon;
        autoInvert = false;
      };

  toHomepage = icon: let
    parsed = parse icon;
  in
    if parsed == null
    then null
    else if parsed ? url
    then parsed.url
    else prefixes.${parsed.prefix}.homepage + parsed.name;

  toGlance = icon: let
    parsed = parse icon;
  in
    if parsed == null
    then null
    else if parsed ? url
    then parsed.url
    else lib.optionalString parsed.autoInvert "auto-invert " + prefixes.${parsed.prefix}.glance + parsed.name;
in {
  inherit toHomepage toGlance;
}
