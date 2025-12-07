{
  lib,
  config,
  ...
}: {
  # With HM version 25.11 the construction of the Quadlet file changed.
  # Quotation marks that appear in the Quadlet don't have to be extra escaped anymore
  # https://github.com/nix-community/home-manager/commit/d800d198b8376ffb6d8f34f12242600308b785ee
  escapeOnDemand = str:
    if lib.versionAtLeast config.home.version.release "25.11"
    then str
    else lib.replaceStrings [''"'' ''`''] [''\"'' ''\`''] str;

  reverseProxy.getPort = port: index:
    if port == null
    then null
    else if (builtins.isInt port)
    then builtins.toString port
    else builtins.elemAt (builtins.match "([0-9]+):([0-9]+)" port) index;
}
