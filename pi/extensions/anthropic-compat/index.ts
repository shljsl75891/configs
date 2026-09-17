import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// Catalog bug: compat.supportsMidConvoEffort makes the Anthropic request builder
// inject empty `{ role: "system", content: [] }` messages, which the API rejects
// with `400 system content must contain at least one block`. Drop once the
// catalog stops reporting the flag for this model.
const PATCHED_MODEL_ID = "claude-opus-5";

export default function anthropicCompat(pi: ExtensionAPI): void {
  const patch = (_event: unknown, ctx: ExtensionContext): void => {
    for (const model of ctx.modelRegistry.getAll()) {
      // Mutates registry-owned objects, so a frozen entry in a future pi must not
      // break startup or abort the scan before this model.
      try {
        const compat = model.compat;
        if (
          model.id === PATCHED_MODEL_ID &&
          compat &&
          "supportsMidConvoEffort" in compat &&
          compat.supportsMidConvoEffort
        ) {
          compat.supportsMidConvoEffort = false;
        }
      } catch {}
    }
  };

  // Both hooks: session_start misses restored and switched sessions.
  pi.on("session_start", patch);
  pi.on("before_agent_start", patch);
}
