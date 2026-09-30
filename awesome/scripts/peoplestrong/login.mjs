#!/usr/bin/env node
/**
 * Gets a PeopleStrong API session token with headless Brave and prints it.
 * Exits 1 when the sign-in needs the user. With `--headed` the Brave window is
 * visible, so the user can finish the sign-in; the run then waits for 5 minutes.
 *
 * The user's own Brave (Work profile) holds the Google sign-in. Brave locks its
 * data folder and ignores the debugging port there, so each run starts on a
 * copy of the cookies. Both use the system keyring, so the copy can read them.
 */
import { spawn } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync } from "node:fs";
import { once } from "node:events";
import { homedir } from "node:os";
import { setTimeout as timeout } from "node:timers/promises";

/** A crashed or killed browser has a signal code and no exit code. */
const hasExited = (chrome) => chrome.exitCode !== null || chrome.signalCode !== null;

/** Unref'd, so a timer that lost a race cannot keep the process alive. */
const sleep = (ms) => timeout(ms, undefined, { ref: false });

const CHROME = process.env.PUNCH_BROWSER ?? "/opt/brave.com/brave-origin/brave";
const SOURCE_DIR = `${homedir()}/.config/BraveSoftware/Brave-Origin`;
const PROFILE_NAME = "Profile 2";
const PROFILE = `${homedir()}/.local/share/punch/brave-profile`;
const HOME_URL = "https://sourcefuse.peoplestrong.com/oneweb/#/home";
const API_HOST = "https://onewebapi.peoplestrong.com/";
const HEADLESS_TIMEOUT_MS = 60_000;
const HEADED_TIMEOUT_MS = 5 * 60_000;
const POLL_INTERVAL_MS = 3000;
const REQUEST_TIMEOUT_MS = 5000;

/**
 * Without an app session the site shows an HTML login page. The Flutter app
 * can show its own login page on a canvas; turning on Flutter's accessibility
 * tree gives that button a DOM node that accepts a click.
 */
const CLICK_GOOGLE_LOGIN = `(() => {
	document.querySelector("flt-semantics-placeholder")?.click();
	[...document.querySelectorAll("a, button, flt-semantics")]
		.find((e) => e.textContent.trim() === "Login via Google")
		?.click();
})()`;

async function connect(url) {
	const ws = new WebSocket(url);
	const pending = new Map();
	const handlers = new Map();
	let lastId = 0;
	ws.onmessage = ({ data }) => {
		const msg = JSON.parse(data);
		if (msg.id) {
			const request = pending.get(msg.id);
			pending.delete(msg.id);
			if (msg.error) request?.reject(new Error(msg.error.message));
			else request?.resolve(msg.result);
		} else {
			handlers.get(msg.method)?.(msg.params);
		}
	};
	// Chrome may die mid-call; without this, awaited requests would hang forever.
	ws.onclose = () => {
		for (const { reject } of pending.values()) reject(new Error("DevTools connection closed"));
		pending.clear();
	};
	await Promise.race([
		new Promise((resolve, reject) => {
			ws.onopen = resolve;
			ws.onerror = () => reject(new Error(`Cannot connect to ${url}`));
		}),
		sleep(REQUEST_TIMEOUT_MS).then(() => {
			throw new Error(`Timed out connecting to ${url}`);
		}),
	]);
	return {
		send(method, params = {}) {
			// ws.send on a closed socket does not throw, and onclose has already run.
			if (ws.readyState !== WebSocket.OPEN) return Promise.reject(new Error("DevTools connection closed"));
			const id = ++lastId;
			ws.send(JSON.stringify({ id, method, params }));
			return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
		},
		on: (method, handler) => handlers.set(method, handler),
	};
}

async function debuggerPort(chrome) {
	const file = `${PROFILE}/DevToolsActivePort`;
	while (!hasExited(chrome)) {
		// Chrome may still be writing the file; wait for a complete port number.
		const port = existsSync(file) ? readFileSync(file, "utf8").split("\n")[0] : "";
		if (/^\d+$/.test(port)) return port;
		await sleep(200);
	}
	throw new Error(`Chrome exited with ${chrome.exitCode ?? chrome.signalCode}`);
}

