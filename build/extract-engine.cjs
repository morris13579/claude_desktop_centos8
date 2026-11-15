// Read the bundled manifest, not conversation data. Fail closed if upstream changes format.
const fs = require('fs');
const input = fs.readFileSync(process.argv[2], 'utf8');
const pattern = /JSON\.parse\('(\{"version":"\d+\.\d+\.\d+","manifest":\{"version":"\d+\.\d+\.\d+"[^']*"baseUrl":"https:\/\/downloads\.claude\.ai\/claude-code-releases"[^']*\})'\)/g;
const records = [];
for (const match of input.matchAll(pattern)) {
  const data = JSON.parse(match[1]);
  const artifact = data.manifest?.platforms?.['linux-x64'];
  if (data.version !== data.manifest?.version || artifact?.binary !== 'claude.zst' || !/^[a-f0-9]{64}$/.test(artifact?.checksum ?? '')) continue;
  records.push(`${data.version} ${artifact.checksum}`);
}
const unique = [...new Set(records)];
if (unique.length !== 1) throw new Error(`Expected exactly one Claude Code manifest, found ${unique.length}; upstream layout may have changed`);
console.log(unique[0]);
