#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const DESC_MAX = 1024;
const DESC_MIN_RECOMMENDED = 50;
const BODY_LINES_MAX = 500;
const SKIP_SKILLS = new Set(['template-skill']);

function discoverSkills() {
  const categories = fs
    .readdirSync(ROOT, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith('.'));

  const skills = [];
  for (const category of categories) {
    const skillsDir = path.join(ROOT, category.name, 'skills');
    if (!fs.existsSync(skillsDir)) continue;
    if (!fs.statSync(skillsDir).isDirectory()) continue;

    const entries = fs.readdirSync(skillsDir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      if (SKIP_SKILLS.has(entry.name)) continue;

      const skillMd = path.join(skillsDir, entry.name, 'SKILL.md');
      if (!fs.existsSync(skillMd)) continue;

      skills.push({
        category: category.name,
        slug: entry.name,
        file: skillMd,
      });
    }
  }

  return skills.sort((a, b) =>
    `${a.category}/${a.slug}`.localeCompare(`${b.category}/${b.slug}`)
  );
}

function extractFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  if (!match) return null;

  const block = match[1];
  const result = {};
  const lines = block.split(/\r?\n/);

  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    const keyMatch = line.match(/^([a-z-]+):\s*(.*)$/);
    if (!keyMatch) {
      i += 1;
      continue;
    }

    const [, key, rest] = keyMatch;
    const trimmed = rest.trim();
    if (trimmed) {
      result[key] = trimmed.replace(/^["']|["']$/g, '');
      i += 1;
      continue;
    }

    if (line.endsWith('|') || line.endsWith('>')) {
      const scalar = [];
      i += 1;
      while (i < lines.length && (lines[i].startsWith('  ') || lines[i].trim() === '')) {
        scalar.push(lines[i].replace(/^  /, ''));
        i += 1;
      }
      result[key] = scalar.join('\n').trim();
      continue;
    }

    const scalar = [];
    i += 1;
    while (i < lines.length && /^\s/.test(lines[i])) {
      scalar.push(lines[i].replace(/^\s+/, ''));
      i += 1;
    }
    result[key] = scalar.join('\n').trim();
    continue;

  }

  return result;
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

function findBrokenLocalLinks(filePath, content) {
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
      broken.push(rawTarget);
    }
  }

  return broken;
}

function analyzeSkill(skill) {
  const id = `${skill.category}/${skill.slug}`;
  const content = fs.readFileSync(skill.file, 'utf8');
  const warnings = [];
  const errors = [];
  const brokenLinks = findBrokenLocalLinks(skill.file, content);

  const fm = extractFrontmatter(content);
  if (!fm) {
    errors.push('missing or invalid YAML frontmatter');
    return {
      id,
      category: skill.category,
      slug: skill.slug,
      file: path.relative(ROOT, skill.file),
      descChars: 0,
      bodyLines: 0,
      tokenEstimate: 0,
      warnings,
      errors,
      brokenLinks,
      status: 'failing',
    };
  }

  const name = (fm.name || '').trim();
  const description = (fm.description || '').trim();
  if (!name) errors.push('missing frontmatter name');
  if (!description) errors.push('missing frontmatter description');

  if (name && name !== skill.slug) {
    errors.push(`name mismatch (name="${name}" slug="${skill.slug}")`);
  }
  if (name && !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(name)) {
    errors.push('name must match spec pattern: lowercase letters, numbers, hyphens');
  }
  if (description.length > DESC_MAX) {
    errors.push(`description length ${description.length} > ${DESC_MAX}`);
  }

  if (description && description.length < DESC_MIN_RECOMMENDED) {
    warnings.push(`description very short (${description.length} chars)`);
  } else if (description && !/\buse\s+when\b/i.test(description)) {
    warnings.push('description missing "use when" phrasing');
  }

  const body = content.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '');
  const bodyLines = body.split(/\r?\n/).length;
  const tokenEstimate = Math.ceil(body.length / 4);
  if (bodyLines > BODY_LINES_MAX) {
    errors.push(`body lines ${bodyLines} > ${BODY_LINES_MAX}`);
  }

  if (!content.endsWith('\n')) {
    warnings.push('file should end with a single newline');
  } else if (content.endsWith('\n\n')) {
    warnings.push('file has multiple trailing newlines');
  }

  for (const link of brokenLinks) {
    warnings.push(`broken link: ${link}`);
  }

  const status = errors.length > 0 ? 'failing' : warnings.length > 0 ? 'warning' : 'ok';

  return {
    id,
    category: skill.category,
    slug: skill.slug,
    file: path.relative(ROOT, skill.file),
    descChars: description.length,
    bodyLines,
    tokenEstimate,
    warnings,
    errors,
    brokenLinks,
    status,
  };
}

