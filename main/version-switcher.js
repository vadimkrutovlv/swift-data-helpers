(() => {
  const moduleRoot = "/documentation/swiftdatahelpers/";
  const stableLabel = "1.0.1";
  const segments = window.location.pathname.split("/").filter(Boolean);
  const channelIndex = segments.findIndex(segment => segment === "main" || segment === "stable");
  if (channelIndex === -1) return;

  const sitePrefix = channelIndex === 0
    ? "/"
    : `/${segments.slice(0, channelIndex).join("/")}/`;
  const currentChannel = segments[channelIndex];
  const suffixSegments = segments.slice(channelIndex + 1);
  const currentSuffix = suffixSegments.length > 0
    ? `/${suffixSegments.join("/")}`
    : moduleRoot;

  const wrapper = document.createElement("div");
  wrapper.style.cssText = "position:fixed;top:16px;right:16px;z-index:9999;background:rgba(255,255,255,0.94);border:1px solid #d0d7de;border-radius:8px;padding:8px 10px;font:12px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;box-shadow:0 2px 10px rgba(0,0,0,0.08);";

  const label = document.createElement("label");
  label.textContent = "Docs:";
  label.style.marginRight = "6px";
  label.style.fontWeight = "600";

  const select = document.createElement("select");
  [
    { value: "main", label: "main" },
    { value: "stable", label: stableLabel }
  ].forEach(option => {
    const element = document.createElement("option");
    element.value = option.value;
    element.textContent = option.label;
    select.appendChild(element);
  });

  select.value = currentChannel;
  select.onchange = () => {
    const targetSuffix = currentSuffix || moduleRoot;
    const normalizedSuffix = targetSuffix.startsWith("/")
      ? targetSuffix
      : `/${targetSuffix}`;
    const target = `${sitePrefix}${select.value}${normalizedSuffix}`;
    fetch(target, { method: "HEAD" })
      .then(response => {
        if (response.ok) {
          window.location.href = target;
          return;
        }
        window.location.href = `${sitePrefix}${select.value}${moduleRoot}`;
      })
      .catch(() => {
        window.location.href = `${sitePrefix}${select.value}${moduleRoot}`;
      });
  };

  wrapper.append(label, select);
  document.body.appendChild(wrapper);
})();
