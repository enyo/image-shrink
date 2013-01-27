# Shrink

Connect middleware that resizes images on the fly.

It supports cropping & scaling, and caches the resulting images.

# Usage


```coffee
app.use require("node-shrink")(
  cachePath: __dirname + "/.." + config.paths.resizedCacheDir
  tmpPath: __dirname + "/.." + config.paths.tmpDir
  secret: config.general.imageSecret
)
```