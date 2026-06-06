export function resourceToStr(r: ResourceStr): string {
  if (typeof r === 'string') return r;
  try {
    return getContext().resourceManager.getStringSync(r.id);
  } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
    return r.id.toString();
  }
}
