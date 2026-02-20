#!/usr/bin/env node
/**
 * Validate all skills in agent-forge against Agent Skills spec + token limits + formatting.
 * Run from repo root: node scripts/validate-skills.mjs [--no-strict] [--lenient] [--report[=json|csv]]
 *
 * Checks (strict by default):
 *   - SKILL.md exists and has YAML frontmatter with name + description
 *   - name matches directory (lowercase, hyphens) unless --lenient
 *   - description length <= 1024 (spec max)
 *   - body <= 500 lines (skills in skills-strict-allowlist.txt allowed until refactored)
 *   - frontmatter: name appears before description (field order)
 *   - file ends with a single newline
 *
 * Warnings (do not fail exit code):
 *   - description very short (< 50 chars) or missing "use when" phrasing
 *   - broken links to references/*.md (linked file missing)
 *
 * --no-strict  Skip body line limit; validate only name, description, and name-vs-dir.
 * --lenient   Skip name-vs-directory match.
 *
 * --report       Print structural metrics per skill.
 * --report=json  Same metrics as JSON array.
 * --report=csv   Same metrics as CSV.
 *
 * Exit 0 if all pass, 1 otherwise. Warnings are printed but do not set exit code to 1.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const FORGE_ROOT = path.resolve(__dirname, '..');
const SKIP_SKILLS = new Set(['template-skill']);
const ALLOWLIST_PATH = path.join(__dirname, 'skills-strict-allowlist.txt');
const DESC_MAX = 1024;
const BODY_LINES_MAX = 500;
const DESC_MIN_RECOMMENDED = 50;

function discoverSkills() {
  const skills = [];
  const categories = fs.readdirSync(FORGE_ROOT, { withFileTypes: true })
    .filter(d => d.isDirectory() && !d.name.startsWith('.'));
  for (const cat of categories) {
    const skillsDir = path.join(FORGE_ROOT, cat.name, 'skills');
    if (!fs.existsSync(skillsDir) || !fs.statSync(skillsDir).isDirectory()) continue;
    const entries = fs.readdirSync(skillsDir, { withFileTypes: true });
    for (const ent of entries) {
      if (!ent.isDirectory()) continue;
      const skillMd = path.join(skillsDir, ent.name, 'SKILL.md');
      if (!fs.existsSync(skillMd)) continue;
      if (SKIP_SKILLS.has(ent.name)) continue;
      skills.push({ category: cat.name, name: ent.name, path: skillMd, skillDir: path.dirname(skillMd) });
    }
  }
  return skills;
}

function loadStrictAllowlist() {
  if (!fs.existsSync(ALLOWLIST_PATH)) return new Set();
  const text = fs.readFileSync(ALLOWLIST_PATH, 'utf8');
  return new Set(
    text.split(/\n/).map(s => s.replace(/#.*/, '').trim()).filter(Boolean)
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
    if (keyMatch) {
      const [, key, rest] = keyMatch;
      const trimmed = rest.trim();
      if (trimmed) {
        result[key] = trimmed;
      } else if (line.endsWith('|') || line.endsWith('>')) {
        const scalar = [];
        i++;
        while (i < lines.length && (lines[i].startsWith('  ') || lines[i].trim() === '')) {
          scalar.push(lines[i].replace(/^  /, ''));
          i++;
        }
        result[key] = scalar.join('\n').trim();
        continue;
      } else {
        const scalar = [];
        i++;
        while (i < lines.length && /^\s/.test(lines[i])) {
          scalar.push(lines[i].replace(/^\s+/, ''));
          i++;
        }
        result[key] = scalar.join('\n').trim();
        continue;
      }
    }
    i++;
  }
  return result;
}

function getFrontmatterRaw(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  return match ? match[1] : null;
}

