import * as fs from "node:fs";
import * as path from "node:path";

/** bin/ → dist/ → package root, plus slack for symlinked/pnpm/monorepo layouts. */
const MAX_PI_ROOT_DEPTH = 6;

/** Walk up from the running CLI to the pi package root. */
export function findPiRoot(from: string = process.argv[1] ?? ""): string | null {
	let dir: string;
	try {
		dir = path.dirname(fs.realpathSync(from));
	} catch {
		return null;
	}
	for (let i = 0; i < MAX_PI_ROOT_DEPTH; i++) {
		if (fs.existsSync(path.join(dir, "dist/utils/clipboard-image.js"))) return dir;
		const parent = path.dirname(dir);
		if (parent === dir) break;
		dir = parent;
	}
	return null;
}
