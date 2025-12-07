# tsbridge Module

This module provides integration with [tsbridge](https://github.com/jtdowney/tsbridge), a Tailscale reverse proxy that discovers Docker containers via labels and automatically exposes them on your Tailnet.

## Features

- Automatic service discovery via Docker labels
- OAuth-based authentication with Tailscale
- Per-service configuration via NixOS options
- Support for custom tags, headers, and streaming
- Integrated with the nix-podman-stacks ecosystem
- **Automatic Docker socket proxy integration** - automatically uses `docker-socket-proxy` when enabled

## Prerequisites

1. A Tailscale account with OAuth credentials
2. OAuth client ID and secret from Tailscale admin console
3. (Optional) `docker-socket-proxy` stack for enhanced security

## Docker Socket Access

The tsbridge module needs access to the Docker/Podman socket to discover containers. This is handled automatically in two ways:

- **With docker-socket-proxy enabled:** tsbridge will automatically use the socket proxy and connect via `--docker-socket` flag pointing to the proxy's address. This provides read-only access and enhanced security.
- **Without docker-socket-proxy:** tsbridge will mount the Podman socket directly at `/var/run/docker.sock` in read-only mode.

You don't need to configure this manually - the module detects the socket proxy and configures itself accordingly.

## Quick Start

### 1. Enable the tsbridge Stack

```nix
{
  nps.stacks.tsbridge = {
    enable = true;
    
    # Required: Your Tailscale tailnet domain
    tailnetDomain = "my-tailnet.ts.net";
    
    oauth = {
      clientIdFile = "/run/secrets/tsbridge_oauth_client_id";
      clientSecretFile = "/run/secrets/tsbridge_oauth_client_secret";
    };
    
    defaultTags = ["tag:container" "tag:http"];
    
    # Optional: Enable metrics
    metricsAddr = ":9090";
  };
}
```

### 2. Expose Services via tsbridge

```nix
{
  services.podman.containers.myapp = {
    image = "myapp:latest";
    
    tsbridge = {
      enable = true;
      port = 8080;  # Port that tsbridge should proxy to
      
      # Optional configurations
      serviceName = "myapp-prod";
      tags = ["tag:production"];
      whoisEnabled = true;
    };
  };
}
```

## Configuration Options

### Global tsbridge Options

These options configure the tsbridge container itself and are prefixed with `nps.stacks.tsbridge`.

#### Tailscale Configuration (`tsbridge.tailscale.*` labels)

##### `nps.stacks.tsbridge.oauth.clientIdFile`
- **Type:** path or null
- **Default:** null
- **Required:** yes
- **Description:** Path to file containing the Tailscale OAuth client ID
- **Label:** `tsbridge.tailscale.oauth_client_id_env`

##### `nps.stacks.tsbridge.oauth.clientSecretFile`
- **Type:** path or null
- **Default:** null
- **Required:** yes
- **Description:** Path to file containing the Tailscale OAuth client secret
- **Label:** `tsbridge.tailscale.oauth_client_secret_env`

##### `nps.stacks.tsbridge.oauth.clientIdEnvVar`
- **Type:** string
- **Default:** "TSBRIDGE_OAUTH_CLIENT_ID"
- **Description:** Environment variable name for OAuth client ID
- **Label:** `tsbridge.tailscale.oauth_client_id_env`

##### `nps.stacks.tsbridge.oauth.clientSecretEnvVar`
- **Type:** string
- **Default:** "TSBRIDGE_OAUTH_CLIENT_SECRET"
- **Description:** Environment variable name for OAuth client secret
- **Label:** `tsbridge.tailscale.oauth_client_secret_env`

##### `nps.stacks.tsbridge.defaultTags`
- **Type:** list of strings
- **Default:** []
- **Description:** Default Tailscale tags applied to all services
- **Example:** `["tag:prod" "tag:http"]`
- **Label:** `tsbridge.tailscale.default_tags`

##### `nps.stacks.tsbridge.tailnetDomain`
- **Type:** string
- **Default:** (none)
- **Required:** yes
- **Description:** Your Tailscale tailnet domain name. Used to construct full service hosts (`tsbridge.serciceHost`) and full service URLs (`tsbridge.serviceUrl`).
- **Example:** `"my-tailnet.ts.net"`
- **Note:** ⚠️ This setting is **required** when using tsbridge wiht Tialscale. Find your tailnet domain in your Tailscale admin console.

#### Global Proxy Configuration (`tsbridge.global.*` labels)

##### `nps.stacks.tsbridge.metricsAddr`
- **Type:** string or null
- **Default:** null
- **Description:** Address to expose Prometheus metrics
- **Example:** `:9090`
- **Label:** `tsbridge.global.metrics_addr`

##### `nps.stacks.tsbridge.writeTimeout`
- **Type:** string or null
- **Default:** null
- **Description:** Global default timeout for writing responses (Go duration format)
- **Example:** `"30s"` or `"0s"` for no timeout
- **Label:** `tsbridge.global.write_timeout`

#### Network Configuration

##### `nps.stacks.tsbridge.network.name`
- **Type:** string
- **Default:** "tsbridge-proxy"
- **Description:** Podman bridge network name. Services using tsbridge must be on this network.

#### Container Configuration

##### `nps.stacks.tsbridge.enable`
- **Type:** boolean
- **Default:** false
- **Description:** Enable the tsbridge stack

##### `nps.stacks.tsbridge.extraEnv`
- **Type:** attribute set
- **Default:** {}
- **Description:** Extra environment variables for the tsbridge container

### Per-Service tsbridge Options

These options are available on any container definition via the `tsbridge` attribute and generate `tsbridge.service.*` labels.

#### Basic Service Configuration

##### `tsbridge.enable`
- **Type:** boolean
- **Default:** false
- **Description:** Enable tsbridge proxy for this service
- **Label:** `tsbridge.enabled`

##### `tsbridge.port`
- **Type:** integer or null
- **Default:** null
- **Description:** Port that tsbridge should proxy to (mutually exclusive with backendAddr)
- **Label:** `tsbridge.service.port`

##### `tsbridge.backendAddr`
- **Type:** string or null
- **Default:** null
- **Description:** Full backend address (host:port) for proxy (mutually exclusive with port)
- **Label:** `tsbridge.service.backend_addr`

##### `tsbridge.serviceName`
- **Type:** string or null
- **Default:** null (uses container name)
- **Description:** Custom service name on the Tailnet
- **Label:** `tsbridge.service.name`

#### Tailscale Features

##### `tsbridge.whoisEnabled`
- **Type:** boolean
- **Default:** false
- **Description:** Enable whois information showing which user accesses the service
- **Label:** `tsbridge.service.whois_enabled`

##### `tsbridge.funnelEnabled`
- **Type:** boolean
- **Default:** false
- **Description:** Expose service to the internet via Tailscale Funnel (requires Funnel enabled in Tailscale settings)
- **Label:** `tsbridge.service.funnel_enabled`

##### `tsbridge.ephemeral`
- **Type:** boolean
- **Default:** false
- **Description:** Make service node ephemeral (automatically removed when disconnected)
- **Label:** `tsbridge.service.ephemeral`

##### `tsbridge.tags`
- **Type:** list of strings
- **Default:** []
- **Description:** Additional Tailscale tags for this service
- **Example:** `["tag:api" "tag:production"]`
- **Label:** `tsbridge.service.tags`

#### Network and Performance

##### `tsbridge.listenAddr`
- **Type:** string or null
- **Default:** null
- **Description:** Custom listen address for this service
- **Example:** `:8080`
- **Label:** `tsbridge.service.listen_addr`

##### `tsbridge.flushInterval`
- **Type:** string or null
- **Default:** null
- **Description:** Interval for flushing responses (for streaming, Go duration format)
- **Example:** `"-1ms"` to disable buffering
- **Label:** `tsbridge.service.flush_interval`

#### Headers and Security

##### `tsbridge.headers`
- **Type:** attribute set of strings
- **Default:** {}
- **Description:** Additional HTTP headers to add to proxied requests (upstream_headers)
- **Example:** `{ "X-Custom-Header" = "value"; }`
- **Label:** `tsbridge.service.upstream_headers.*`

##### `tsbridge.insecureSkipVerify`
- **Type:** boolean
- **Default:** false
- **Description:** Skip TLS certificate verification for HTTPS backends (use only for trusted internal services with self-signed certificates)
- **Label:** `tsbridge.service.insecure_skip_verify`

#### Service URL Information

##### `tsbridge.serviceHost`
- **Type:** string (read-only)
- **Description:** The full hostname of the service on the Tailnet (automatically generated). Can be used for `ALLOWED_HOSTS` environment variables. For example `homepage` needs that in its `HOMEPAGE_ALLOWED_HOSTS` environment variable.   
- **Format:** `serviceName.tailnet-domain`
- **Example:** `"homepage.my-tailnet.ts.net"`
- **Note:** Uses custom `serviceName` if set, otherwise uses container name

##### `tsbridge.serviceUrl`
- **Type:** string (read-only)
- **Description:** The full HTTPS URL of the service on the Tailnet (automatically generated)
- **Example:** `"https://homepage.my-tailnet.ts.net"`
- **Usage:** Can be used in other container configurations that need to reference the tsbridge URL

## Not Yet Implemented

## Additional Options Not Yet Implemented

The following service-level options from the [tsbridge configuration reference](https://github.com/jtdowney/tsbridge/blob/main/docs/configuration-reference.md) are available in tsbridge but not yet exposed in this NixOS module:

### Network Options
- **`tls_mode`** - Controls TLS mode ("auto" or "off")

### Timeouts (Go duration format: "30s", "1m", etc.)
- **`read_header_timeout`** - Time to read request headers (default: 30s)
- **`idle_timeout`** - Keep-alive timeout (default: 120s)
- **`shutdown_timeout`** - Graceful shutdown timeout (default: 15s)
- **`dial_timeout`** - Time to establish backend connection (default: 30s)
- **`response_header_timeout`** - Time to wait for backend headers (default: 0s)
- **`keep_alive_timeout`** - Keep-alive probe interval (default: 30s)
- **`idle_conn_timeout`** - Idle connection timeout (default: 90s)
- **`tls_handshake_timeout`** - TLS handshake timeout (default: 10s)
- **`expect_continue_timeout`** - 100-continue timeout (default: 1s)
- **`whois_timeout`** - Whois lookup timeout (default: 1s)

### Header Manipulation
- **`downstream_headers`** - Headers to add to responses going to client
- **`remove_upstream`** - Headers to remove from requests (array/comma-separated)
- **`remove_downstream`** - Headers to remove from responses (array/comma-separated)

Note: The current `headers` option maps to `upstream_headers` only.

### Additional Options
- **`oauth_preauthorized`** - Override global preauth setting (default: true)
- **`access_log`** - Enable/disable access logging for this service (default: true)
- **`max_request_body_size`** - Request body size limit (bytes or human-readable format)

If you need any of these options, please open an issue or submit a pull request to the nix-podman-stacks repository.

## Examples

### Basic Service Exposure

```nix
{
  services.podman.containers.web = {
    image = "nginx:latest";
    
    tsbridge = {
      enable = true;
      port = 80;
    };
  };
}
```

### Service with Custom Name and Tags

```nix
{
  services.podman.containers.api = {
    image = "myapi:latest";
    
    tsbridge = {
      enable = true;
      port = 3000;
      serviceName = "production-api";
      tags = ["tag:api" "tag:prod"];
      whoisEnabled = true;
    };
  };
}
```

### Streaming Service (SSE, WebSocket, etc.)

```nix
{
  services.podman.containers.stream = {
    image = "streaming-app:latest";
    
    tsbridge = {
      enable = true;
      port = 8080;
      flushInterval = "-1ms";     # Disable buffering
    };
  };
}

# For global write timeout setting:
{
  nps.stacks.tsbridge = {
    enable = true;
    tailnetDomain = "my-tailnet.ts.net";
    writeTimeout = "0s";  # No write timeout globally
    oauth = {
      clientIdFile = "/run/secrets/tsbridge_oauth_id";
      clientSecretFile = "/run/secrets/tsbridge_oauth_secret";
    };
  };
}
```

### HTTPS Backend with Self-Signed Certificate

```nix
{
  services.podman.containers.internal-service = {
    image = "internal:latest";
    
    tsbridge = {
      enable = true;
      backendAddr = "internal-host:8443";
      insecureSkipVerify = true;
    };
  };
}
```

### Service with Custom Headers

```nix
{
  services.podman.containers.api = {
    image = "api:latest";
    
    tsbridge = {
      enable = true;
      port = 8000;
      headers = {
        "X-Forwarded-Proto" = "https";
        "X-Real-IP" = "$remote_addr";
      };
    };
  };
}
```

### Public Service via Tailscale Funnel

```nix
{
  services.podman.containers.public-web = {
    image = "nginx:latest";
    
    tsbridge = {
      enable = true;
      port = 80;
      serviceName = "website";
      funnelEnabled = true;  # Expose to the public internet
      tags = ["tag:public" "tag:web"];
    };
  };
}
```

> **Note:** Tailscale Funnel must be enabled in your Tailscale settings before using `funnelEnabled`. 
> The service will be accessible at `https://website.<tailnet-name>.ts.net` from anywhere on the internet.

## Advanced Configuration

### Using with Docker Socket Proxy

For enhanced security, use tsbridge with docker-socket-proxy:

```nix
{
  nps.stacks.tsbridge = {
    enable = true;
    tailnetDomain = "my-tailnet.ts.net";
    useSocketProxy = true;
    oauth = {
      clientIdFile = "/run/secrets/tsbridge_oauth_id";
      clientSecretFile = "/run/secrets/tsbridge_oauth_secret";
    };
  };
  
  nps.stacks.docker-socket-proxy.enable = true;
}
```

### Custom Network Configuration

```nix
{
  nps.stacks.tsbridge = {
    enable = true;
    network.name = "custom-tsbridge-net";
    oauth = {
      clientIdFile = "/run/secrets/tsbridge_oauth_id";
      clientSecretFile = "/run/secrets/tsbridge_oauth_secret";
    };
  };
  
  services.podman.containers.myapp = {
    image = "myapp:latest";
    tsbridge = {
      enable = true;
      port = 8080;
    };
    # Container will automatically join the tsbridge network
  };
}
```

## Networking Requirements

- tsbridge and all proxied services **must** share the same Docker/Podman network
- The module automatically adds services to the tsbridge network when `tsbridge.enable = true`
- Default network: `tsbridge-proxy` (subnet: 10.81.0.0/24)

## Troubleshooting

### Service not appearing on Tailnet

1. Check that OAuth credentials are valid
2. Verify the service has `tsbridge.enable = true`
3. Ensure service is on the same network as tsbridge
4. Check tsbridge container logs: `podman logs tsbridge`

### Connection timeouts for streaming services

Configure appropriate settings:

```nix
# Global write timeout
nps.stacks.tsbridge.writeTimeout = "0s";  # Disable write timeout globally

# Per-service flush interval
tsbridge = {
  flushInterval = "-1ms";   # Disable buffering
};
```

### HTTPS backend connection errors

For self-signed certificates:

```nix
tsbridge = {
  insecureSkipVerify = true;  # Only for trusted internal services
};
```

## References

- [tsbridge GitHub Repository](https://github.com/jtdowney/tsbridge)
- [tsbridge Docker Labels Documentation](https://github.com/jtdowney/tsbridge/blob/main/docs/docker-labels.md)
- [Tailscale OAuth Documentation](https://tailscale.com/kb/1215/oauth-clients/)
