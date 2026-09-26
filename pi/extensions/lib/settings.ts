/**
 * Reads one top-level key from ~/.pi/agent/settings.json (path from
 * getAgentDir(); PI_CODING_AGENT_DIR overrides it). Re-read on every call,
 * not cached: settings.json is meant to be editable mid-session and take
 * effect on the next read. Returns `unknown`; callers must narrow it.
 * A missing file returns undefined; bad JSON throws instead of silently
 * dropping every rule callers rely on (see permission/index.ts's use of this).
 */
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

export function readAgentSetting(key: string): unknown {
  const file = join(getAgentDir(), "settings.json");
  if (!existsSync(file)) return undefined;
  return JSON.parse(readFileSync(file, "utf8"))[key];
}
