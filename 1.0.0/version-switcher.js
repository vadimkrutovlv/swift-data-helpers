(() => {
  const moduleRoot = "/documentation/swiftdatahelpers/";
  const switcherId = "codex-docs-switcher";
  const defaultChannel = "1.0.0";
  const manifestName = "versions.json";
  const fallbackStableLabel = "stable (latest release)";
  const semverPattern = /^\d+\.\d+\.\d+$/;
  const isChannelSegment = (segment) =>
    segment === "main" || segment === "stable" || semverPattern.test(segment);

  const pathParts = window.location.pathname.split("/").filter(Boolean);
  const channelIndex = pathParts.findIndex(isChannelSegment);
  if (channelIndex === -1) return;

  const sitePrefix = channelIndex === 0 ? "/" : `/${pathParts.slice(0, channelIndex).join("/")}/`;
  const currentChannel = pathParts[channelIndex] || defaultChannel;
  let currentSuffix = `/${pathParts.slice(channelIndex + 1).join("/")}`;

  if (currentSuffix === "/" || currentSuffix === "//") {
    currentSuffix = moduleRoot;
  } else if (currentSuffix === "/documentation/swiftdatahelpers") {
    currentSuffix = `${currentSuffix}/`;
  }

  const compareSemverDesc = (left, right) => {
    const lhs = left.split(".").map(Number);
    const rhs = right.split(".").map(Number);
    for (let index = 0; index < 3; index += 1) {
      if (lhs[index] !== rhs[index]) {
        return rhs[index] - lhs[index];
      }
    }
    return 0;
  };

  const fallbackManifest = () => ({
    stable: null,
    entries: [
      { key: "stable", label: fallbackStableLabel, channel: "stable" },
      { key: "main", label: "main", channel: "main" }
    ]
  });

  const readManifest = async (url) => {
    const response = await fetch(url, {
      method: "GET",
      cache: "no-store",
      headers: { Accept: "application/json" }
    });
    if (!response.ok) {
      throw new Error(`Manifest request failed (${response.status})`);
    }
    return response.json();
  };

  const manifestUrls = () => {
    const urls = [
      `${sitePrefix}stable/${manifestName}`,
      `${sitePrefix}main/${manifestName}`,
      `${sitePrefix}${currentChannel}/${manifestName}`,
      `${sitePrefix}${defaultChannel}/${manifestName}`
    ];

    return urls.filter((value, index) => urls.indexOf(value) === index);
  };

  const loadManifest = async () => {
    for (const url of manifestUrls()) {
      try {
        const payload = await readManifest(url);
        if (payload && Array.isArray(payload.entries)) {
          return payload;
        }
      } catch (_) {
        // Try the next candidate manifest path.
      }
    }
    return fallbackManifest();
  };

  const normalizeEntries = (manifestPayload) => {
    const stableVersion =
      typeof manifestPayload?.stable === "string" && semverPattern.test(manifestPayload.stable)
        ? manifestPayload.stable
        : null;
    const defaultStableLabel = stableVersion
      ? `stable (${stableVersion})`
      : fallbackStableLabel;

    const byChannel = new Map();
    if (Array.isArray(manifestPayload?.entries)) {
      manifestPayload.entries.forEach((entry) => {
        if (!entry || typeof entry.channel !== "string") {
          return;
        }
        const channel = entry.channel.trim();
        if (!channel) {
          return;
        }
        const label = typeof entry.label === "string" && entry.label.trim()
          ? entry.label.trim()
          : channel;
        const key = typeof entry.key === "string" && entry.key.trim()
          ? entry.key.trim()
          : channel;

        byChannel.set(channel, { key, label, channel });
      });
    }

    const stableEntry = byChannel.get("stable") || {
      key: "stable",
      label: defaultStableLabel,
      channel: "stable"
    };
    if (!String(stableEntry.label).toLowerCase().includes("stable")) {
      stableEntry.label = defaultStableLabel;
    }

    const mainEntry = byChannel.get("main") || {
      key: "main",
      label: "main",
      channel: "main"
    };

    const releaseEntries = [];
    byChannel.forEach((entry, channel) => {
      if (channel !== "stable" && channel !== "main" && semverPattern.test(channel)) {
        releaseEntries.push(entry);
      }
    });
    releaseEntries.sort((lhs, rhs) => compareSemverDesc(lhs.channel, rhs.channel));

    const ordered = [stableEntry, mainEntry, ...releaseEntries];

    if (!ordered.some((entry) => entry.channel === currentChannel)) {
      ordered.push({
        key: `current:${currentChannel}`,
        label: `current (${currentChannel})`,
        channel: currentChannel
      });
    }

    return ordered;
  };

  const prefersDarkQuery = window.matchMedia("(prefers-color-scheme: dark)");

  const resolveDarkMode = () => {
    const html = document.documentElement;
    const body = document.body;

    const preferredScheme =
      html?.dataset?.colorScheme ||
      body?.dataset?.colorScheme ||
      "auto";
    if (preferredScheme === "dark") {
      return true;
    }
    if (preferredScheme === "light") {
      return false;
    }

    if (html?.classList?.contains("theme-dark") || body?.classList?.contains("theme-dark")) {
      return true;
    }
    if (html?.classList?.contains("theme-light") || body?.classList?.contains("theme-light")) {
      return false;
    }

    return document.documentElement.classList.contains("theme-dark") || prefersDarkQuery.matches;
  };

  const applyTheme = (select) => {
    const isDark = resolveDarkMode();
    select.style.colorScheme = isDark ? "dark" : "light";
    select.style.color = isDark
      ? "var(--color-nav-dark-link-color, #f5f5f7)"
      : "var(--color-nav-link-color, #1d1d1f)";
    select.style.backgroundColor = isDark ? "rgba(20, 20, 22, 0.84)" : "rgba(255, 255, 255, 0.9)";
    select.style.borderColor = isDark ? "rgba(255, 255, 255, 0.34)" : "rgba(0, 0, 0, 0.24)";
  };

  const applyLayout = (select) => {
    const isCompact = window.innerWidth <= 900;
    select.style.display = isCompact ? "none" : "block";
    select.style.position = "absolute";
    select.style.top = "50%";
    select.style.left = "50%";
    select.style.transform = "translate(-50%, -50%)";
    select.style.zIndex = "3";
    select.style.padding = "4px 28px 4px 10px";
    select.style.borderWidth = "1px";
    select.style.borderStyle = "solid";
    select.style.borderRadius = "8px";
    select.style.cursor = "pointer";
    select.style.fontSize = "14px";
    select.style.fontWeight = "400";
    select.style.lineHeight = "1";
    select.style.fontFamily = "var(--typography-html-font, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif)";
    select.style.boxShadow = "0 2px 10px rgba(0, 0, 0, 0.08)";
    select.style.appearance = "auto";
    select.style.WebkitAppearance = "menulist";
  };

  const getOrCreateSelect = (entries) => {
    const existing = document.getElementById(switcherId);
    if (existing) {
      const knownChannels = new Set(Array.from(existing.options).map((option) => option.value));
      entries.forEach((entry) => {
        if (knownChannels.has(entry.channel)) {
          return;
        }
        const option = document.createElement("option");
        option.value = entry.channel;
        option.textContent = entry.label;
        existing.appendChild(option);
      });
      return existing;
    }

    const select = document.createElement("select");
    select.id = switcherId;
    select.setAttribute("aria-label", "Documentation channel");

    entries.forEach((entry) => {
      const element = document.createElement("option");
      element.value = entry.channel;
      element.textContent = entry.label;
      select.appendChild(element);
    });

    if (Array.from(select.options).some((option) => option.value === currentChannel)) {
      select.value = currentChannel;
    }
    select.onchange = () => {
      const target = `${sitePrefix}${select.value}${currentSuffix}`;
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

    return select;
  };

  const mountSelect = (entries) => {
    const navContent = document.querySelector(".nav-content");
    if (!navContent) return;
    if (window.getComputedStyle(navContent).position === "static") {
      navContent.style.position = "relative";
    }

    const select = getOrCreateSelect(entries);
    if (select.parentElement !== navContent) {
      navContent.appendChild(select);
    }

    applyLayout(select);
    applyTheme(select);
  };

  const initialize = async () => {
    const manifestPayload = await loadManifest();
    const entries = normalizeEntries(manifestPayload);
    mountSelect(entries);

    const observer = new MutationObserver(() => {
      mountSelect(entries);
    });
    observer.observe(document.body, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ["class", "data-color-scheme", "data-theme"]
    });

    const handleThemeChange = () => {
      const select = document.getElementById(switcherId);
      if (select) applyTheme(select);
    };

    if (typeof prefersDarkQuery.addEventListener === "function") {
      prefersDarkQuery.addEventListener("change", handleThemeChange);
    } else if (typeof prefersDarkQuery.addListener === "function") {
      prefersDarkQuery.addListener(handleThemeChange);
    }

    window.addEventListener("resize", () => {
      const select = document.getElementById(switcherId);
      if (select) applyLayout(select);
    });
  };

  initialize();
})();
