

file = require("../../file")
im = require("imagemagick")
crypto = require("crypto")
fs = require("fs")


module.exports = (options) ->
  new Shrink(options)



pathRegex = /^\/+(resize|crop)\/([a-z0-9]+)\-(\d*)x(\d*)\.(jpg|png)$/i


#
# Middleware to resize images.
#
class Shrink

  constructor: (@options) ->
  
  accepts: (req) ->
    parsedUrl = require("url").parse(req.url, true)

    matches = parsedUrl.pathname.match pathRegex
    return false unless matches? and parsedUrl.query?.hash?

    urlInfo =
      method: matches[1]
      fileId: matches[2]
      width:  matches[3]
      height: matches[4]
      extension: matches[5]

    urlInfo.cacheFilename = "#{urlInfo.method}/#{urlInfo.fileId}-#{urlInfo.width}x#{urlInfo.height}.#{urlInfo.extension}"

    hash = crypto.createHash("md5").update(urlInfo.cacheFilename + @options.secret).digest("hex")
    resizeHash = crypto.createHash("md5").update("#{urlInfo.method}-#{urlInfo.width}x#{urlInfo.height}" + @options.secret).digest("hex")

    unless hash is parsedUrl.query.hash or resizeHash is parsedUrl.query.hash
      console.warn "Wrong hash for (#{urlInfo.cacheFilename}). Right hash: #{hash} or resizeHash: #{resizeHash}"
      return false
    else
      # resizeHash
      req._urlInfo = urlInfo
      return true


  # This should only be called once! The second time a static file server should directly serve the file.
  # This method assumes accepts() has been called before to set req._urlInfo
  handle: (req, res, next) ->
    cacheFilename = "/" + req._urlInfo.cacheFilename

    file.read req._urlInfo.fileId, (err, data) =>
      return next err if err?
        

      tmpUri = @options.tmpPath + (new Date().getTime().toString()) + Math.round(Math.random() * 10000).toString()
      fs.writeFile tmpUri, data, (err) =>
        return next err if err?
          
        options =
          srcPath: tmpUri
          dstPath: @options.cachePath + cacheFilename

        options.width = req._urlInfo.width  if req._urlInfo.width?
        options.height = req._urlInfo.height  if req._urlInfo.height?
        im[req._urlInfo.method] options, (err, stdout, stderr) ->
          return next err if err?

          # Redirect to the same url since now the static server should serve it.
          res.redirect cacheFilename

          fs.unlink tmpUri, (err) -> console.error err if err?

