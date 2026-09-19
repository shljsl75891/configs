/**
 * IPC contract between the orchestrator (index.ts) and the child process
 * (marker-extension.ts). Both sides import from here; string literals in
 * either place would drift silently and produce a silent-timeout failure mode.
 */

/** Environment variable names used to configure the child process. */
export const ENV = {
	resultFile: "PI_SUBAGENT_RESULT_FILE",
	review: "PI_SUBAGENT_REVIEW",
	label: "PI_SUBAGENT_LABEL",
	depth: "PI_SUBAGENT_DEPTH",
} as const;

/** Append this suffix to the result file path to get the review-pending marker. */
export const reviewMarkerFor = (resultFile: string): string => `${resultFile}.review`;

/** Depth of the current process in the subagent tree (0 = root). */
export const childDepth = (): number => Number(process.env[ENV.depth]) || 0;
