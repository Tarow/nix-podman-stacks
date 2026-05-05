This module serves as an exemplary stack, designed primarily as a structural blueprint for future contributions.

Please note that this blueprint is optimized for straightforward, standard services. Should your service support or require other configurations, such as external YAML files, I recommend examining other existing modules or creating a custom solution.

## Service Implementation Checklist

- [ ] **Verify Existence**: Ensure the service has not yet been implemented.
- [ ] **Documentation Review**: Thoroughly consult the service's docs, paying particular attention to:
  - [ ] Admin User Provisioning {39}
  - [ ] OIDC Integration {130}
  - [ ] Volumes paths {171}
  - [ ] Required Environment Variables {179}
  - [ ] Port, that reverse proxy will forward to (if applicable) {201}
  - [ ] Database Compatibility (Supported types and specific requirements) {225}
- [ ] **Implementation**:
  - [ ] Duplicate the `modules/example` directory.
  - [ ] Apply the information gathered during the documentation review. Note: The bracketed numbers `{}` indicate the corresponding lines or blocks requiring modification in `default.nix`.
  - [ ] Edit the `default.nix` file, following the comments and instructions.
  - [ ] Add your module to `modules/module_list.nix` and a sample configuration in `ci_config.nix`.
  - [ ] Add the service to the list of services in the root `README.md`
  - [ ] Update the docs below

**Note:** Please delete the content above (including this line) before submitting a PR.

{One sentence description of the service}

- [Github](Source code of the service)
- [Website](Website of the service, if it exists)

## Example

```nix
{config, ...}: {
  nps.stacks.example = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."example/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
