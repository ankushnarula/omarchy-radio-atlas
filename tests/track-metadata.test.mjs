import assert from "node:assert/strict"
import fs from "node:fs"
import path from "node:path"
import vm from "node:vm"
import { fileURLToPath } from "node:url"

const projectDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..")
const context = {}
vm.runInNewContext(fs.readFileSync(path.join(projectDir, "TrackMetadata.js"), "utf8"), context)

function expectTrack(title, artist, track) {
  const parsed = context.parse(title)
  assert.equal(parsed?.artist, artist)
  assert.equal(parsed?.track, track)
}

expectTrack("Artist - Track", "Artist", "Track")
expectTrack("Artist – Track", "Artist", "Track")
expectTrack("Artist — Track", "Artist", "Track")
expectTrack("Proem - Untitled - Brothomstates Remix", "Proem", "Untitled - Brothomstates Remix")
expectTrack("  Artist - Track\n", "Artist", "Track")

assert.equal(context.parse("Station title without a separator"), null)
assert.equal(context.parse("Artist-Track"), null)
assert.equal(context.parse(`Artist - ${"x".repeat(161)}`), null)

console.log("TrackMetadata tests passed")
