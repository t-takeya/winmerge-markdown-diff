import test from "node:test";
import assert from "node:assert/strict";
import { readFile, writeFile, mkdtemp, rm, link } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { decode, formatMarkdown, formatFile } from "../src/format.mjs";

test("formatting-only changes compare equal; content changes remain", async () => {
  const files = await Promise.all(["left", "right", "changed"].map(async name =>
    formatMarkdown(await readFile(new URL(`../examples/${name}.md`, import.meta.url), "utf8"))));
  assert.equal(files[0], files[1]);
  assert.notEqual(files[0], files[2]);
  assert.equal(await formatMarkdown(files[0]), files[0]);
});

test("code and Markdown hard breaks retain their meaning", async () => {
  const code = '```js\nconst x={a:1};\n  // keep indentation\n```\n';
  assert.equal(await formatMarkdown(code), code);
  const hardBreak = await formatMarkdown("first  \nsecond\n");
  assert.notEqual(hardBreak, await formatMarkdown("first\nsecond\n"));
  assert.match(await formatMarkdown("- [x] 完了\n- [ ] 未完了\n"), /\[x\] 完了/);
});

test("Unicode BOMs decode correctly and corrupt UTF-8 fails", () => {
  const text = "# 日本語\n";
  assert.equal(decode(Buffer.from("\ufeff" + text)), text);
  assert.equal(decode(Buffer.from("\ufeff" + text, "utf16le")), text);
  const bigEndian = Buffer.from("\ufeff" + text, "utf16le").swap16();
  assert.equal(decode(bigEndian), text);
  assert.throws(() => decode(Buffer.from([0xff, 0x80])));
});

test("CLI handles spaces and Japanese paths without modifying input", async () => {
  const dir = await mkdtemp(join(tmpdir(), "markdown 日本語 & "));
  try {
    const source = join(dir, "入力 file.md");
    const output = join(dir, "比較 file.md");
    const original = Buffer.from("# 日本語\r\n\r\n* 項目\r\n");
    await writeFile(source, original);
    const result = spawnSync(process.execPath, ["src/format.mjs", source, output], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(await readFile(source), original);
    assert.equal((await readFile(output, "utf8")), "\ufeff# 日本語\n\n- 項目\n");
    await assert.rejects(formatFile(source, source), /different files/);
    const alias = join(dir, "alias.md");
    await link(source, alias);
    await assert.rejects(formatFile(source, alias), /different files/);
    const invalid = join(dir, "invalid.md");
    await writeFile(invalid, Buffer.from([0xff, 0x80]));
    const failure = spawnSync(process.execPath, ["src/format.mjs", invalid, output], { encoding: "utf8" });
    assert.equal(failure.status, 1);
    assert.match(failure.stderr, /MarkdownFormat/);
    assert.equal(await readFile(output, "utf8"), "\ufeff# 日本語\n\n- 項目\n");
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
