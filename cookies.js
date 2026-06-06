/**
 * Uniting Technology BV — GDPR Cookie Consent
 * Compliant with EU ePrivacy Directive & GDPR (Belgium)
 */
(function () {
  'use strict';

  var COOKIE_KEY = 'ut_cookie_consent';
  var COOKIE_DAYS = 365;

  function getCookie(name) {
    var v = document.cookie.match('(^|;)\\s*' + name + '\\s*=\\s*([^;]+)');
    return v ? v.pop() : null;
  }

  function setCookie(name, value, days) {
    var d = new Date();
    d.setTime(d.getTime() + days * 864e5);
    document.cookie = name + '=' + value + ';expires=' + d.toUTCString() + ';path=/;SameSite=Lax';
  }

  function removeBanner() {
    var b = document.getElementById('ut-cookie-banner');
    if (b) { b.style.opacity = '0'; setTimeout(function () { b.remove(); }, 400); }
  }

  function acceptAll() {
    setCookie(COOKIE_KEY, 'all', COOKIE_DAYS);
    removeBanner();
  }

  function acceptEssential() {
    setCookie(COOKIE_KEY, 'essential', COOKIE_DAYS);
    removeBanner();
  }

  function buildBanner() {
    if (getCookie(COOKIE_KEY)) return;

    var style = document.createElement('style');
    style.textContent = [
      '#ut-cookie-banner{position:fixed;bottom:0;left:0;right:0;z-index:99999;',
      'background:#0C1C30;border-top:1px solid rgba(0,191,223,0.25);',
      'padding:16px clamp(16px,4vw,48px);display:flex;align-items:center;',
      'justify-content:space-between;gap:16px;flex-wrap:wrap;',
      'box-shadow:0 -4px 24px rgba(0,0,0,0.4);',
      'transition:opacity 0.4s ease;font-family:Inter,system-ui,sans-serif;}',

      '#ut-cookie-banner .ut-ck-text{flex:1;min-width:200px;}',
      '#ut-cookie-banner .ut-ck-title{font-size:13px;font-weight:600;',
      'color:#fff;margin-bottom:4px;letter-spacing:0.02em;}',
      '#ut-cookie-banner .ut-ck-desc{font-size:11px;color:rgba(255,255,255,0.45);',
      'line-height:1.55;font-weight:300;}',
      '#ut-cookie-banner .ut-ck-desc a{color:rgba(0,191,223,0.8);text-decoration:none;}',
      '#ut-cookie-banner .ut-ck-desc a:hover{color:#00BFDF;}',

      '#ut-cookie-banner .ut-ck-btns{display:flex;gap:10px;flex-shrink:0;flex-wrap:wrap;}',
      '#ut-cookie-banner .ut-ck-essential{',
      'background:transparent;border:0.5px solid rgba(255,255,255,0.2);',
      'color:rgba(255,255,255,0.55);font-size:11px;padding:9px 18px;',
      'border-radius:3px;cursor:pointer;font-family:inherit;',
      'letter-spacing:0.08em;text-transform:uppercase;transition:all 0.2s;}',
      '#ut-cookie-banner .ut-ck-essential:hover{border-color:rgba(255,255,255,0.5);color:#fff;}',

      '#ut-cookie-banner .ut-ck-accept{',
      'background:#00BFDF;border:none;color:#0C1C30;',
      'font-size:11px;font-weight:600;padding:9px 20px;',
      'border-radius:3px;cursor:pointer;font-family:inherit;',
      'letter-spacing:0.08em;text-transform:uppercase;transition:background 0.2s;}',
      '#ut-cookie-banner .ut-ck-accept:hover{background:#00A8C8;}',

      '@media(max-width:600px){',
      '#ut-cookie-banner{flex-direction:column;align-items:flex-start;}',
      '#ut-cookie-banner .ut-ck-btns{width:100%;}',
      '#ut-cookie-banner .ut-ck-essential,#ut-cookie-banner .ut-ck-accept{flex:1;text-align:center;}}'
    ].join('');
    document.head.appendChild(style);

    var banner = document.createElement('div');
    banner.id = 'ut-cookie-banner';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-label', 'Cookie consent');
    banner.innerHTML = [
      '<div class="ut-ck-text">',
      '<div class="ut-ck-title">We use cookies</div>',
      '<div class="ut-ck-desc">',
      'We use essential cookies to make our website work, and optional analytics cookies to understand how visitors use it. ',
      'Read our <a href="/privacy.html">Privacy Policy</a> and <a href="/cookies.html">Cookie Policy</a>.',
      '</div>',
      '</div>',
      '<div class="ut-ck-btns">',
      '<button class="ut-ck-essential" id="ut-ck-essential-btn">Essential only</button>',
      '<button class="ut-ck-accept" id="ut-ck-accept-btn">Accept all</button>',
      '</div>'
    ].join('');

    document.body.appendChild(banner);

    document.getElementById('ut-ck-accept-btn').addEventListener('click', acceptAll);
    document.getElementById('ut-ck-essential-btn').addEventListener('click', acceptEssential);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', buildBanner);
  } else {
    buildBanner();
  }
})();
