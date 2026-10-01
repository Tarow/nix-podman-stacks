# Reusable Docker API section regexes for the socket-proxy
#
# https://github.com/wollomatic/socket-proxy/wiki/Docker-API-regex-pattern-index
#
# Patterns must use POSIX character classes (`[[:digit:]]`, not `\d`) and
# `[[:graph:]]` (not `\S`), because systemd mangles backslashes before they
# reach the proxy, which silently empties the allowlist.
let
  # The API version prefix is optional: Docker clients may omit it, which is
  # deprecated and will be removed, but still happens in practice.
  apiVersion = "(/v[[:digit:].]+)?";

  # Optional object id or name, endpoint and query string, e.g. `/abc/json?all=1`
  tail = "((/|[?])[[:graph:]]+)?";

  # A whole section, e.g. `(..)?/containers((/|[?])[[:graph:]]+)?`
  section = name: "${apiVersion}/${name}${tail}";

  # A single endpoint, e.g. `(..)?/info`
  endpoint = name: "${apiVersion}/${name}";
in {
  # Required by every Docker client
  version = endpoint "version";
  ping = endpoint "_ping";

  events = section "events";

  containers = section "containers";
  images = section "images";
  build = section "build";
  commit = section "commit";
  networks = section "networks";
  volumes = section "volumes";
  exec = section "exec";
  plugins = section "plugins";
  info = endpoint "info";
  system = section "system";
  distribution = section "distribution";

  # Swarm only, listed for completeness, Podman has no Swarm API
  swarm = section "swarm";
  nodes = section "nodes";
  services = section "services";
  tasks = section "tasks";
  configs = section "configs";

  # Security critical
  auth = endpoint "auth";
  secrets = section "secrets";

  # Deprecated by the Docker API, kept for completeness
  session = endpoint "session";
}
