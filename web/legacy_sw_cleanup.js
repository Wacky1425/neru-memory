// Migration-only worker at the legacy Flutter service-worker URL.
// Existing installations fetch this during their normal service-worker update check.
self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
});
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((name) => name.startsWith('flutter-')).map((name) => caches.delete(name)));
    await self.registration.unregister();
    const pages = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    await Promise.all(pages.map((page) => page.navigate(page.url).catch(() => {})));
  })());
});
