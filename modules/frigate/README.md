NVR with real-time local object detection for IP cameras.

- [Github](https://github.com/blakeblackshear/frigate)
- [Docs](https://docs.frigate.video/)

## Example

```nix
{
  nps.stacks.frigate = {
    enable = true;
    settings = {
      ffmpeg.hwaccel_args = "preset-intel-qsv-h264";

      go2rtc.streams.birdfeeder = [
        "https://<username>:<password>@<ip>:<port>/video/h264"
      ];
      cameras.birdfeeder = {
        enabled = true;
        ffmpeg.inputs = [
          {
            path = "rtsp://127.0.0.1:8554/birdfeeder";
            input_args = "preset-rtsp-restream";
            roles = ["detect" "record"];
          }
        ];
        objects.track = ["bird"];
      };
      record = {
        enabled = true;
        continuous = {
          days = 1;
        };
        motion = {
          days = 1;
        };
        detections.retain = {
          days = 1;
        };
        alerts.retain = {
          days = 1;
        };
      };
      snapshots = {
        enabled = true;
        retain.default = 7;
      };
    };
  };
}
```
