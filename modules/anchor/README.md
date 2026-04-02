# Anchor

Offline-first, self-hostable note-taking application.

## Features

- Rich text editor with formatting
- Offline-first with local database
- Note sharing with users
- Tags system with colors
- Attachments (images, audio)
- Admin panel for user management
- OIDC authentication

## Usage

```nix
nps.stacks.anchor = {
  enable = true;

  # Optional: Use external PostgreSQL (default: embedded)
  db.type = "postgres";
  db.passwordFile = "/path/to/password";

  # Optional: Enable OIDC with Authelia
  oidc = {
    enable = true;
    clientSecretFile = "/path/to/secret";
  };

    # Optional: Extra environment variables
    extraEnv = {
      # SOME_SECRET = { fromFile = "/run/secrets/secret_name"; };
      # FOO = "bar";
    };
  };
```
