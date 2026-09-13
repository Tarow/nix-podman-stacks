{
  dummyHash,
  dummySecretFile,
  dummyUser,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.guacamole = {
    enable = true;
    userMappingXml = ''
      <user-mapping>
        <authorize username="${dummyUser}" password="{{ file.Read `${dummySecretFile}`}}">
            <connection name="SSH">
                <protocol>ssh</protocol>
                <param name="hostname">host.containers.internal</param>
                <param name="port">22</param>
            </connection>
        </authorize>
      </user-mapping>
    '';
    oidc.enable = true;
    db.passwordFile = dummySecretFile;
  };
}
