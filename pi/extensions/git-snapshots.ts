/**
 * Git Snapshots
 *
 * Snapshots the worktree into shadow git refs at every turn, and restores the
 * matching snapshot when you move the session leaf with /tree. Moving back to
 * an older prompt therefore also reverts the files that prompt changed; moving
 * forward again re-applies them (redo).
 *
 * Storage: refs/pi-snapshots/<sessionId>/<entryId> -> commit made with
 * commit-tree from a temporary index. Your index, HEAD and stash are never
 * touched. Snapshots respect .gitignore. No-op outside a git repo.
 *
 * Known limitation: restoring removes files added since the snapshot but leaves
 * the directories that held them behind.
 */

import { execFile, spawn } from "node:child_process";
import { copyFile, mkdtemp, rm, unlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const execFileAsync = promisify(execFile);

const REF_ROOT = "refs/pi-snapshots";
const ROOT_KEY = "root";
const PRUNE_DAYS = 14;
const SECONDS_PER_DAY = 86_400;
const MAX_SUMMARY_LINES = 12;
const MAX_BUFFER = 64 * 1024 * 1024;

type Env = Record<string, string>;

const childEnv = (env?: Env) => (env ? { ...process.env, ...env } : process.env);

interface State {
	repoRoot: string;
	sessionId: string;
}

async function git(cwd: string, args: string[], env?: Env): Promise<string> {
	const { stdout } = await execFileAsync("git", args, {
		cwd,
		env: childEnv(env),
		maxBuffer: MAX_BUFFER,
	});
	return stdout.trim();
}

/** git call fed from stdin, which has no argv length limit. */
async function gitStdin(cwd: string, args: string[], input: string, env?: Env): Promise<void> {
	await new Promise<void>((done, fail) => {
		const child = spawn("git", args, {
			cwd,
			env: childEnv(env),
			stdio: ["pipe", "ignore", "pipe"],
		});
		let stderr = "";
		child.stderr.setEncoding("utf8");
		child.stderr.on("data", (chunk: string) => {
			stderr += chunk;
		});
		child.on("error", fail);
		child.on("close", (code) =>
			code === 0 ? done() : fail(new Error(`git ${args[0]} failed: ${stderr.trim()}`)),
		);
		child.stdin.end(input);
	});
}

/** git call whose failure is an expected answer ("no such ref", "not a repo"). */
async function gitOrNull(cwd: string, args: string[], env?: Env): Promise<string | undefined> {
	try {
		return await git(cwd, args, env);
	} catch {
		return undefined;
	}
}

/**
 * Run `fn` against a private index seeded from the real one. The copy keeps
 * git's stat cache, so `add -A` only rehashes files that actually changed
 * instead of the whole worktree; writes land in the copy, never in .git/index.
 */
async function withTempIndex<T>(repoRoot: string, fn: (env: Env) => Promise<T>): Promise<T> {
	const dir = await mkdtemp(join(tmpdir(), "pi-snapshot-"));
	const indexFile = join(dir, "index");
	const realIndex = await gitOrNull(repoRoot, ["rev-parse", "--git-path", "index"]);
	if (realIndex) await copyFile(resolve(repoRoot, realIndex), indexFile).catch(() => {});
	try {
		return await fn({ GIT_INDEX_FILE: indexFile });
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
}

/** Tree of the current worktree: tracked + untracked, minus ignored. */
async function writeTree(repoRoot: string): Promise<string> {
	return withTempIndex(repoRoot, async (env) => {
		await git(repoRoot, ["add", "-A"], env);
		return git(repoRoot, ["write-tree"], env);
	});
}

async function commitTree(repoRoot: string, tree: string, message: string): Promise<string> {
	const head = await gitOrNull(repoRoot, ["rev-parse", "--verify", "--quiet", "HEAD"]);
	const parent = head ? ["-p", head] : [];
	// Fixed identity: these are shadow commits, and the repo may have no user.name set.
	return git(repoRoot, [
		"-c",
		"user.name=pi",
		"-c",
		"user.email=pi@localhost",
		"commit-tree",
		tree,
		...parent,
		"-m",
		message,
	]);
}

/** Paths that differ between two snapshot commits, split by what the restore must do. */
async function diffPaths(
	repoRoot: string,
	from: string,
	to: string,
): Promise<{ restore: string[]; remove: string[] }> {
	const raw = await git(repoRoot, ["diff", "--no-renames", "--name-status", "-z", from, to]);
	const fields = raw.split("\0").filter((f) => f.length > 0);
	const restore: string[] = [];
	const remove: string[] = [];
	for (let i = 0; i + 1 < fields.length; i += 2) {
		const status = fields[i]?.[0];
		const path = fields[i + 1];
		/* Status is relative to `from` (the snapshot we restore): "A" means the
		   path only exists now, so it must go; anything else must be written back. */
		if (status === "A") remove.push(path);
		else restore.push(path);
	}
	return { restore, remove };
}

/** `target` and `current` are any tree-ish: snapshot commits or bare trees. */
async function restoreSnapshot(repoRoot: string, target: string, current: string): Promise<void> {
	const { restore, remove } = await diffPaths(repoRoot, target, current);
	if (restore.length > 0) {
		await withTempIndex(repoRoot, async (env) => {
			await git(repoRoot, ["read-tree", target], env);
			await gitStdin(repoRoot, ["checkout-index", "-f", "-z", "--stdin"], restore.join("\0"), env);
		});
	}
	for (const path of remove) {
		await unlink(join(repoRoot, path)).catch(() => {});
	}
}

function describe(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}

export default function (pi: ExtensionAPI) {
	let state: State | undefined;

	// git plumbing on one worktree must not interleave.
	let queue: Promise<unknown> = Promise.resolve();
	function serial<T>(fn: () => Promise<T>): Promise<T> {
		const run = queue.then(fn, fn);
		queue = run.catch(() => {});
		return run;
	}

	const refFor = (s: State, entryId: string | null) =>
		`${REF_ROOT}/${s.sessionId}/${entryId ?? ROOT_KEY}`;

	async function take(s: State, entryId: string | null): Promise<void> {
		const ref = refFor(s, entryId);
		const tree = await writeTree(s.repoRoot);
		const known = await gitOrNull(s.repoRoot, ["rev-parse", "--verify", "--quiet", `${ref}^{tree}`]);
		if (known === tree) return;
		const commit = await commitTree(s.repoRoot, tree, `pi snapshot ${entryId ?? ROOT_KEY}`);
		await git(s.repoRoot, ["update-ref", ref, commit]);
	}

	/** Snapshot for `leafId`, or the closest ancestor that has one. */
	async function findSnapshot(
		s: State,
		ctx: ExtensionContext,
		leafId: string | null,
	): Promise<string | undefined> {
		const seen = new Set<string>();
		let id = leafId;
		for (;;) {
			const commit = await gitOrNull(s.repoRoot, [
				"rev-parse",
				"--verify",
				"--quiet",
				`${refFor(s, id)}^{commit}`,
			]);
			if (commit) return commit;
			if (id === null || seen.has(id)) return undefined;
			seen.add(id);
			id = ctx.sessionManager.getEntry(id)?.parentId ?? null;
		}
	}

	async function prune(s: State): Promise<void> {
		const listing = await gitOrNull(s.repoRoot, [
			"for-each-ref",
			"--format=%(refname) %(committerdate:unix)",
			REF_ROOT,
		]);
		if (!listing) return;
		const cutoff = Date.now() / 1000 - PRUNE_DAYS * SECONDS_PER_DAY;
		for (const line of listing.split("\n")) {
			const [refname, date] = line.split(" ");
			const age = Number(date);
			if (!refname || !Number.isFinite(age) || age >= cutoff) continue;
			await gitOrNull(s.repoRoot, ["update-ref", "-d", refname]);
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		const repoRoot = await gitOrNull(ctx.cwd, ["rev-parse", "--show-toplevel"]);
		state = repoRoot ? { repoRoot, sessionId: ctx.sessionManager.getSessionId() } : undefined;
		if (!state) return;
		const s = state;
		try {
			await serial(async () => {
				await prune(s);
				await take(s, ctx.sessionManager.getLeafId());
			});
		} catch (error) {
			ctx.ui.notify(`Snapshot init failed: ${describe(error)}`, "error");
		}
	});

	/* State the turn produced, keyed by the leaf it produced it at. Both events
	   fire because tools can still write files between the last turn_end and the
	   run settling; take() skips the commit when the tree is unchanged. */
	const snapshotLeaf = async (_event: unknown, ctx: ExtensionContext) => {
		const s = state;
		if (!s) return;
		try {
			await serial(() => take(s, ctx.sessionManager.getLeafId()));
		} catch (error) {
			ctx.ui.notify(`Snapshot failed: ${describe(error)}`, "error");
		}
	};
	pi.on("turn_end", snapshotLeaf);
	pi.on("agent_settled", snapshotLeaf);

	/* Capture the branch being left (including uncommitted edits) so returning to
	   it restores exactly this state. */
	pi.on("session_before_tree", async (event, ctx) => {
		const s = state;
		if (!s) return;
		try {
			await serial(() => take(s, event.preparation.oldLeafId));
		} catch (error) {
			ctx.ui.notify(`Snapshot of current branch failed: ${describe(error)}`, "error");
		}
	});

	pi.on("session_tree", async (event, ctx) => {
		const s = state;
		if (!s || !ctx.hasUI) return;
		let rescueRef: string | undefined;
		try {
			/* The prompt is deliberately outside serial(): a dialog can stay open
			   for minutes and must not block snapshots. */
			const plan = await serial(async () => {
				const target = await findSnapshot(s, ctx, event.newLeafId);
				if (!target) return undefined;
				const stat = await git(s.repoRoot, ["diff", "--stat", target, await writeTree(s.repoRoot)]);
				return stat ? { target, stat } : undefined;
			});
			if (!plan) return;
			const summary = plan.stat.split("\n").slice(-MAX_SUMMARY_LINES).join("\n");
			if (!(await ctx.ui.confirm("Restore files to this point?", summary))) return;
			await serial(async () => {
				// Re-read the worktree: it may have changed while the dialog was open.
				const current = await writeTree(s.repoRoot);
				// Those changes belong to no snapshot yet, so park them on a rescue ref
				// before overwriting them. prune() reaps it like any other snapshot.
				const rescue = await commitTree(s.repoRoot, current, "pi pre-restore");
				rescueRef = `${REF_ROOT}/${s.sessionId}/pre-restore-${Date.now()}`;
				await git(s.repoRoot, ["update-ref", rescueRef, rescue]);
				await restoreSnapshot(s.repoRoot, plan.target, current);
			});
			ctx.ui.notify(`Files restored. Previous state kept at ${rescueRef}`, "info");
		} catch (error) {
			const recovery = rescueRef ? ` Previous state kept at ${rescueRef}` : "";
			ctx.ui.notify(`Snapshot restore failed: ${describe(error)}.${recovery}`, "error");
		}
	});
}
