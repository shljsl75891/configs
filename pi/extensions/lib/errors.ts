/** Consistent error-to-string conversion for user- and model-facing text. */
export function errorText(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}
