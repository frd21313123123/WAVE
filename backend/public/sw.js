/* ============================
   Wave Messenger Service Worker
   Push notifications + offline cache
   ============================ */

const CACHE_NAME = "wave-v14";
const PRECACHE_URLS = [
    "/",
    "/index.html",
    "/styles.css?v=20260313-7",
    "/app.js?v=20260313-14",
];

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
    let data = { title: "Wave Messenger", body: "New message" };

    if (event.data) {
        try {
            data = event.data.json();
        } catch {
            data.body = event.data.text();
        }
    }

    const isIncomingCall = data.type === "call:incoming";
    const options = {
        body: data.body || "New message",
        icon: data.icon || "/icons/icon-192.png",
        badge: "/icons/icon-192.png",
        tag: data.tag || (isIncomingCall ? "wave-call" : "wave-msg"),
        renotify: true,
        requireInteraction: isIncomingCall,
        vibrate: isIncomingCall ? [250, 150, 250, 150, 250] : [200, 100, 200],
        data: {
            type: data.type || "message",
            conversationId: data.conversationId || null,
            callId: data.callId || null,
            fromUserId: data.fromUserId || null,
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
