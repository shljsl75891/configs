import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export const AUTO_APPROVE_EVENT = "auto-approve";

/** Subscribes to AUTO_APPROVE_EVENT with the payload already narrowed. */
export function onAutoApproveChange(pi: ExtensionAPI, handler: (enabled: boolean) => void): void {
  pi.events.on(AUTO_APPROVE_EVENT, (data) => handler((data as { enabled: boolean }).enabled));
}
