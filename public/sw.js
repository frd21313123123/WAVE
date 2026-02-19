/* ============================
   Wave Messenger — Service Worker
   Push notifications + offline cache
   ============================ */

const CACHE_NAME = "wave-v1";
const PRECACHE_URLS = ["/", "/index.html", "/styles.css", "/app.js"];

/* ---------- Install ---------- */
self.addEventListener("install", (event) => {
    self.skipWaiting();
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
    );
});

/* ---------- Activate ---------- */
self.addEventListener("activate", (event) => {
    event.waitUntil(
        caches
            .keys()
            .then((keys) =>
                Promise.all(
                    keys
                        .filter((key) => key !== CACHE_NAME)
                        .map((key) => caches.delete(key))
                )
            )
            .then(() => self.clients.claim())
    );
});

/* ---------- Fetch (network-first, fallback to cache) ---------- */
self.addEventListener("fetch", (event) => {
    if (event.request.method !== "GET") return;
    if (event.request.url.includes("/api/")) return;
    if (event.request.url.includes("/ws")) return;

    event.respondWith(
        fetch(event.request)
            .then((response) => {
                const clone = response.clone();
                caches.open(CACHE_NAME).then((cache) => {
                    cache.put(event.request, clone);
                });
                return response;
            })
            .catch(() => caches.match(event.request))
    );
});

/* ---------- Push notification ---------- */
self.addEventListener("push", (event) => {
    let data = { title: "Wave Messenger", body: "Новое сообщение" };

    if (event.data) {
        try {
            data = event.data.json();
        } catch {
            data.body = event.data.text();
        }
    }

    const options = {
        body: data.body || "Новое сообщение",
        icon: data.icon || "/icons/icon-192.png",
        badge: "/icons/icon-192.png",
        tag: data.tag || "wave-msg",
        renotify: true,
        vibrate: [200, 100, 200],
        data: {
            conversationId: data.conversationId || null,
            url: data.url || "/",
        },
    };

    event.waitUntil(
        self.registration.showNotification(data.title || "Wave Messenger", options)
    );
});

/* ---------- Notification click ---------- */
self.addEventListener("notificationclick", (event) => {
    event.notification.close();

    const urlToOpen = event.notification.data?.url || "/";

    event.waitUntil(
        self.clients
            .matchAll({ type: "window", includeUncontrolled: true })
            .then((clientList) => {
                for (const client of clientList) {
                    if (client.url.includes(self.location.origin) && "focus" in client) {
                        return client.focus();
                    }
                }
                return self.clients.openWindow(urlToOpen);
            })
    );
});
