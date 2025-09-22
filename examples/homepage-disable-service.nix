/*
In order to avoid having a service show up in the homepage dashboard,
set the `category` option to `null`.
*/
{
  nps.stacks = {
    streaming.containers.sonarr.homepage.category = null;
  };
}
