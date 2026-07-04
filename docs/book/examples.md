# Examples

## Disable Stack

Each stack has a `enable` option that has to be set to enable a stack.
In order to disable the Streaming stack, set the `enable` option to `false` or remove the declaration entirely, since stacks are disabled by default.

```nix
{
  nps.stacks.streaming.enable = false;
}
```

## Override & extend Defaults

The `nps` modules are built on top of Home Managers builtin [`services.podman.containers`](https://home-manager-options.extranix.com/?query=services.podman.containers&release=release-25.11) options.
When enabling a stack, under the hood, one or multiple `services.podman.containers` definitions will be created, including the setup of necessary environment variables, volumes, labels etc.

In some cases it can be helpful to either extend or override the settings that a module is preconfigured with.
The options can be set directly on `services.podman.container` level, or through the stack aliases provided with this project.
For example, the following two configurations are equivalent:

```nix
{
  nps.stacks = {
      streaming.containers.jellyfin.volumes = ["/mnt/hdd2/media:/media/extra-lib"];
  };
}
```

```nix
{
  services.podman.containers.jellyfin.volumes = ["/mnt/hdd2/media:/media/extra-lib"];
}
```

### Extending Presets

Mergable option types like attribute sets (e.g. used for environment variables) or lists (e.g. used for volumes) can be extended.
In the above example, the new Jellyfin volume would be appended to the list of preconfigured volumes that a module defines.

The same works with attribute sets. To add new environment variables to the Paperless container:

```nix
{
  nps.stacks.paperless = {
    containers.paperless.environment = {
      PAPERLESS_CONSUMER_RECURSIVE = true;
      PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
    };
  };
}
```

This would append the two new environment variables to the existing configuration.

### Override Presets

While mergable option type definitions with the same priority will be merged, it's also possible to override a definition.
For example, instead of appending to the existing list of volumes, we can override all volumes entirely.

Modifying the initial example:

```nix
{lib, ...}: {
  nps.stacks = {
      streaming.containers.jellyfin.volumes = lib.mkForce ["/mnt/hdd2/media:/media/extra-lib"];
  };
}
```

The `lib.mkForce` will apply this option with a higher prioority. It won't be merged with the existing definition but will override it entirely. In this case, the Jellyfin container would only have a single volume entry.

The same goes for the Paperless example:

```nix
{lib, ...}: {
  nps.stacks.paperless = {
    containers.paperless.environment = lib.mkForce {
      PAPERLESS_CONSUMER_RECURSIVE = true;
      PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
    };
  };
}
```

This would override all environment variables of the Paperless container. The final container would only have two environment variables defined.

In case of conflicting definitions, instead of overriding all attributes of an attribute set, you can also apply it to individual items:

```nix
{lib, ...}: {
  nps.stacks.paperless = {
    containers.paperless.environment = {
      PAPERLESS_FILENAME_FORMAT = lib.mkForce "{{created_year}}/{{created_month}}/{{correspondent}}/{{title}}";
    };
  };
}
```

### Override individual Volumes

When overriding the `volumes` option (list type), the full list of new volumes has to be specified.
For stacks that define multiple volumes, this may be undesired, especially if only a single volume definition should be overriden.

To allow overriding individual volumes, the nps modules will declare the [`volumeMap`](/container-options#services.podman.containers.<name>.volumeMap) option. This is a simple attribute set wrapper around the `volumes` option, which allows refering to individual volumes.

Example:

```nix
{
  nps.stacks = {
    paperless.containers.paperless.volumeMap = {
      media = lib.mkForce "/mnt/hdd/documents:/usr/src/paperless/media";
    };
  };
}
```

This will only override the volume definition for the media files, all other volumes will remain unaffected.

## Authelia

### Forward Auth

Some services don't have built-in auth or support OIDC.
If you still want to protect them, it is possible by utilizing Traefiks ForwardAuth middleware in combination with Authelia.

Rules can be either configured through Authelia settings options, or at container level.
In the latter case they will be forwarded.

The following two configurations are equivalent:

```nix
{config, ...}: {



  # Apply the authelia middleware for the Homepage service
  nps.stacks.homepage.containers.homepage = {
    traefik.middleware.authelia.enable = true;
  };

  nps.stacks.authelia.settings = {
    # Setup a rule for the Homepage service domain.
    access_control.rules = [
      {
        domain = config.nps.containers.homepage.traefik.serviceHost;
        policy = "two_factor";
      }
    ];
  };
}
```

The above configuration can also be achieved by setting the `forwardAuth` container options.
The domain will be automatically infered and defaults to the serviceHost registered in Traefik.
If forwardAuth is enabled, the Authelia middleware will also be applied automatically

```nix
{config, ...}: {
  nps.stacks.homepage.containers.homepage = {
    forwardAuth = {
      enable = true;
      rules = [
        {
          # For a full list of available rule options see <https://www.authelia.com/configuration/security/access-control/>
          policy = "two_factor";
        }
      ];
    };
  };
}
```

For details on the `forwardAuth` container option check the [Container Options](/container-options#services.podman.containers.<name>.forwardAuth.enable)

### Forward Auth - Group based access

In the previous example, every access required `two_factor` authentication to access the resource.
A common use-case is, to only allow certain users with specific groups to access a resource.
This can be achieved as followed:

```nix
{config, ...}: {
  nps.stacks = {
    # Create LLDAP group
    lldap.bootstrap.groups."homepage_user" = {};

    # Allow only users in the created "homepage_user" group to access the homepage dashboard
    # For others, the default policy (deny) will apply
    homepage.containers.homepage = {
      forwardAuth = {
        enable = true;
        rules = [
          {
            subject = ["group:homepage_user"];
            policy = "one_factor";
          }
        ];
      };
    };
  };
}
```

## Gatus

### Simple Service Monitor

You can monitor the status of a service by adding it to the Gatus endpoint configuration.
This can be simplified by using a containers `gatus` option.

When enabled, by default the endpoint settings configured via `nps.stacks.gatus.defaultEndpoint`
are used. You can override individial settings as needed (e.g. timeout, conditions).

The endpoint added to the Gatus configuration will be the domain of the service that is handled by Traefik.
This can also be overriden by setting the `url` option in the `gatus.settings`.
The most basic example to enable Gatus monitoring:

```nix
{config, ...}: {
  nps.stacks.streaming.containers.sonarr.gatus.enable = true;
}
```

The above is equivalent to adding the service to Gatus via its settings option:

```nix
{config, ...}: {
  nps.stacks.gatus = {
    settings.endpoints = let
      sonarrCfg = config.nps.stacks.streaming.containers.sonarr;
    in [
      {
        name = sonarrCfg.traefik.name;
        url = sonarrCfg.traefik.serviceUrl;
      }
    ];
  };
}
```

### Override Defaults

To override the default settings of a container when enabling Gatus (e.g. the url),
the `settings` attribute can be used, which is directly mapped to an endpointentry in the in Gatus configuration.

For example to set the `url` to a custom one and change the condition:

```nix
{config, ...}: {
  nps.stacks = let
    cfg = config.nps.stacks.aiostreams.containers.aiostreams;
  in {
    aiostreams.containers.aiostreams.gatus = {
      enable = true;
      settings = {
        url = "${cfg.traefik.serviceUrl}/api/v1/status";
        conditions = [
          "[BODY].success == true"
        ];
      };
    };
  };
}
```

## Glance

### Override Attributes

Most containers come with preconfigured Glance coniguration.
They will set `category`, `name`, `description`, `href`, ...
You can override these values if desired.

The options are not available on stack level, so we can refer to the container options

```nix
{lib, ...}: {
  nps.stacks = {
    adguard.containers.adguard.homepage = {
      name = lib.mkForce "New Name";
      category = lib.mkForce "New Category";
      settings = {
        description = lib.mkForce "New Description";
        icon = lib.mkForce "si-adblock";
      };
    };
  };
}
```

## Homepage

### Override Attributes

Most containers come with preconfigured homepage coniguration.
They will set category, name and description.
You can override these values if desired.

The options are not available on stack level, so we can refer to the container options

```nix
{lib, ...}: {
  nps.stacks = {
    adguard.containers.adguard.homepage = {
      name = lib.mkForce "New Name";
      category = lib.mkForce "New Category";
      settings = {
        description = lib.mkForce "New Description";
        icon = lib.mkForce "si-adblock";
      };
    };
  };
}
```

### Disable Service

In order to avoid having a service show up in the homepage dashboard,
set the `category` option to `null`.

```nix
{
  nps.stacks = {
    streaming.containers.sonarr.homepage.category = null;
  };
}
```

### Sort Services

By default services in a category are sorted alphabetically.
You can set the `rank` attribute to influence the order of services.
For example, to move the `traefik` and `wg-easy` services to the top:

```nix
{
  nps.stacks = {
    traefik.containers.traefik.homepage.settings.rank = 10;
    wg-easy.containers.wg-easy.homepage.settings.rank = 20;
  };
}
```

### Enable Widgets

You can also enable homepage widgets.
For the necessary values, refer to the widget documentation of the hompage project: https://gethomepage.dev/widgets/

The 'url' and 'type' attributes are already preconfigured for every widget.
To enable a widget, we need to set the `enable` flag and add missing information (if any).

```nix
{
  nps.stacks = {
    streaming.containers.sonarr.homepage.settings.widget = {
      enable = true;

      # In order to avoid having secrets visible in your config refer to the following example
      key = "secret";
    };
  };
}
```

### Widget Secrets

In order to avoid secrets being visible in your Git repository, you can also pass widget values as paths.
This allows you to refer to sops secrets for example.

If a value is a passed as a 'path', it will be replaced by an placeholder and the necessary environment variable
will be automatically added to the homepage container.

```nix
{config, ...}: {
  nps.stacks = {
    streaming.containers.sonarr.homepage.settings.widget = {
      enable = true;
      key = {path = config.sops.secrets."SONARR_API_KEY".path;};
    };
  };
}
```

## Prometheus Alerting

Prometheus alerts handled by Alertmanager can be automatically forwarded to `ntfy`:

```nix

{
  nps.stacks = {
    # We will receive notifications through ntfy
    ntfy.enable = true;

    monitoring = {
      enable = true;

      # Prometheus alert rules.
      # Fire when CPU usage is >90% for 20 minutes or RAM usage is >85%
      # Alertmanager will handle alerts
      prometheus.rules.groups = let
        cpuThresh = 90;
        ramThresh = 85;
      in [
        {
          name = "resource.usage";
          rules = [
            {
              alert = "HighCpuUsage";
              expr = ''100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > ${toString cpuThresh}'';
              for = "20m";
              labels = {
                severity = "warning";
              };
              annotations = {
                summary = "High CPU usage";
                description = "CPU usage is above ${toString cpuThresh}% (current value: {{ $value }}%)";
              };
            }
            {
              alert = "HighRamUsage";
              expr = ''(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > ${toString ramThresh}'';
              labels = {
                severity = "warning";
              };
              annotations = {
                summary = "High RAM usage";
                description = "RAM usage is above ${toString ramThresh}% (current value: {{ $value }}%)";
              };
            }
          ];
        }
      ];

      # Handle Prometheus alerts and forward them to ntfy
      alertmanager = {
        enable = true;
        ntfy = {
          enable = true;
          settings.ntfy.notification.topic = "monitoring";
        };
      };
    };
  };
}
```

## Traefik

### Change Service Subdomain

The subdomain which a service is reachable at is controlled by the containers `traefik.name` attribute.
Is it preconfigured for every container.
You can override the subdomain, e.g. make Sonarr available at
'series.mydomain.com' instead of 'sonarr.mydomain.com'.

Changes to the traefik subdomain will automatically be reflected on the Homepage dashboard too,
so the `href` will update automatically.

```nix
{lib, ...}: {
  nps.stacks = {
    streaming.containers.sonarr.traefik.subDomain = "series";
  };
}
```

### Change DNS Provider

Traefik is configured to use Cloudflare for the Letsencrypt DNS challenge when getting certificates for your domain.
You can override the DNS challenge provider by modifying the static config.
Keep in mind, that depending on the used provider, you have to provide the necessary environment variables.
Refer to <https://doc.traefik.io/traefik/reference/install-configuration/tls/certificate-resolvers/acme/#dnschallenge> for details

```nix
{
  nps.stacks = {
    traefik.staticConfig.certificatesResolvers.letsencrypt.acme.dnsChallenge.provider = "porkbun";
  };
}
```

### Expose Service

By default, Traefik is configured with two middlewares.
`private`: Only allows access to a service from private networks
`public`: Allows external access. Will setup ratelimits, geoblocking, security-headers and Crowdsec if enabled

The option `expose` controls which of these two middlewares is applied.
By default the `expose` option defaults to `false`, which results in the `private` middleware being applied.

To expose a service, set the `expose` option to `true`, which results in the `public` middleware being applied.

If you use the `dockdns` stack, a DNS entry pointing to your public IP will be created automatically in Cloudflare.
When changing a service from public to private, the DNS entry can be automatically removed.

```nix
{
  nps.stacks = {
    streaming.containers.jellyfin.expose = true;
  };
}
```

### Start Containers after Sops Secret Provisioning

If you use use [sops-nix](https://github.com/Mic92/sops-nix) to provide secrets for your services, you want to make sure the container starts after sops has provisioned the secrets to avoid a race condition.

This can be done by adding a systemd dependency to a particular service. For example, to start the Paperless service after sops has decrypted the secrets:

```nix
{
  nps.stacks.paperless.containers.paperless = {
    extraConfig.Unit = {
      Wants = ["sops-nix.service"];
      After = ["sops-nix.service"];
    };
  };
}
```

Instead of individually configuring every service like this, you can also include this module to declare the dependency for every container automatially:

```nix
{
  # Make sure every container starts after the sops-nix service
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule ({config, ...}: {
        extraConfig.Unit = {
          Wants = ["sops-nix.service"];
          After = ["sops-nix.service"];
        };
      })
    );
  };
}
```
