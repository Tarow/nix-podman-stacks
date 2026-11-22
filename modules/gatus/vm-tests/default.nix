{
  nps.stacks.gatus = {
    enable = true;
    # Gatus refuses to start with an empty endpoint list.
    settings.endpoints = [
      {
        name = "Self";
        url = "http://localhost:8080";
      }
    ];
  };
}
