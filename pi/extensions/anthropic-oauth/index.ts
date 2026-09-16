/**
 * Claude Max OAuth helper for pi.
 *
 * Pi already supports `/login anthropic` → Claude Pro/Max. That path still
 * fingerprints as a third-party harness, so Anthropic bills extra usage
 * instead of the Max plan. This extension:
 *
 * 1. Sanitizes pi fingerprints out of the system prompt / request payload
 * 2. Upgrades prompt cache markers to 1h
 * 3. Zeros displayed token cost for OAuth turns
 *
 * Login with: `/login anthropic` → "Sign in with an account"
 *
 * WARNING: This tries to make a third-party harness look like Claude Code.
 * Anthropic may still detect it, and using a subscription this way may
 * violate Anthropic's terms. Use your own judgment.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
	isAnthropicOAuthKey,
	sanitizeAnthropicPayload,
	sanitizeSystemText,
} from "./sanitize.ts";

function isAnthropicOAuth(ctx: ExtensionContext): boolean {
	const model = ctx.model;
	if (!model || model.provider !== "anthropic") return false;
	return ctx.modelRegistry.isUsingOAuth(model);
}

function updateStatus(ctx: ExtensionContext): void {
	if (!ctx.hasUI) return;
	ctx.ui.setStatus("anthropic-oauth", isAnthropicOAuth(ctx) ? "Claude Max" : undefined);
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		updateStatus(ctx);
	});

	pi.on("model_select", async (_event, ctx) => {
		updateStatus(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		if (ctx.hasUI) ctx.ui.setStatus("anthropic-oauth", undefined);
	});

	pi.on("before_agent_start", (event, ctx) => {
		if (!isAnthropicOAuth(ctx)) return;
		const next = sanitizeSystemText(event.systemPrompt);
		if (next === event.systemPrompt) return;
		return { systemPrompt: next };
	});

	pi.on("before_provider_request", (event, ctx) => {
		if (!isAnthropicOAuth(ctx)) return;
		return sanitizeAnthropicPayload(event.payload);
	});

	pi.on("message_end", (event, ctx) => {
		const message = event.message;
		if (message.role !== "assistant") return;
		if (message.provider !== "anthropic") return;
		if (!isAnthropicOAuth(ctx)) return;

		return {
			message: {
				...message,
				usage: {
					...message.usage,
					cost: {
						input: 0,
						output: 0,
						cacheRead: 0,
						cacheWrite: 0,
						total: 0,
					},
				},
			},
		};
	});

	pi.registerCommand("max-status", {
		description: "Show Claude Max OAuth status for the current session",
		handler: async (_args, ctx) => {
			const model = ctx.model;
			const oauth = isAnthropicOAuth(ctx);
			const auth = await ctx.modelRegistry.getProviderAuth("anthropic").catch(
				() => undefined,
			);
			const storedOAuth = isAnthropicOAuthKey(auth?.auth.apiKey);
			const lines = [
				`model: ${model ? `${model.provider}/${model.id}` : "(none)"}`,
				`active anthropic oauth: ${oauth ? "yes" : "no"}`,
				`stored anthropic oauth: ${storedOAuth ? "yes" : "no"}`,
				`auth source: ${auth?.source ?? "(none)"}`,
			];
			if (!oauth) {
				lines.push(
					"",
					"To use your Claude Max plan: /login anthropic → Sign in with an account",
					"Then /model and pick an anthropic/* model.",
				);
			}
			ctx.ui.notify(lines.join("\n"), oauth ? "info" : "warning");
		},
	});
}
