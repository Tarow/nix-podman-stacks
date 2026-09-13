# Base home-manager settings for VM integration tests.
{pkgs, ...}: {
  home = {
    username = "ci";
    homeDirectory = "/home/ci";
    stateVersion = "26.05";
  };

  # Dummy secrets (never use real ones here)
  _module.args = {
    # 64-character string, satisfies most stacks' secret format requirements
    dummySecretFile = "${pkgs.writeText "dummy-secret" "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"}";
    dummyHash = "$argon2id$v=19$m=65536,t=3,p=4$689VBxbUiBYuXgC2flxaMQ$dblA2J+WccfKujUOVm4KiIh5RrvCr02fOJNT2oKhGy0";
    dummyClientSecretHash = "$pbkdf2-sha512$310000$1THCrOhCoICCVjNz7vfFMQ$2ercGVMG99CVVF42gs9BA4O9v.LlO3m8m8.6w0ynI0UFNJgnDPxadvgMTVc8mkCARlUSS5ZyxrSmm0WP31ZLSw";
    dummyUser = "admin";
    dummyEmail = "admin@example.com";
    dummyId = "dummy";
    dummySecret = "insecure_secret";
    dummyRsaKeyFile = "${pkgs.runCommand "dummy-rsa-key" {nativeBuildInputs = [pkgs.openssl];} "openssl genrsa -out $out 2048"}";
  };

  nps = {
    hostUid = 1000;
    storageBaseDir = "/home/ci/stacks";
    externalStorageBaseDir = "/mnt/media";
    defaultTz = "UTC";
    hostIP4Address = "192.168.1.1";
  };
}
