function parse(title) {
  var value = String(title || "").replace(/[\r\n\t]+/g, " ").trim()
  var match = value.match(/^(.+?)\s+(?:-|–|—)\s+(.+)$/)
  if (!match) return null

  var artist = String(match[1] || "").trim()
  var track = String(match[2] || "").trim()
  if (!artist || !track || artist.length > 160 || track.length > 160) return null

  return { artist: artist, track: track }
}
