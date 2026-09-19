/** Wire format written by marker-extension.ts and parsed by index.ts. One owner; import this in both. */
export interface SubagentResult {
	status: "ok" | "error";
	output: string;
	/** Passed through untouched, so the shape is not this tool's to claim. */
	usage?: unknown;
	stopReason?: string;
	errorMessage?: string;
}

const optStr = (v: unknown): boolean => v === undefined || typeof v === "string";

/** Type-guard for parsing the result file. One cast, to the weakest type that permits property access. */
export function isSubagentResult(value: unknown): value is SubagentResult {
	if (typeof value !== "object" || value === null) return false;
	const v = value as Partial<Record<keyof SubagentResult, unknown>>;
	return (v.status === "ok" || v.status === "error") && typeof v.output === "string" && optStr(v.errorMessage) && optStr(v.stopReason);
}

