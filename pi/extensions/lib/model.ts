/** Formats a model as "provider/id" for display, storage, and comparison. */
export function modelKey(model: { provider: string; id: string } | undefined): string | undefined {
  return model && `${model.provider}/${model.id}`;
}

/** Splits "provider/id"; undefined when the provider part is empty or missing. */
export function parseModelKey(key: string): { provider: string; id: string } | undefined {
  const slash = key.indexOf("/");
  return slash < 1 ? undefined : { provider: key.slice(0, slash), id: key.slice(slash + 1) };
}
