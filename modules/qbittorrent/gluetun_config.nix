{
  roles = [
    {
      name = "public";
      routes = ["GET /v1/publicip/ip"];
      auth = "none";
    }
  ];
}
