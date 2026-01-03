## Example

```nix
{config, ...}: {
  nps.stacks.pocketid = {
    enable = true;
    encryptionKeyFile = config.sops.secrets."pocketid/encryptionKey".path;
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
