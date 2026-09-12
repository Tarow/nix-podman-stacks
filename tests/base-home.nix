# Base home-manager settings for VM integration tests.
{pkgs, ...}: {
  home = {
    username = "ci";
    homeDirectory = "/home/ci";
    stateVersion = "26.05";
  };

  # Dummy secrets (never use real ones here)
  _module.args = {
    dummySecretFile = "${pkgs.writeText "dummy-secret" "insecure_secret_insecure_secret"}";
    dummyHash = "$argon2id$v=19$m=65536,t=3,p=4$8USywQgWNhOf4drzlVTieA$Rm8SlHy+ipThtIa/6nMMir2QkoXESCr4uCB2aAdvlmo";
    dummyClientSecretHash = "$pbkdf2-sha512$310000$cbOAIWbfz3vCVXIPIp6d2A$J0klwULa6TvPRCU1HAfuKua/dMKTl8gbTYJz2N73ejGUu0LUGz/y3kwmJLuKuAYGg3WQOT0q9ZzVHHUvpKpgvQ";
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
