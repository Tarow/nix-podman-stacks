A self-hosted library and reading platform for ebooks, audiobooks, comics and PDFs

- [Github](https://github.com/bookorbit/bookorbit)
- [Website](https://bookorbit.app/)

## Example

```nix
{config, ...}: {
  nps.stacks.bookorbit = {
    enable = true;
    libraryPath = "/mnt/hdd/media/books";
    jwtSecretFile = config.sops.secrets."bookorbit/jwt_secret".path;
    podcastEncryptionKeyFile = config.sops.secrets."bookorbit/podcast_encryption_key".path;
    setupBootstrapTokenFile = config.sops.secrets."bookorbit/setup_bootstrap_token".path;
    db.passwordFile = config.sops.secrets."bookorbit/db_password".path;
    oidc = {
      registerClient = true;
      clientSecretHash = "$pbkdf2-sha512$...";
      userGroup = "bookorbit_user";
      adminGroup = "bookorbit_admin";
    };
    tts.enable = true;
  };
}
```

## OIDC

When `oidc.registerClient = true`, the stack registers an OIDC client in Authelia.
You still need to add the provider in the Web UI under Settings → OIDC / SSO with:

| Field | Value |
|-------|-------|
| Issuer URI | `https://authelia.<your domain>` |
| Client ID | `bookorbit` |
| Client Secret | Value from `oidc.clientSecretHash` |
| Scopes | `openid profile email groups` |
| Redirect URI | `https://bookorbit.<your domain>/oauth2-callback` |
| Group Claim | `groups` |

Group mappings translate an Authelia group into a BookOrbit permission. Map `bookorbit_admin` to admin permissions and `bookorbit_user` for basic access. Note that a group can only map to a single permission, so multiple permissions require multiple groups.

If Authelia is reachable on a private address only, set `OIDC_ALLOW_LOCAL_ISSUERS` via `extraEnv`.

## Text-to-Speech

Enable `tts.enable` to add a Kokoro container. The TTS provider is registered automatically at `http://bookorbit-kokoro:8880/v1`.

## OIDC Group Mappings

If you set `oidc.adminGroup`, add group mappings manually in the UI:
- Settings → OIDC / SSO → your provider → Group Mappings
- Map `${oidc.adminGroup}_<permission>` → `<permission>` (e.g., `bookorbit_admin_ManageAppSettings` → `ManageAppSettings`)