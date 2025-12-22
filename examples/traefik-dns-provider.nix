/*
Traefik is configured to use cloudflare for the letsencrypt DNS challenge when getting certificates for your domain.
You can override the DNS challenge provider by modifying the static config.
Keep in mind, that depending on the used provider, you have to provide the necessary environment variables.
Refer to https://doc.traefik.io/traefik/reference/install-configuration/tls/certificate-resolvers/acme/#dnschallenge for details
*/
{
  nps.stacks = {
    traefik.staticConfig.certificatesResolvers.letsencrypt.acme.dnsChallenge.provider = "porkbun";
  };
}
