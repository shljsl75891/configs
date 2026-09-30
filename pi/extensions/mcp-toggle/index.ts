/**
 * Alt+M: turn MCP servers on and off with the space key.
 * Servers come from ~/.pi/agent/mcp-servers.json and, in a trusted project,
 * .pi/mcp-servers.json. Pi does not read these files, so all servers are off
 * at the start of every session. Changes apply at once and are not saved.
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir, getSettingsListTheme } from "@earendil-works/pi-coding-agent";
import { Box, matchesKey, type SettingItem, SettingsList, visibleWidth } from "@earendil-works/pi-tui";

const FILE = "mcp-servers.json";
const POLL_MS = 300;
const TIMEOUT_MS = 30_000;

function readServers(path: string): Record<string, unknown> {
	let text: string;
	try {
		text = readFileSync(path, "utf8");
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return {};
		throw error;
	}
	return JSON.parse(text).mcpServers ?? {};
}

function loadServers(ctx: ExtensionContext): Record<string, unknown> {
	const project = ctx.isProjectTrusted() ? readServers(join(ctx.cwd, ".pi", FILE)) : {};
	return { ...readServers(join(getAgentDir(), FILE)), ...project };
}

export default function mcpToggle(pi: ExtensionAPI): void {
	const state = new Map<string, "…" | "on">();
	const timers = new Map<string, ReturnType<typeof setInterval>>();
	let view: { list: SettingsList; render: () => void } | undefined;

	const show = (name: string, value: string) => {
		view?.list.updateValue(name, value);
		view?.render();
	};

	const stop = (name: string) => {
		clearInterval(timers.get(name));
		timers.delete(name);
	};

	const hasTools = (name: string) =>
		pi.getAllTools().some((tool) => tool.namespace?.name === `mcp__${name}` && tool.exposure !== "hidden");

	const turnOff = (name: string) => {
		stop(name);
		state.delete(name);
		pi.unregisterMcpServer(name);
	};

	const turnOn = (ctx: ExtensionContext, name: string, config: unknown) => {
		pi.registerMcpServer(name, config as never);
		state.set(name, "…");
		show(name, "…");
		const started = Date.now();
		timers.set(
			name,
			setInterval(() => {
				if (hasTools(name)) {
					stop(name);
					state.set(name, "on");
					show(name, "on");
				} else if (Date.now() - started > TIMEOUT_MS) {
					turnOff(name);
					show(name, "off");
					ctx.ui.notify(`${name}: no tools after ${TIMEOUT_MS / 1000}s, run /mcp for the cause`, "error");
				}
			}, POLL_MS),
		);
	};

	pi.on("session_shutdown", () => {
		for (const name of timers.keys()) stop(name);
		view = undefined;
	});

	pi.registerShortcut("alt+m", {
		description: "Toggle MCP servers",
		handler: async (ctx) => {
			if (view) return;
			let servers: Record<string, unknown>;
			try {
				servers = loadServers(ctx);
			} catch (error) {
				ctx.ui.notify(`${FILE}: ${error instanceof Error ? error.message : error}`, "error");
				return;
			}
			const names = Object.keys(servers).sort();
			if (names.length === 0) {
				ctx.ui.notify(`No servers in ${FILE}`, "warning");
				return;
			}

			try {
			await ctx.ui.custom((tui, theme, _kb, done) => {
				const items: SettingItem[] = names.map((name) => ({
					id: name,
					label: name,
					currentValue: state.get(name) ?? "off",
					values: ["off", "on"],
				}));
				const list = new SettingsList(
					items,
					Math.min(items.length, 10),
					getSettingsListTheme(),
					(name, value) => {
						try {
							if (value === "on") turnOn(ctx, name, servers[name]);
							else turnOff(name);
						} catch (error) {
							show(name, "off");
							ctx.ui.notify(`${name}: ${error instanceof Error ? error.message : error}`, "error");
						}
					},
					() => {
						view = undefined;
						done(undefined);
					},
				);
				view = { list, render: () => tui.requestRender() };
				const container = new Box(2, 1, (text) => theme.bg("userMessageBg", text));
				container.addChild({
					render: (width: number) => {
						const title = theme.fg("accent", theme.bold("MCP servers"));
						return [" ".repeat(Math.max(0, Math.floor((width - visibleWidth(title)) / 2))) + title, ""];
					},
					invalidate: () => {},
				});
				// Drop SettingsList's built-in blank + hint line (last 2 lines).
				container.addChild({
					render: (width: number) => list.render(width).slice(0, -2),
					invalidate: () => list.invalidate(),
				});
				return {
					render: (width: number) => container.render(width),
					invalidate: () => container.invalidate(),
					handleInput: (data: string) => {
						if (matchesKey(data, "alt+m")) {
							done(undefined);
							return;
						}
						list.handleInput(data);
						tui.requestRender();
					},
				};
			}, { overlay: true, overlayOptions: { anchor: "center", width: "35%", maxHeight: "90%" } });
			} finally {
				view = undefined;
			}
		},
	});
}
