{
  backup = {
    database = {
      cronExpression = "0 02 * * *";
      enabled = true;
      keepLastAmount = 14;
    };
  };

  ffmpeg = {
    accel = "qsv";
    accelDecode = true;
    acceptedAudioCodecs = [
      "aac"
      "mp3"
      "opus"
      "pcm_s16le"
    ];
    acceptedContainers = [
      "mov"
      "ogg"
      "webm"
    ];
    acceptedVideoCodecs = [
      "hevc"
      "h264"
    ];
    bframes = -1;
    cqMode = "auto";
    crf = 23;
    gopSize = 0;
    maxBitrate = "0";
    preferredHwDevice = "auto";
    preset = "ultrafast";
    refs = 0;
    targetAudioCodec = "aac";
    targetResolution = "original";
    targetVideoCodec = "hevc";
    temporalAQ = false;
    threads = 0;
    tonemap = "hable";
    transcode = "required";
    twoPass = false;
  };

  image = {
    colorspace = "p3";
    extractEmbedded = false;
    fullsize = {
      enabled = false;
      format = "jpeg";
      quality = 80;
    };
    preview = {
      format = "jpeg";
      quality = 80;
      size = 1440;
    };
    thumbnail = {
      format = "webp";
      quality = 80;
      size = 250;
    };
  };

  job = {
    backgroundTask = {
      concurrency = 5;
    };
    faceDetection = {
      concurrency = 2;
    };
    library = {
      concurrency = 5;
    };
    metadataExtraction = {
      concurrency = 5;
    };
    migration = {
      concurrency = 5;
    };
    notifications = {
      concurrency = 5;
    };
    search = {
      concurrency = 5;
    };
    sidecar = {
      concurrency = 5;
    };
    smartSearch = {
      concurrency = 2;
    };
    thumbnailGeneration = {
      concurrency = 3;
    };
    videoConversion = {
      concurrency = 1;
    };
  };

  library = {
    scan = {
      cronExpression = "0 0 * * *";
      enabled = true;
    };
    watch = {
      enabled = false;
    };
  };

  logging = {
    enabled = true;
    level = "log";
  };

  machineLearning = {
    clip = {
      enabled = true;
      modelName = "ViT-B-32__openai";
    };
    duplicateDetection = {
      enabled = true;
      maxDistance = 0.01;
    };
    enabled = true;
    facialRecognition = {
      enabled = true;
      maxDistance = 0.5;
      minFaces = 3;
      minScore = 0.7;
      modelName = "buffalo_l";
    };
    urls = ["http://immich-machine-learning:3003"];
  };

  map = {
    darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
    enabled = true;
    lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
  };

  metadata = {
    faces = {
      import = false;
    };
  };

  newVersionCheck = {
    enabled = true;
  };

  notifications = {
    smtp = {
      enabled = false;
      from = "";
      replyTo = "";
      transport = {
        host = "";
        ignoreCert = false;
        password = "";
        port = 587;
        username = "";
      };
    };
  };

  passwordLogin = {
    enabled = true;
  };

  reverseGeocoding = {
    enabled = true;
  };

  server = {
    externalDomain = "";
    loginPageMessage = "";
    publicUsers = true;
  };

  storageTemplate = {
    enabled = true;
    hashVerificationEnabled = true;
  };

  templates = {
    email = {
      albumInviteTemplate = "";
      albumUpdateTemplate = "";
      welcomeTemplate = "";
    };
  };

  theme = {
    customCss = "";
  };

  trash = {
    days = 30;
    enabled = true;
  };

  user = {
    deleteDelay = 7;
  };
}
