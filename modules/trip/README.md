Minimalist Map tracker and Trip planner

- [Github](https://github.com/itskovacs/trip)
- [Website](https://itskovacs-trip.netlify.app/)

## Example

```nix
{config, ...}: {
  nps.stacks.trip = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."trip/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
