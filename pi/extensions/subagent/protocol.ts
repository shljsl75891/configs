/**
 * IPC contract between the orchestrator (index.ts) and the child process
 * (marker-extension.ts). Both sides import from here; string literals in
 * either place would drift silently and produce a silent-timeout failure mode.
 */

/** Environment variable names used to configure the child process. */
export const ENV = {
	resultFile: "PI_SUBAGENT_RESULT_FILE",
	label: "PI_SUBAGENT_LABEL",
	depth: "PI_SUBAGENT_DEPTH",
	tools: "PI_SUBAGENT_TOOLS",
} as const;

/** Append this suffix to the result file path to get the marker that says the child waits on a prompt. */
export const reviewMarkerFor = (resultFile: string): string => `${resultFile}.review`;

/** Child touches this file on activity; the parent treats a fresh mtime as proof of life. */
export const heartbeatFor = (resultFile: string): string => `${resultFile}.alive`;

/** Depth of the current process in the subagent tree (0 = root). */
export const childDepth = (): number => Number(process.env[ENV.depth]) || 0;
