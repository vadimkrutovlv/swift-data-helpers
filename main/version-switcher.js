(() => {
  const moduleRoot = "/documentation/swiftdatahelpers/";
  const switcherId = "codex-docs-switcher";
  const stableLabel = "1.0.1";
  const pathParts = window.location.pathname.split("/").filter(Boolean);
  const channelIndex = pathParts.findIndex(segment => segment === "main" || segment === "stable");
  if (channelIndex === -1) return;

  const sitePrefix = channelIndex === 0 ? "/" : `/${pathParts.slice(0, channelIndex).join("/")}/`;
  const currentChannel = pathParts[channelIndex];
  let currentSuffix = `/${pathParts.slice(channelIndex + 1).join("/")}`;

  if (currentSuffix === "/" || currentSuffix === "//") {
    currentSuffix = moduleRoot;
  } else if (currentSuffix === "/documentation/swiftdatahelpers") {
    currentSuffix = `${currentSuffix}/`;
  }

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

  const getOrCreateSelect = () => {
    const existing = document.getElementById(switcherId);
    if (existing) return existing;

    const select = document.createElement("select");
    select.id = switcherId;
    select.setAttribute("aria-label", "Documentation channel");

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

  const mountSelect = () => {
    const navContent = document.querySelector(".nav-content");
    if (!navContent) return;
    if (window.getComputedStyle(navContent).position === "static") {
      navContent.style.position = "relative";
    }

    const select = getOrCreateSelect();
    if (select.parentElement !== navContent) {
      navContent.appendChild(select);
    }

    applyLayout(select);
    applyTheme(select);
  };

  mountSelect();

  const observer = new MutationObserver(() => {
    mountSelect();
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
})();
