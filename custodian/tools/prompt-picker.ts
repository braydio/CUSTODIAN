#!/usr/bin/env -S bun
/**
 * prompt-picker.ts - Interactive prompt selector
 * 
 * Lists descriptive names from docs/ai_context/prompts/, 
 * lets user pick one, copies to clipboard via wl-copy.
 */

import { execSync } from "child_process";
import { readdirSync, readFileSync, writeFileSync, unlinkSync } from "fs";
import * as readline from "readline";

const PROMPTS_DIR = "/home/braydenchaffee/Projects/CUSTODIAN/custodian/docs/ai_context/prompts";

const PROMPT_NAMES: Record<string, string> = {
  "review_runtime_change.md":      "Review Runtime Change",
  "scan_git_commit.md":             "Scan Git & Create Commits",
  "inspect_procgen_handoff.md":    "Inspect Procgen Handoff",
  "tune_combat_feel.md":           "Tune Combat Feel",
  "review_docs_drift.md":          "Review Docs Drift",
  "update_sprite_pipeline.md":     "Update Sprite Pipeline",
  "implement_runtime_feature.md": "Implement Runtime Feature",
};

function getFiles(dir: string): string[] {
  return readdirSync(dir).filter(f => f.endsWith(".md") && f !== "README.md");
}

function copyToClipboard(text: string): void {
  try {
    const tmp = "/tmp/prompt-picker-clipboard.txt";
    writeFileSync(tmp, text);
    execSync(`wl-copy < "${tmp}"`, { encoding: "utf8", timeout: 5000 });
    unlinkSync(tmp);
    console.log("✅ Copied to clipboard!\n");
  } catch {
    console.log("⚠️  Copy failed. Showing content:\n");
    console.log(text);
  }
}

function main() {
  console.log("\n📋 CUSTODIAN PROMPT PICKER\n");
  console.log("Choose a prompt by number:\n");

  const files = getFiles(PROMPTS_DIR);

  const items = files.map((file, i) => {
    const name = PROMPT_NAMES[file] || file.replace(".md", "").replace(/_/g, " ");
    return { num: i + 1, file, name };
  });

  items.forEach(item => {
    const pad = item.name.length > 28 ? "  " : "   ";
    console.log(`  ${item.num}${pad}${item.name}`);
  });

  console.log("\n  0    Cancel\n");

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  rl.question("> Enter number: ", (answer) => {
    rl.close();
    const num = parseInt(answer.trim(), 10);

    if (num === 0) {
      console.log("Cancelled.\n");
      return;
    }

    const selected = items.find(i => i.num === num);
    if (!selected) {
      console.log("Invalid selection.\n");
      return;
    }

    const content = readFileSync(`${PROMPTS_DIR}/${selected.file}`, "utf8");
    copyToClipboard(content);
    console.log(`📎 "${selected.name}"`);
    console.log(`   ${selected.file}\n`);
  });
}

main();