function validateSkill(skill, strict, strictAllowlist) {
  const errors = [];
  const warnings = [];
  const content = fs.readFileSync(skill.path, 'utf8');
  const fm = extractFrontmatter(content);
  if (!fm) {
    errors.push('missing or invalid YAML frontmatter (--- ... ---)');
    return { errors, warnings };
  }
  if (!fm.name) errors.push('missing frontmatter "name"');
  if (!fm.description) errors.push('missing frontmatter "description"');
  const nameNorm = fm.name ? fm.name.replace(/^["']|["']$/g, '').trim() : '';
  const lenient = process.argv.includes('--lenient');
  if (!lenient && fm.name && nameNorm !== skill.name) {
    errors.push(`name "${fm.name}" does not match directory "${skill.name}" (spec: must match)`);
  }
  if (fm.name && !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(nameNorm)) {
    errors.push('name must be lowercase letters, numbers, hyphens only (spec)');
  }
  if (fm.description) {
    if (fm.description.length > DESC_MAX) {
      errors.push(`description length ${fm.description.length} > ${DESC_MAX} (spec max)`);
    }
    if (fm.description.length < DESC_MIN_RECOMMENDED) {
      warnings.push(`description very short (${fm.description.length} chars); consider adding "Use when..." for better matching`);
    } else if (!/\buse\s+when\b/i.test(fm.description)) {
      warnings.push('description does not contain "use when"; consider adding when-to-use phrasing for better matching');
    }
  }
  if (strict) {
    const afterFrontmatter = content.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '');
    const bodyLines = afterFrontmatter.split(/\r?\n/).length;
    if (bodyLines > BODY_LINES_MAX) {
      const key = `${skill.category}/${skill.name}`;
      if (!strictAllowlist.has(key)) {
        errors.push(`body lines ${bodyLines} > ${BODY_LINES_MAX} (move content to references/ or add to ${path.basename(ALLOWLIST_PATH)})`);
      }
    }
  }
  // Frontmatter field order: name should appear before description
  const rawFm = getFrontmatterRaw(content);
  if (rawFm) {
    const nameIdx = rawFm.indexOf('name:');
    const descIdx = rawFm.indexOf('description:');
    if (nameIdx !== -1 && descIdx !== -1 && descIdx < nameIdx) {
      errors.push('frontmatter: "description" should appear after "name" (recommended order: name, description)');
    }
  }
  // File should end with a single newline
  if (content.length > 0 && !content.endsWith('\n')) {
    warnings.push('file should end with a single newline');
  } else if (content.endsWith('\n\n')) {
    warnings.push('file has multiple trailing newlines; use a single newline at end');
  }
  // Broken links to references/*.md
  const refLinkRegex = /\]\s*\(\s*references\/([^)\s]+)\s*\)/g;
  let refMatch;
  while ((refMatch = refLinkRegex.exec(content)) !== null) {
    const refPath = path.join(skill.skillDir, 'references', refMatch[1]);
    if (!fs.existsSync(refPath)) {
      warnings.push(`broken link: references/${refMatch[1]} does not exist`);
    }
  }
  return { errors, warnings };
}

function getSkillReport(skill) {
  const id = `${skill.category}/${skill.name}`;
  let content;
  try {
    content = fs.readFileSync(skill.path, 'utf8');
  } catch {
    return { id, descChars: 0, bodyLines: 0, bodyChars: 0, tokenEstimate: 0, status: 'ERROR' };
  }
  const fm = extractFrontmatter(content);
  if (!fm || !fm.description) {
    return { id, descChars: 0, bodyLines: 0, bodyChars: 0, tokenEstimate: 0, status: 'ERROR' };
  }
  const afterFrontmatter = content.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '');
  const bodyLines = afterFrontmatter.split(/\r?\n/).length;
  const bodyChars = afterFrontmatter.length;
  const tokenEstimate = Math.ceil(bodyChars / 4);
  let status = 'OK';
  if (fm.description.length > DESC_MAX || bodyLines > BODY_LINES_MAX || tokenEstimate > 5000) status = 'OVER';
  return { id, descChars: fm.description.length, bodyLines, bodyChars, tokenEstimate, status };
}

function parseReportArg() {
  const arg = process.argv.find(a => a.startsWith('--report'));
  if (!arg) return null;
  if (arg === '--report') return 'text';
  const eq = arg.indexOf('=');
  if (eq !== -1) return arg.slice(eq + 1); // json or csv
  return 'text';
}

function main() {
  const strict = !process.argv.includes('--no-strict');
  const lenient = process.argv.includes('--lenient');
  const reportFormat = parseReportArg();
  const strictAllowlist = loadStrictAllowlist();
  const skills = discoverSkills();
  let failed = 0;
  let warnCount = 0;
  for (const skill of skills) {
    const { errors, warnings } = validateSkill(skill, strict, strictAllowlist);
    if (errors.length) {
      failed++;
      console.error(`${skill.category}/skills/${skill.name}:`);
      errors.forEach(e => console.error(`  - ${e}`));
    }
    if (warnings.length) {
      warnCount += warnings.length;
      console.error(`${skill.category}/skills/${skill.name}:`);
      warnings.forEach(w => console.error(`  warn: ${w}`));
    }
  }
  if (warnCount) {
    console.error(`\n(${warnCount} warning(s) — fix for consistency; they do not fail validation)`);
  }
  if (failed) {
    console.error(`\n${failed} skill(s) failed validation. Fix the above and re-run.`);
    process.exit(1);
  }
  if (reportFormat) {
    const rows = skills.map(getSkillReport);
    if (reportFormat === 'json') {
      console.log(JSON.stringify(rows, null, 0));
    } else if (reportFormat === 'csv') {
      console.log('id,descChars,bodyLines,bodyChars,tokenEstimate,status');
      for (const r of rows) {
        console.log(`${r.id},${r.descChars},${r.bodyLines},${r.bodyChars},${r.tokenEstimate},${r.status}`);
      }
    } else {
      for (const r of rows) {
        const over = r.status === 'OVER' ? 'OVER' : 'OK';
        console.log(`${r.id}  desc=${r.descChars}  body=${r.bodyLines}L  ~${r.tokenEstimate} tokens  [${over}]`);
      }
    }
  }
  const opts = [!strict && 'basic only', lenient && 'name vs dir skipped', reportFormat && 'report'].filter(Boolean);
  console.log(`Validated ${skills.length} skill(s).${opts.length ? ` (${opts.join(', ')})` : ' (strict: body ≤500)'}`);
}

main();
