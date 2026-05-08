/* eslint-disable no-restricted-globals */

const CACHE_VERSION = 'elimupepe-shell-v1';
const SHELL_CACHE = `${CACHE_VERSION}-shell`;
const RUNTIME_CACHE = `${CACHE_VERSION}-runtime`;

const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
  './splash/img/light-1x.png',
  './splash/img/light-2x.png',
  './splash/img/light-3x.png',
  './splash/img/light-4x.png',
  './splash/img/dark-1x.png',
  './splash/img/dark-2x.png',
  './splash/img/dark-3x.png',
  './splash/img/dark-4x.png',
  './assets/images/elimu.png',
  './assets/images/trans.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(SHELL_CACHE);
    await Promise.all(
      PRECACHE_URLS.map(async (url) => {
        try {
          const response = await fetch(url, { cache: 'reload' });
          if (response.ok) {
            await cache.put(url, response.clone());
          }
        } catch (_) {
          // Ignore missing files during development or partial deployments.
        }
      }),
    );
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const cacheNames = await caches.keys();
    await Promise.all(
      cacheNames
        .filter((name) => name.startsWith('elimupepe-shell-') && name !== SHELL_CACHE && name !== RUNTIME_CACHE)
        .map((name) => caches.delete(name)),
    );
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }

  const requestUrl = new URL(event.request.url);
  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  if (event.request.mode === 'navigate') {
    event.respondWith(networkFirstNavigation(event.request));
    return;
  }

  if (['style', 'script', 'image', 'font'].includes(event.request.destination)) {
    event.respondWith(cacheFirst(event.request));
    return;
  }

  event.respondWith(networkFirstAsset(event.request));
});

async function networkFirstNavigation(request) {
  try {
    const response = await fetch(request);
    const cache = await caches.open(SHELL_CACHE);
    cache.put('./', response.clone()).catch(() => {});
    return response;
  } catch (_) {
    const cached = await caches.match(request, { ignoreSearch: true });
    if (cached) {
      return cached;
    }

    const shell = await caches.match('./index.html');
    if (shell) {
      return shell;
    }

    return new Response(
      `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Elimu Pepe</title></head><body><main style="font-family:system-ui;padding:24px;max-width:720px;margin:0 auto;"><h1>Elimu Pepe is offline</h1><p>The live app shell is unavailable right now. Reconnect and reload.</p></main></body></html>`,
      {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      },
    );
  }
}

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }

  const response = await fetch(request);
  const cache = await caches.open(RUNTIME_CACHE);
  cache.put(request, response.clone()).catch(() => {});
  return response;
}

async function networkFirstAsset(request) {
  try {
    const response = await fetch(request);
    const cache = await caches.open(RUNTIME_CACHE);
    cache.put(request, response.clone()).catch(() => {});
    return response;
  } catch (_) {
    return caches.match(request);
  }
}
