AI coding agent server. Omnigent is a meta-harness for running, governing and collaborating on AI coding agents from a shared server, with native OIDC login, policies and session history.

- [Github](https://github.com/omnigent-ai/omnigent)
- [Website](https://omnigent.ai)

The OIDC session cookie secret needs to be 64 hex characters, generate it with `openssl rand -hex 32`.

## Example

```nix
{
  nps.stacks.omnigent = {
    enable = true;

    db = {
      type = "postgres";
      passwordFile = config.sops.secrets."omnigent/db_password".path;
    };

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."omnigent/oidc/client_secret".path;
      cookieSecretFile = config.sops.secrets."omnigent/oidc/cookie_secret".path;
      # clientSecretHash = ... # optional, defaults to hashing clientSecretFile
    };
  };
}
```