import { readFile, writeFile, realpath, stat } from "node:fs/promises";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { TextDecoder } from "node:util";
import { format } from "prettier/standalone";
import * as markdown from "prettier/plugins/markdown";

export function decode(bytes) {
  if (bytes[0] === 0xff && bytes[1] === 0xfe) {
    return new TextDecoder("utf-16le", { fatal: true }).decode(bytes);
  }
  if (bytes[0] === 0xfe && bytes[1] === 0xff) {
    return new TextDecoder("utf-16be", { fatal: true }).decode(bytes);
  }
  // Reject invalid UTF-8 instead of silently replacing source characters.
  return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
}

export async function formatMarkdown(text) {
  return format(text, {
    parser: "markdown",
    plugins: [markdown],
    proseWrap: "never",
    endOfLine: "lf",
    tabWidth: 2,
    embeddedLanguageFormatting: "off",
  });
}

export async function formatFile(source, destination) {
  const sourcePath = await realpath(source);
  let destinationPath = resolve(destination);
  try {
    destinationPath = await realpath(destination);
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  const normalize = (path) => process.platform === "win32" ? path.toLowerCase() : path;
  if (normalize(sourcePath) === normalize(destinationPath)) {
    throw new Error("Input and output must be different files.");
  }
  try {
    const [inputStat, outputStat] = await Promise.all([stat(sourcePath), stat(destinationPath)]);
    if (inputStat.dev === outputStat.dev && inputStat.ino === outputStat.ino) {
      throw new Error("Input and output must be different files.");
    }
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  const result = await formatMarkdown(decode(await readFile(sourcePath)));
  // BOM makes the temporary file unambiguously UTF-8 to WinMerge.
  await writeFile(destinationPath, "\ufeff" + result, "utf8");
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    if (process.argv.length !== 4) throw new Error("Usage: node format.mjs INPUT OUTPUT");
    await formatFile(process.argv[2], process.argv[3]);
  } catch (error) {
    console.error(`MarkdownFormat: ${error.message}`);
    process.exitCode = 1;
  }
}
