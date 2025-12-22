/*
Some services don't have built-in auth or support OIDC
If you still want to protect them, it is possible by utilizing Traefiks ForwardAuth middleware in combination with Authelia.

Rules can be either configured through the authelia settings options, or at container level.
In the latter case they will be forwarded.

The following two configurations are equivalent:
*/
{config, ...}: {
  # Apply the authelia middleware for the Homepage service
  nps.stacks.homepage.containers.homepage = {
    traefik.middleware.authelia.enable = true;
  };
  # Setup a rule for the Homepage service domain. If no Authelia rule matches, the default_policy applies
  nps.stacks.authelia.settings = {
    access_control.rules = [
      {
        domain = config.nps.containers.homepage.traefik.serviceHost;
        policy = "two_factor";
      }
    ];
  };

  # The above configuration can also be achieved by setting the `forwardAuth` container options.
  # The domain will be automatically infered and defaults to the serviceHost registered in Traefik.
  # If forwardAuth is enabled, the Authelia middleware will also be applied automatically
  nps.stacks.homepage.containers.homepage = {
    forwardAuth = {
      enable = true;
      rules = [
        {
          # For a full list of available rule option see <https://www.authelia.com/configuration/security/access-control/>
          policy = "two_factor";
        }
      ];
    };
  };
}
