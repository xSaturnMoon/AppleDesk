import Foundation

/// Spoof desktop Chrome + segnali PWA per evitare il muro "Aggiungi alla Home" su iPad.
enum GFNBrowserSpoof {
  /// User-Agent Chrome Windows — supportato ufficialmente da play.geforcenow.com.
  static let desktopChromeUserAgent =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  /// Iniettato prima di qualsiasi script della pagina.
  static let bootstrapScript = """
  (function() {
    const UA = '\(desktopChromeUserAgent)';
    const defs = [
      ['userAgent', UA],
      ['platform', 'Win32'],
      ['vendor', 'Google Inc.'],
      ['maxTouchPoints', 0],
      ['hardwareConcurrency', 8],
      ['deviceMemory', 8],
      ['webdriver', false],
      ['standalone', true]
    ];
    for (const [key, val] of defs) {
      try { Object.defineProperty(navigator, key, { get: () => val, configurable: true }); } catch (e) {}
    }
    try {
      Object.defineProperty(navigator, 'userAgentData', {
        get: () => ({
          brands: [{ brand: 'Chromium', version: '131' }, { brand: 'Google Chrome', version: '131' }],
          mobile: false,
          platform: 'Windows',
          getHighEntropyValues: () => Promise.resolve({ platform: 'Windows', platformVersion: '10.0.0' })
        }),
        configurable: true
      });
    } catch (e) {}
    const origMatch = window.matchMedia.bind(window);
    window.matchMedia = function(q) {
      if (q === '(display-mode: standalone)' || q === '(display-mode: fullscreen)') {
        return { matches: true, media: q, addListener: () => {}, removeListener: () => {}, addEventListener: () => {}, removeEventListener: () => {} };
      }
      if (q === '(pointer: fine)') {
        return { matches: true, media: q, addListener: () => {}, removeListener: () => {}, addEventListener: () => {}, removeEventListener: () => {} };
      }
      return origMatch(q);
    };
    try { delete window.orientation; } catch (e) {}
  })();
  """

  /// Dopo il caricamento: nasconde prompt iOS e marca i pulsanti login.
  static let pageCleanupScript = """
  (function() {
    if (window.__appledeskGFN) return;
    window.__appledeskGFN = true;

    const blockPhrases = [
      'schermata home', 'schermata Home', 'home screen', 'aggiungi alla',
      'add to home', 'aggiungi a home', 'scorciatoia'
    ];
    const loginPhrases = ['accedi', 'sign in', 'log in', 'login', 'get in', 'entra'];

    function shouldHide(text) {
      const t = (text || '').trim().toLowerCase();
      if (!t || t.length > 220) return false;
      return blockPhrases.some(p => t.includes(p.toLowerCase()));
    }

    function isLoginButton(el) {
      const t = (el.textContent || '').trim().toLowerCase();
      if (!t || t.length > 40) return false;
      return loginPhrases.some(p => t === p || t.startsWith(p + ' ') || t.includes(p));
    }

    function hideInstallWall() {
      document.querySelectorAll('div, section, article, aside, dialog, [role="dialog"]').forEach(node => {
        const txt = node.textContent || '';
        if (!shouldHide(txt)) return;
        if (node.querySelector('video, canvas, iframe')) return;
        const r = node.getBoundingClientRect();
        if (r.width < 80 || r.height < 80) return;
        node.style.setProperty('display', 'none', 'important');
        node.style.setProperty('visibility', 'hidden', 'important');
        node.setAttribute('data-appledesk-hidden', 'install-wall');
      });
    }

    function markLoginButtons() {
      document.querySelectorAll('button, a, [role="button"], input[type="button"], input[type="submit"]').forEach(el => {
        if (isLoginButton(el)) el.setAttribute('data-appledesk-login', '1');
      });
    }

    function run() {
      hideInstallWall();
      markLoginButtons();
    }

    run();
    new MutationObserver(run).observe(document.documentElement, { childList: true, subtree: true, attributes: true });
  })();
  """

  static let clickLoginScript = """
  (function() {
    const nodes = document.querySelectorAll('[data-appledesk-login], button, a, [role="button"]');
    const words = ['accedi', 'sign in', 'log in', 'get in', 'entra', 'login'];
    for (const el of nodes) {
      const t = (el.textContent || '').trim().toLowerCase();
      if (!t || t.length > 48) continue;
      if (words.some(w => t === w || t.startsWith(w + ' ') || t.includes(w))) {
        el.click();
        return 'clicked';
      }
    }
    return 'not-found';
  })();
  """
}