/** Starts every run from the cookies of the user's own Brave, so its sign-in is always current. */
function copyCookies() {
	const target = `${PROFILE}/${PROFILE_NAME}`;
	rmSync(PROFILE, { recursive: true, force: true });
	mkdirSync(target, { recursive: true, mode: 0o700 });
	copyFileSync(`${SOURCE_DIR}/Local State`, `${PROFILE}/Local State`);
	for (const file of ["Cookies", "Cookies-journal"]) {
		// The journal only exists while Brave is writing.
		if (existsSync(`${SOURCE_DIR}/${PROFILE_NAME}/${file}`)) copyFileSync(`${SOURCE_DIR}/${PROFILE_NAME}/${file}`, `${target}/${file}`);
	}
}

/** Resolves with the token, or null when the time runs out. */
async function login(headless, timeoutMs) {
	copyCookies();
	rmSync(`${PROFILE}/DevToolsActivePort`, { force: true });
	// The debugging port is open to every local user while Chrome runs; this is a single-user machine.
	const chrome = spawn(
		CHROME,
		[
			`--user-data-dir=${PROFILE}`,
			`--profile-directory=${PROFILE_NAME}`,
			"--no-first-run",
			"--remote-debugging-port=0",
			...(headless ? ["--headless=new"] : []),
			"--window-size=1000,1100",
			"about:blank",
		],
		{ stdio: "ignore" },
	);
	// A missing browser binary is an 'error' event; without a handler it would crash with exit 1: "sign in needed".
	chrome.once("error", (error) => {
		console.error(error);
		process.exit(2);
	});
	// `timeout` in mark-attendance sends SIGTERM when a run hangs; do not leave Chrome holding the profile.
	process.once("SIGTERM", () => {
		chrome.kill();
		process.exit(124);
	});
	let port;
	try {
		port = await debuggerPort(chrome);
		const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`, { signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) })).json();
		const cdp = await connect(targets.find((t) => t.type === "page").webSocketDebuggerUrl);

		/**
		 * The app sends the token in the `sessiontoken` header of every API call.
		 * Only a 200 answer proves the token is valid, not a stale stored one.
		 */
		const sentTokens = new Map();
		const token = new Promise((resolve) => {
			cdp.on("Network.requestWillBeSent", ({ requestId, request }) => {
				const sent = request.headers.sessiontoken;
				if (request.url.startsWith(API_HOST) && sent) sentTokens.set(requestId, sent);
			});
			cdp.on("Network.responseReceived", ({ requestId, response }) => {
				if (response.status === 200 && sentTokens.has(requestId)) resolve(sentTokens.get(requestId));
			});
		});
		await cdp.send("Network.enable");
		await cdp.send("Page.navigate", { url: HOME_URL });

		const deadline = Date.now() + timeoutMs;
		while (Date.now() < deadline && !hasExited(chrome)) {
			const result = await Promise.race([token, sleep(POLL_INTERVAL_MS)]);
			if (result) return result;
			await cdp.send("Runtime.evaluate", { expression: CLICK_GOOGLE_LOGIN }).catch(() => {
				// The page may be in the middle of a navigation; try again next round.
			});
		}
		return null;
	} finally {
		if (!hasExited(chrome)) {
			/*
			 * A signal skips the cookie flush, so Google forgets the sign-in, and
			 * Chrome reopens the old tabs. Browser.close shuts down cleanly.
			 */
			const exited = once(chrome, "exit");
			try {
				const { webSocketDebuggerUrl } = await (await fetch(`http://127.0.0.1:${port}/json/version`, { signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) })).json();
				// No await: Chrome may exit before it answers.
				(await connect(webSocketDebuggerUrl)).send("Browser.close").catch(() => {});
			} catch {
				chrome.kill();
			}
			// The next Chrome cannot use the profile until this one releases its lock.
			await Promise.race([exited, sleep(10_000).then(() => chrome.kill())]);
			await exited;
		}
	}
}

/* Exit 1 means the user must sign in; exit 2 means this script or Chrome broke. */
const headed = process.argv[2] === "--headed";
const token = await login(!headed, headed ? HEADED_TIMEOUT_MS : HEADLESS_TIMEOUT_MS).catch((error) => {
	console.error(error);
	process.exit(2);
});
if (!token) {
	console.error("PeopleStrong sign-in needs the user");
	process.exit(1);
}
process.stdout.write(token);
