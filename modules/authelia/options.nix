lib:
with lib;
with types; rec {
  nullableClientSecretType = nullOr clientSecretType;

  clientSecretType = either str (submodule {
    options = {
      fromFile = lib.mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing the client secret hash.";
        example = lib.literalExpression ''config.sops.secrets."immich/client_secret_hash".path'';
      };
      toHash = lib.mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing the client secret. The file content will be hashed automatically before being passed to Authelia.";
        example = lib.literalExpression ''config.sops.secrets."immich/client_secret".path'';
      };
    };
  });

  clientSecretFile = mkOption {
    type = path;
    example = lib.literalExpression ''config.sops.secrets."immich/authelia/client_secret".path"'';
    description = ''
      The file containing the client secret for the OIDC client that will be registered in Authelia.

      For examples on how to generate a client secret, see

      <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
    '';
  };

  clientSecretHash = mkOption {
    type = clientSecretType;
    example = lib.literalExpression ''
      # Literal String:
      "$pbkdf2-sha512$310000$cbOAIWbfz3vCVXIPIp6d2A$J0klwULa6TvPRCU1HAfuKua/dMKTl8gbTYJz2N73ejGUu0LUGz/y3kwmJLuKuAYGg3WQOT0q9ZzVHHUvpKpgvQ"

      # Client secret hash stored in a file
      { fromFile = config.sops.secrets."immich/client_secret_hash".path; }

      # Client secret stored in a file: Hash will be computed dynamically
      { toHash = config.sops.secrets."immich/client_secret".path; }
    '';
    description = ''
      The client secret hash.
      For examples on how to generate a client secret, see

      <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>

      The value can be passed in multiple ways:

      1. As a literal string
      2. As an absolute path to a file containing the hash (`toFile`)
      3. As an absolute oath to a file containing the client_secret, in which case the hash will be automatically computed (`toHash`)
    '';
  };

  derivableClientSecretHash = clientSecretFile:
    mkOption {
      type = nullableClientSecretType;
      default = null;
      example = lib.literalExpression ''
        # Literal String:
        "$pbkdf2-sha512$310000$cbOAIWbfz3vCVXIPIp6d2A$J0klwULa6TvPRCU1HAfuKua/dMKTl8gbTYJz2N73ejGUu0LUGz/y3kwmJLuKuAYGg3WQOT0q9ZzVHHUvpKpgvQ"

        # Client secret hash stored in a file
        { fromFile = config.sops.secrets."immich/client_secret_hash".path; }

        # Client secret stored in a file: Hash will be computed dynamically
        { toHash = config.sops.secrets."immich/client_secret".path; }

        # Null (default): Hash will be computed automatically based on the clientSecretFile option
        # Equivalent to { toHash = cfg.oidc.clientSecretFile; }
        null
      '';
      description = ''
        The client secret hash.
        For examples on how to generate a client secret, see
        <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>

        The value can be passed in multiple ways:

        1. As a literal string
        2. As an absolute path to a file containing the hash (`toFile`)
        3. As an absolute oath to a file containing the client_secret, in which case the hash will be automatically computed (`toHash`)
        4. As `null`

        If left unset (`null`), the client secret will be read from the file specified in the `clientSecretFile` option and hashed automatically before being passed to the Authelia container.
      '';
      apply = v:
        if v == null
        then {
          toHash = clientSecretFile;
        }
        else v;
    };
}
