export function resourceToStr(r: ResourceStr): string {
  if (typeof r === 'string') return r;
  try {
    return getContext().resourceManager.getStringSync(r.id);
  } catch (_e) {
    return String(r.id);
  }
}
