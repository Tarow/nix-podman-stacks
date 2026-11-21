{
  dummyEmail,
  dummySecretFile,
  ...
}: {
  nps.stacks.ntfy = {
    enable = true;
    extraEnv = {
      NTFY_WEB_PUSH_EMAIL_ADDRESS = dummyEmail;
      NTFY_WEB_PUSH_PUBLIC_KEY.fromFile = dummySecretFile;
      NTFY_WEB_PUSH_PRIVATE_KEY.fromFile = dummySecretFile;
    };
    enableGrafanaDashboard = true;
    enablePrometheusExport = true;
  };
}
