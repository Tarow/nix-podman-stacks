## Example

```nix
{config, ...}: {
  pocketid = {
    enable = true;

    # Sync users from LLDAP
    ldap.enableSynchronisation = true;

    # Register OIDC Traefik middleware
    traefikIntegration = {
      enable = true;
      clientId = "123-456-789-abc-def";
      clientSecretFile = config.sops.secrets."pocketid/traefik/clientSecret".path;
      encryptionSecretFile = config.sops.secrets."pocketid/traefik/middlewareSecret".path;
    };
  };
}
```
