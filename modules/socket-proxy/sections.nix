# Reusable Docker API section regexes, from the upstream pattern index:
# https://github.com/wollomatic/socket-proxy/wiki/Docker-API-regex-pattern-index
let
  # Optional API version prefix, e.g. `/v1.55`
  apiVersion = "(/v[[:digit:].]+)?";

  # Optional object id, endpoint and query string, e.g. `/abc/json?all=1`
  tail = "((/|[?])[[:graph:]]+)?";

  section = name: "${apiVersion}/${name}${tail}";
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

  # Swarm only, Podman has no Swarm API
  swarm = section "swarm";
  nodes = section "nodes";
  services = section "services";
  tasks = section "tasks";
  configs = section "configs";

  # Security critical
  auth = endpoint "auth";
  secrets = section "secrets";

  # Deprecated by the Docker API
  session = endpoint "session";
}
