{
  dummyEmail,
  dummyHash,
  dummySecretFile,
  dummyUser,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.paperless = {
    enable = true;
    adminProvisioning = {
      username = dummyUser;
      email = dummyEmail;
      passwordFile = dummySecretFile;
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
    secretKeyFile = dummySecretFile;
    extraEnv = {
      PAPERLESS_OCR_LANGUAGES = "eng deu";
      PAPERLESS_OCR_LANGUAGE = "eng+deu";
    };
    db.passwordFile = dummySecretFile;
    enableTika = true;
    ftp = {
      enable = true;
      passwordFile = dummySecretFile;
    };
  };
}
