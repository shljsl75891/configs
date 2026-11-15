#!/usr/bin/env node
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const {pathToFileURL} = require('node:url');

const USAGE =
  'npx -y -p @mermaid-js/mermaid-cli@11 -p marked@4 node build-pdf.cjs <doc.md>';

/** Chrome cannot start its sandbox on some Linux machines, for example in containers. */
const CHROME_ARGS = ['--no-sandbox'];

const CSS = `
body { font: 10.5pt/1.5 "Liberation Sans", "DejaVu Sans", Arial, sans-serif; color: #1f2328; }
h1 { font-size: 20pt; border-bottom: 1px solid #d0d7de; padding-bottom: .3em; margin-top: 0; }
h2 { font-size: 15pt; border-bottom: 1px solid #d0d7de; padding-bottom: .25em; margin-top: 1.6em; }
h3 { font-size: 12.5pt; margin-top: 1.4em; }
h4 { font-size: 11pt; }
h1, h2, h3, h4 { break-after: avoid; }
table { border-collapse: collapse; width: 100%; font-size: 9pt; margin: .8em 0; }
th, td { border: 1px solid #d0d7de; padding: 4px 7px; vertical-align: top; text-align: left; }
th { background: #f6f8fa; }
tr { break-inside: avoid; }
code { font: 8.8pt/1.4 "DejaVu Sans Mono", "Liberation Mono", monospace; background: #eff1f3; padding: .1em .3em; border-radius: 4px; overflow-wrap: break-word; }
pre { background: #f6f8fa; padding: 10px 12px; border-radius: 6px; white-space: pre-wrap; }
pre code { background: none; padding: 0; }
img { display: block; max-width: 100%; margin: 1em auto; }
a { color: #0969da; text-decoration: none; }
`;

/** npx puts `<cache>/node_modules/.bin` in PATH, but require() does not look there. */
function requireFromNpx(name) {
  const bin = path.join('node_modules', '.bin');
  const caches = process.env.PATH.split(path.delimiter)
    .filter(dir => dir.endsWith(bin))
    .map(dir => path.dirname(path.dirname(dir)));
  if (caches.length === 0) throw new Error(`Run it with npx: ${USAGE}`);
  return require(require.resolve(name, {paths: caches}));
}

async function main(docArg) {
  if (!docArg) throw new Error(`Usage: ${USAGE}`);
  const doc = path.resolve(docArg);
  const pdf = path.join(path.dirname(doc), `${path.parse(doc).name}.pdf`);
  const work = fs.mkdtempSync(path.join(os.tmpdir(), 'build-pdf-'));
  try {
    const puppeteerConfig = path.join(work, 'puppeteer.json');
    fs.writeFileSync(puppeteerConfig, JSON.stringify({args: CHROME_ARGS}));
    const rendered = path.join(work, 'doc.md');
    execFileSync(
      'mmdc',
      ['-i', doc, '-o', rendered, '-e', 'png', '-s', '3', '-b', 'white', '-p', puppeteerConfig],
      {stdio: 'inherit'},
    );

    const md = fs.readFileSync(rendered, 'utf8');
    const title = md.match(/^# (.+)$/m)?.[1] ?? path.parse(doc).name;
    const {marked} = requireFromNpx('marked');
    const html = path.join(work, 'doc.html');
    fs.writeFileSync(
      html,
      `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>${title}</title><style>${CSS}</style></head><body>${marked.parse(md)}</body></html>`,
    );

    const puppeteer = requireFromNpx('puppeteer');
    const browser = await puppeteer.launch({args: CHROME_ARGS});
    try {
      const page = await browser.newPage();
      await page.goto(pathToFileURL(html).href, {waitUntil: 'load'});
      await page.pdf({
        path: pdf,
        format: 'A4',
        margin: {top: '14mm', bottom: '16mm', left: '14mm', right: '14mm'},
        printBackground: true,
        outline: true,
        displayHeaderFooter: true,
        headerTemplate: '<span></span>',
        footerTemplate: `<div style="font: 8px sans-serif; color: #57606a; width: 100%; margin: 0 14mm; display: flex; justify-content: space-between;"><span>${title}</span><span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>`,
      });
    } finally {
      await browser.close();
    }
  } finally {
    fs.rmSync(work, {recursive: true, force: true});
  }
  console.log(`Wrote ${pdf}`);
}

main(process.argv[2]).catch(err => {
  console.error(err.message);
  process.exit(1);
});
