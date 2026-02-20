#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const EXCLUDED_DIRS = new Set([
  '.git',
  'node_modules',
  '.next',
  'dist',
  'build',
  'out',
  '.cache',
]);

function walkMarkdownFiles(dir, out = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.isDirectory()) {
      if (EXCLUDED_DIRS.has(entry.name)) continue;
      walkMarkdownFiles(path.join(dir, entry.name), out);
      continue;
    }
    if (!entry.isFile()) continue;
    if (!entry.name.toLowerCase().endsWith('.md')) continue;
    out.push(path.join(dir, entry.name));
  }
  return out;
}

function stripCodeFences(markdown) {
  return markdown
    .replace(/```[\s\S]*?```/g, '')
    .replace(/~~~[\s\S]*?~~~/g, '');
}

function normalizeTarget(rawTarget) {
  let target = rawTarget.trim();
  if (!target) return '';

  if (target.startsWith('<') && target.endsWith('>')) {
    target = target.slice(1, -1).trim();
  }

  const titleMatch = target.match(/^(\S+)\s+["'(].*$/);
  if (titleMatch) {
    target = titleMatch[1];
  }

  target = target.replace(/^['"]|['"]$/g, '').trim();
  return target;
}

function isExternalTarget(target) {
  return /^(https?:|mailto:|tel:|data:|javascript:)/i.test(target);
}

function findBrokenLinks(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const text = stripCodeFences(content);
  const re = /\[[^\]]*]\(([^)]+)\)/g;
  const broken = [];
  let match;

  while ((match = re.exec(text)) !== null) {
    const rawTarget = match[1];
    let target = normalizeTarget(rawTarget);
    if (!target) continue;

    if (target.startsWith('#')) continue;
    if (target.startsWith('/')) continue;
    if (isExternalTarget(target)) continue;
    if (target.includes('{') || target.includes('}')) continue;

    target = target.split('#')[0].split('?')[0].trim();
    if (!target) continue;

    const resolved = path.resolve(path.dirname(filePath), target);
    if (!fs.existsSync(resolved)) {
      broken.push({
        file: path.relative(ROOT, filePath),
        link: rawTarget,
      });
    }
  }

  return broken;
}

function main() {
  const files = walkMarkdownFiles(ROOT).sort();
  const broken = [];

  for (const file of files) {
    broken.push(...findBrokenLinks(file));
  }

  if (broken.length > 0) {
    console.error('Broken local markdown links found:\n');
    for (const issue of broken) {
      console.error(`- ${issue.file} -> ${issue.link}`);
    }
    console.error(`\nFound ${broken.length} broken link(s) across ${files.length} markdown files.`);
    process.exit(1);
  }

  console.log(`Checked ${files.length} markdown files. No broken local links found.`);
}

main();
