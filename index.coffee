# Image Shrink
# Copyright(c) Matias Meno 2012
#
# Image shrink is connect middleware to resize images

module.exports = (options) ->
  shrink = require("./lib/shrink")(options)
  (req, res, next) ->
    if shrink.accepts(req) then shrink.handle req, res, next
    else next()
