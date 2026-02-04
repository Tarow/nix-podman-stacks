Health dashboard for containers

- [Github](https://github.com/TwiN/gatus)

## Example

```nix
{config, ...}: {
  nps.stacks.gatus = {
    enable = true;

    db = {
      type = "postgres";
      passwordFile = config.sops.secrets."gatus/postgresPassword".path;
    };

    settings.endpoints = [
      {
        name = "Some website";
        url = "https://example.com";
        client.dns-resolver = "tcp://1.1.1.1:53";
        conditions = [
          "[STATUS] == 200"
        ];
      }
    ];

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."gatus/authelia_client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
