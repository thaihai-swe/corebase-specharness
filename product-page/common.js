/**
 * common.js — single source of truth for page behavior.
 * Pairs with the pre-head FOUC-prevention script in document.html, which uses
 * the same localStorage key.
 */

const THEME_KEY = 'theme';

function getStoredTheme() {
    return localStorage.getItem(THEME_KEY);
}

function getResolvedTheme() {
    const stored = getStoredTheme();
    if (stored === 'dark' || stored === 'light') return stored;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem(THEME_KEY, theme);
    syncThemeToggleUI(theme);
    configureMermaid();
}

function syncThemeToggleUI(theme) {
    const sun = document.querySelector('#theme-toggle .sun');
    const moon = document.querySelector('#theme-toggle .moon');
    if (sun && moon) {
        sun.style.display = theme === 'dark' ? 'block' : 'none';
        moon.style.display = theme === 'dark' ? 'none' : 'block';
    }
    const toggle = document.getElementById('theme-toggle');
    if (toggle) {
        toggle.setAttribute('aria-label',
            theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme');
    }
}

function initThemeSwitcher() {
    const toggle = document.getElementById('theme-toggle');
    if (!toggle) return;
    syncThemeToggleUI(getResolvedTheme());
    toggle.addEventListener('click', async () => {
        const next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
        applyTheme(next);
        await renderAllMermaid();
    });
}

const mermaidCache = new Map();
const renderCounter = { n: 0 };
const panZoomInstances = new Map();
let mermaidResizeTimer;

function configureMermaid() {
    if (typeof mermaid === 'undefined') return false;
    const theme = getResolvedTheme();
    mermaid.initialize({
        startOnLoad: false,
        theme: theme === 'dark' ? 'dark' : 'neutral',
        securityLevel: 'loose',
        fontFamily: 'Inter, system-ui, sans-serif',
        flowchart: { htmlLabels: true, curve: 'basis' },
        themeVariables: {
            fontSize: '14px',
            actorTextColor: theme === 'dark' ? '#F7F7F5' : '#111111',
            actorLineColor: theme === 'dark' ? '#3A3F47' : '#D4D0C7',
            signalColor: theme === 'dark' ? '#F7F7F5' : '#111111',
            signalTextColor: theme === 'dark' ? '#F7F7F5' : '#111111',
            labelTextColor: theme === 'dark' ? '#F7F7F5' : '#111111',
            loopTextColor: theme === 'dark' ? '#F7F7F5' : '#111111',
            noteTextColor: '#111111'
        }
    });
    return true;
}

async function fetchMmd(path) {
    if (mermaidCache.has(path)) return mermaidCache.get(path);
    const res = await fetch(path);
    if (!res.ok) throw new Error('HTTP ' + res.status);
    const txt = await res.text();
    mermaidCache.set(path, txt);
    return txt;
}

function resolveMmdPath(path) {
    if (window.location.pathname.includes('/product-page/')) return '../' + path;
    return path;
}

function fitPanZoom(instance) {
    try {
        instance.resize();
        instance.fit();
        instance.center();
    } catch (_) { }
}

function attachPanZoom(container, svgEl) {
    if (typeof svgPanZoom === 'undefined') return;
    setTimeout(() => {
        try {
            const pz = svgPanZoom(svgEl, {
                zoomEnabled: true,
                panEnabled: true,
                controlIconsEnabled: true,
                fit: true,
                center: true,
                minZoom: 0.3,
                maxZoom: 10,
                zoomScaleSensitivity: 0.3
            });
            fitPanZoom(pz);
            panZoomInstances.set(container, pz);
        } catch (err) {
            console.error('Pan/zoom setup failed:', err);
        }
    }, 30);
}

async function renderMermaidFromFile(container) {
    const sourcePath = container.getAttribute('data-mmd');
    const path = resolveMmdPath(sourcePath);
    if (panZoomInstances.has(container)) {
        try { panZoomInstances.get(container).destroy(); } catch (_) { }
        panZoomInstances.delete(container);
    }
    try {
        const src = await fetchMmd(path);
        const id = 'mmd-' + (renderCounter.n++);
        const result = await mermaid.render(id, src);
        container.innerHTML = result.svg;
        const svgEl = container.querySelector('svg');
        if (svgEl) {
            svgEl.removeAttribute('width');
            svgEl.removeAttribute('height');
            svgEl.style.cssText = 'display:block;width:100%;height:100%;max-width:none';
            attachPanZoom(container, svgEl);
        }
    } catch (err) {
        console.error('Mermaid render failed for ' + path + ':', err);
        container.innerHTML = '<div class="callout danger">Failed to render diagram <code>' + sourcePath +
            '</code><br><small>' + (err && err.message ? err.message : err) + '</small></div>';
    }
}

async function renderMermaidFromCode(el, index) {
    const id = 'mermaid-svg-' + index;
    const content = el.tagName === 'CODE'
        ? el.textContent
        : decodeURIComponent(el.getAttribute('data-mermaid-src'));
    let container;
    if (el.tagName === 'CODE') {
        container = document.createElement('div');
        container.className = 'diagram-wrapper';
        container.setAttribute('data-mermaid-src', encodeURIComponent(content));
        el.parentElement.replaceWith(container);
    } else {
        container = el;
        if (panZoomInstances.has(id)) {
            try { panZoomInstances.get(id).destroy(); } catch (_) { }
            panZoomInstances.delete(id);
        }
        container.innerHTML = '';
    }
    try {
        const { svg } = await mermaid.render(id, content);
        container.innerHTML = svg;
        const svgEl = container.querySelector('svg');
        if (svgEl) {
            svgEl.removeAttribute('width');
            svgEl.removeAttribute('height');
            svgEl.style.cssText = 'display:block;width:100%;height:100%;max-width:none';
            if (typeof svgPanZoom !== 'undefined') {
                setTimeout(() => {
                    const pz = svgPanZoom(svgEl, {
                        zoomEnabled: true,
                        controlIconsEnabled: true,
                        fit: true,
                        center: true,
                        minZoom: 0.1,
                        maxZoom: 10
                    });
                    panZoomInstances.set(id, pz);
                }, 50);
            }
        }
    } catch (e) {
        console.error('Failed to render diagram ' + index + ':', e);
        container.innerHTML = '<div class="callout danger">Failed to render diagram: ' + e.message + '</div>';
    }
}

async function renderAllMermaid() {
    if (!configureMermaid()) return;
    const fileTargets = document.querySelectorAll('.mermaid-render[data-mmd]');
    for (const c of fileTargets) await renderMermaidFromFile(c);
    const codeTargets = document.querySelectorAll('pre code.language-mermaid, .diagram-wrapper[data-mermaid-src]');
    for (let i = 0; i < codeTargets.length; i++) await renderMermaidFromCode(codeTargets[i], i);
}

function initMermaidViewportResize() {
    window.addEventListener('resize', () => {
        window.clearTimeout(mermaidResizeTimer);
        mermaidResizeTimer = window.setTimeout(() => {
            panZoomInstances.forEach(fitPanZoom);
        }, 120);
    });
}

function initSearch() {
    const input = document.getElementById('toc-search');
    const items = document.querySelectorAll('#toc-list li');
    if (!input || !items.length) return;
    input.addEventListener('input', (event) => {
        const query = event.target.value.trim().toLowerCase();
        items.forEach(item => {
            item.hidden = !item.textContent.toLowerCase().includes(query);
        });
    });
}

function initBackToTop() {
    const btn = document.getElementById('back-to-top');
    if (!btn) return;
    window.addEventListener('scroll', () => {
        btn.classList.toggle('visible', window.scrollY > 300);
    });
    btn.addEventListener('click', (e) => {
        e.preventDefault();
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });
}

function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const targetId = this.getAttribute('href');
            if (!targetId || targetId === '#') return;
            const target = document.querySelector(targetId);
            if (target) {
                e.preventDefault();
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    });
}

