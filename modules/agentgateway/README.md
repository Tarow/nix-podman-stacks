Gateway for AI agents, LLM providers, and MCP services.

- [Github](https://github.com/agentgateway/agentgateway)
- [Website](https://agentgateway.dev/)

## Examples

### Simple

```nix
{
  nps.stacks.agentgateway.enable = true;
}
```

### Declarative Settings

```nix
{config, ...}: {
  nps.stacks.agentgateway = {
    enable = true;

    settings = {
      config = {
        database.url = "sqlite:///config/data.db";
        session = {
          key = "$SESSION_KEY";
        };
      };
      gateways.default.port = 4000;
      ui.gateways = "default";
      llm.gateways = "default";
      mcp.gateways = "default";
    };

    extraEnv.SESSION_KEY.fromFile = config.sops.secrets."agentgateway/session_key".path;
  };
}
```
