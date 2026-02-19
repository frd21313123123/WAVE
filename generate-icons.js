const { createCanvas } = (() => {
    try { return require("canvas"); } catch { return { createCanvas: null }; }
})();
const fs = require("fs");
const path = require("path");

// Simple PNG generation using raw pixel data
// Creates a minimal valid PNG file

function createMinimalPng(size) {
    // Create a simple colored icon using raw data
    const width = size;
    const height = size;

    // CRC32 table
    const crcTable = new Uint32Array(256);
    for (let n = 0; n < 256; n++) {
        let c = n;
        for (let k = 0; k < 8; k++) {
            c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
        }
        crcTable[n] = c;
    }

    function crc32(buf) {
        let c = 0xffffffff;
        for (let i = 0; i < buf.length; i++) {
            c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
        }
        return (c ^ 0xffffffff) >>> 0;
    }

    function writeUint32BE(buf, val, off) {
        buf[off] = (val >>> 24) & 0xff;
        buf[off + 1] = (val >>> 16) & 0xff;
        buf[off + 2] = (val >>> 8) & 0xff;
        buf[off + 3] = val & 0xff;
    }

    // Generate pixel data (RGBA)
    const pixels = Buffer.alloc(width * height * 4);
    const cx = width / 2, cy = height / 2;
    const cornerR = size * 0.19;

    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const i = (y * width + x) * 4;

            // Check if inside rounded rect
            let inside = true;
            const corners = [
                [cornerR, cornerR],
                [width - cornerR, cornerR],
                [cornerR, height - cornerR],
                [width - cornerR, height - cornerR]
            ];

            if (x < cornerR && y < cornerR) {
                const dx = x - cornerR, dy = y - cornerR;
                inside = (dx * dx + dy * dy) <= cornerR * cornerR;
            } else if (x > width - cornerR && y < cornerR) {
                const dx = x - (width - cornerR), dy = y - cornerR;
                inside = (dx * dx + dy * dy) <= cornerR * cornerR;
            } else if (x < cornerR && y > height - cornerR) {
                const dx = x - cornerR, dy = y - (height - cornerR);
                inside = (dx * dx + dy * dy) <= cornerR * cornerR;
            } else if (x > width - cornerR && y > height - cornerR) {
                const dx = x - (width - cornerR), dy = y - (height - cornerR);
                inside = (dx * dx + dy * dy) <= cornerR * cornerR;
            }

            if (!inside) {
                pixels[i] = pixels[i + 1] = pixels[i + 2] = pixels[i + 3] = 0;
                continue;
            }

            // Background gradient
            const t = (x + y) / (width + height);
            const r = Math.round(14 + t * 12);
            const g = Math.round(22 + t * 20);
            const b = Math.round(33 + t * 28);

            // Draw wave pattern
            const nx = x / width;
            const waveY1 = cy + Math.sin(nx * Math.PI * 2) * (height * 0.15);
            const waveY2 = cy - height * 0.1 + Math.sin(nx * Math.PI * 2) * (height * 0.15);

            const distW1 = Math.abs(y - waveY1);
            const distW2 = Math.abs(y - waveY2);

            const lineW = size * 0.035;

            if (distW1 < lineW) {
                const blend = 1 - distW1 / lineW;
                const wt = nx;
                pixels[i] = Math.round(r + blend * (0 + wt * 123 - r));  // cyan to purple
                pixels[i + 1] = Math.round(g + blend * (210 - wt * 113 - g));
                pixels[i + 2] = Math.round(b + blend * (255 - b));
                pixels[i + 3] = 255;
            } else if (distW2 < lineW * 0.7) {
                const blend = (1 - distW2 / (lineW * 0.7)) * 0.5;
                const wt = nx;
                pixels[i] = Math.round(r + blend * (0 + wt * 123 - r));
                pixels[i + 1] = Math.round(g + blend * (210 - wt * 113 - g));
                pixels[i + 2] = Math.round(b + blend * (255 - b));
                pixels[i + 3] = 255;
            } else {
                pixels[i] = r;
                pixels[i + 1] = g;
                pixels[i + 2] = b;
                pixels[i + 3] = 255;
            }
        }
    }

    // Build raw data (filter byte + RGBA per row)
    const rawData = Buffer.alloc(height * (1 + width * 4));
    for (let y = 0; y < height; y++) {
        rawData[y * (1 + width * 4)] = 0; // filter: none
        pixels.copy(rawData, y * (1 + width * 4) + 1, y * width * 4, (y + 1) * width * 4);
    }

    // Deflate (use zlib)
    const zlib = require("zlib");
    const compressed = zlib.deflateSync(rawData, { level: 9 });

    // Build PNG
    const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

    // IHDR
    const ihdrData = Buffer.alloc(13);
    writeUint32BE(ihdrData, width, 0);
    writeUint32BE(ihdrData, height, 4);
    ihdrData[8] = 8; // bit depth
    ihdrData[9] = 6; // color type: RGBA
    ihdrData[10] = 0; // compression
    ihdrData[11] = 0; // filter
    ihdrData[12] = 0; // interlace

    function makeChunk(type, data) {
        const typeB = Buffer.from(type);
        const length = Buffer.alloc(4);
        writeUint32BE(length, data.length, 0);
        const crcInput = Buffer.concat([typeB, data]);
        const crcVal = Buffer.alloc(4);
        writeUint32BE(crcVal, crc32(crcInput), 0);
        return Buffer.concat([length, typeB, data, crcVal]);
    }

    const ihdr = makeChunk("IHDR", ihdrData);
    const idat = makeChunk("IDAT", compressed);
    const iend = makeChunk("IEND", Buffer.alloc(0));

    return Buffer.concat([signature, ihdr, idat, iend]);
}

const dir = path.join(__dirname, "public", "icons");
if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

fs.writeFileSync(path.join(dir, "icon-192.png"), createMinimalPng(192));
fs.writeFileSync(path.join(dir, "icon-512.png"), createMinimalPng(512));
console.log("Icons generated successfully!");