function initCodeCopyButtons() {
    const blocks = document.querySelectorAll('pre');
    blocks.forEach(pre => {
        if (pre.querySelector('.code-copy-btn')) return;
        const codeEl = pre.querySelector('code');
        if (!codeEl) return;
        if (codeEl.classList.contains('language-mermaid')) return;
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'code-copy-btn';
        btn.textContent = 'Copy';
        btn.setAttribute('aria-label', 'Copy code to clipboard');
        btn.addEventListener('click', async () => {
            const text = codeEl.innerText;
            try {
                await navigator.clipboard.writeText(text);
            } catch {
                const ta = document.createElement('textarea');
                ta.value = text;
                ta.style.position = 'fixed';
                ta.style.opacity = '0';
                document.body.appendChild(ta);
                ta.select();
                try { document.execCommand('copy'); } finally { document.body.removeChild(ta); }
            }
            btn.textContent = 'Copied';
            btn.dataset.copied = 'true';
            setTimeout(() => {
                btn.textContent = 'Copy';
                delete btn.dataset.copied;
            }, 1800);
        });
        pre.appendChild(btn);
    });
}

document.addEventListener('DOMContentLoaded', () => {
    initThemeSwitcher();
    initSmoothScroll();
    initBackToTop();
    initSearch();
    initCodeCopyButtons();
    initPrimaryNav();
    initMermaidViewportResize();
    renderAllMermaid();
});

