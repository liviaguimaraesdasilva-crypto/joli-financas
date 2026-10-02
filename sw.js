const CACHE_NAME = "joli-final-2026-08";

const APP_ASSETS = [
  "./",
  "index.html",
  "styles.css",
  "app.js",
  "config.js",
  "historical-data.js",
  "manifest.webmanifest",
  "icon-192.png",
  "icon-512.png"
];

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(APP_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(key => key !== CACHE_NAME)
          .map(key => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", event => {
  const request = event.request;
  const url = new URL(request.url);

  // Não intercepta POST, autenticação, Supabase ou qualquer serviço externo.
  if (
    request.method !== "GET" ||
    url.origin !== self.location.origin
  ) {
    return;
  }

  // Somente arquivos do próprio JOLI passam pelo service worker.
  event.respondWith(
    fetch(request).catch(() => caches.match(request))
  );
});
