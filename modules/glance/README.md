## Example

```nix
{config, ...}: {
  glance = {
    enable = true;
    settings.pages.home = {
      columns.start = {
        rank = 500;
        size = "small";
        widgets = [
          {
            type = "server-stats";
            servers = [
              {
                type = "local";
                name = "Server";
              }
            ];
          }
          {
            type = "reddit";
            subreddit = "selfhosted";
            collapse-after = 3;
          }
        ];
      };
    };
  };
}
```