// Primary nav: dropdown menus + mobile toggle + scroll-aware compact state
function initPrimaryNav() {
    const header = document.querySelector('.main-header');
    const nav = document.querySelector('.main-nav');
    const list = document.getElementById('primary-nav');
    const burger = document.getElementById('nav-toggle');
    if (!nav || !list) return;

    // Mobile burger toggle
    if (burger) {
        burger.addEventListener('click', () => {
            const open = list.classList.toggle('is-open');
            burger.setAttribute('aria-expanded', open ? 'true' : 'false');
        });
    }

    // Close mobile menu when any link is clicked
    list.querySelectorAll('a').forEach(a => {
        a.addEventListener('click', () => {
            if (list.classList.contains('is-open')) {
                list.classList.remove('is-open');
                if (burger) burger.setAttribute('aria-expanded', 'false');
            }
            closeAllDropdowns();
        });
    });

    // Dropdown triggers (desktop click + keyboard)
    const triggers = list.querySelectorAll('.nav-dropdown-trigger');
    triggers.forEach(btn => {
        btn.addEventListener('click', e => {
            e.stopPropagation();
            const group = btn.parentElement;
            const isOpen = group.classList.contains('is-open');
            closeAllDropdowns();
            if (!isOpen) {
                group.classList.add('is-open');
                btn.setAttribute('aria-expanded', 'true');
            }
        });
    });

    // Close dropdowns on outside click or Escape
    document.addEventListener('click', e => {
        if (!nav.contains(e.target)) closeAllDropdowns();
    });
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') {
            closeAllDropdowns();
            if (list.classList.contains('is-open')) {
                list.classList.remove('is-open');
                if (burger) burger.setAttribute('aria-expanded', 'false');
            }
        }
    });

    function closeAllDropdowns() {
        list.querySelectorAll('.nav-group.is-open').forEach(g => g.classList.remove('is-open'));
        triggers.forEach(t => t.setAttribute('aria-expanded', 'false'));
    }

    // Compact-on-scroll header
    if (header) {
        let lastY = window.scrollY;
        window.addEventListener('scroll', () => {
            const y = window.scrollY;
            header.classList.toggle('is-scrolled', y > 8);
            lastY = y;
        }, { passive: true });
    }
}