function renderMarkdown(rows, totals, generatedAt) {
  const lines = [];
  lines.push('# Skill Health');
  lines.push('');
  lines.push(`Generated: ${generatedAt}`);
  lines.push('');
  lines.push('## Summary');
  lines.push('');
  lines.push(`- Total skills: ${totals.total}`);
  lines.push(`- OK: ${totals.ok}`);
  lines.push(`- Warning: ${totals.warning}`);
  lines.push(`- Failing: ${totals.failing}`);
  lines.push(`- Total warnings: ${totals.warningCount}`);
  lines.push(`- Total errors: ${totals.errorCount}`);
  lines.push('');
  lines.push('## Per Skill');
  lines.push('');
  lines.push('| Skill | Desc | Body lines | ~Tokens | Status | Warnings | Errors |');
  lines.push('| --- | ---: | ---: | ---: | --- | ---: | ---: |');
  for (const row of rows) {
    lines.push(
      `| ${row.id} | ${row.descChars} | ${row.bodyLines} | ${row.tokenEstimate} | ${row.status} | ${row.warnings.length} | ${row.errors.length} |`
    );
  }

  const failing = rows.filter((row) => row.errors.length > 0);
  if (failing.length > 0) {
    lines.push('');
    lines.push('## Failing Skills');
    lines.push('');
    for (const row of failing) {
      lines.push(`### ${row.id}`);
      lines.push('');
      for (const error of row.errors) {
        lines.push(`- ${error}`);
      }
      lines.push('');
    }
  }

  const broken = rows.filter((row) => row.brokenLinks.length > 0);
  if (broken.length > 0) {
    lines.push('');
    lines.push('## Broken Links');
    lines.push('');
    for (const row of broken) {
      lines.push(`### ${row.id}`);
      lines.push('');
      for (const link of row.brokenLinks) {
        lines.push(`- ${link}`);
      }
      lines.push('');
    }
  }

  return `${lines.join('\n').trimEnd()}\n`;
}

function main() {
  const skills = discoverSkills();
  const rows = skills.map(analyzeSkill);
  const totals = {
    total: rows.length,
    ok: rows.filter((row) => row.status === 'ok').length,
    warning: rows.filter((row) => row.status === 'warning').length,
    failing: rows.filter((row) => row.status === 'failing').length,
    warningCount: rows.reduce((sum, row) => sum + row.warnings.length, 0),
    errorCount: rows.reduce((sum, row) => sum + row.errors.length, 0),
  };

  const generatedAt = new Date().toISOString();
  const report = {
    generatedAt,
    totals,
    skills: rows,
  };

  const reportsDir = path.join(ROOT, 'reports');
  const docsDir = path.join(ROOT, 'docs');
  fs.mkdirSync(reportsDir, { recursive: true });
  fs.mkdirSync(docsDir, { recursive: true });

  const jsonPath = path.join(reportsDir, 'skills-health.json');
  const mdPath = path.join(docsDir, 'SKILL-HEALTH.md');
  fs.writeFileSync(jsonPath, `${JSON.stringify(report, null, 2)}\n`);
  fs.writeFileSync(mdPath, renderMarkdown(rows, totals, generatedAt));

  console.log(`Wrote ${path.relative(ROOT, jsonPath)}`);
  console.log(`Wrote ${path.relative(ROOT, mdPath)}`);
}

main();
