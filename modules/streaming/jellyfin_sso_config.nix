{
  autheliaUri,
  clientId,
  adminGroup,
  userGroup,
  clientSecretFile,
}: ''
  <?xml version="1.0" encoding="utf-8"?>
  <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <SamlConfigs />
    <OidConfigs>
      <item>
        <key>
          <string>authelia</string>
        </key>
        <value>
          <PluginConfiguration>
            <OidEndpoint>${autheliaUri}</OidEndpoint>
            <OidClientId>${clientId}</OidClientId>
            <OidSecret>{{ file.Read "${clientSecretFile}" }}</OidSecret>
            <Enabled>true</Enabled>
            <EnableAuthorization>true</EnableAuthorization>
            <EnableAllFolders>true</EnableAllFolders>
            <EnabledFolders />
            <AdminRoles>
              <string>${adminGroup}</string>
            </AdminRoles>
            <Roles>
              <string>${adminGroup}</string>
              <string>${userGroup}</string>
            </Roles>
            <EnableFolderRoles>false</EnableFolderRoles>
            <EnableLiveTvRoles>false</EnableLiveTvRoles>
            <EnableLiveTv>false</EnableLiveTv>
            <EnableLiveTvManagement>false</EnableLiveTvManagement>
            <LiveTvRoles />
            <LiveTvManagementRoles />
            <FolderRoleMappings />
            <RoleClaim>groups</RoleClaim>
            <OidScopes>
              <string>groups</string>
            </OidScopes>
            <CanonicalLinks></CanonicalLinks>
            <DisableHttps>false</DisableHttps>
            <SchemeOverride>https</SchemeOverride>
            <DisablePushedAuthorization>true</DisablePushedAuthorization>
            <DoNotValidateEndpoints>false</DoNotValidateEndpoints>
            <DoNotValidateIssuerName>false</DoNotValidateIssuerName>
          </PluginConfiguration>
        </value>
      </item>
    </OidConfigs>
  </PluginConfiguration>
''
