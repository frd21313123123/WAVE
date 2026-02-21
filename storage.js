const fs = require("node:fs/promises");
const path = require("node:path");

class JsonStore {
  constructor(filePath, defaultData) {
    this.filePath = filePath;
    this.defaultData = defaultData;
    this.initPromise = null;
    this.queue = Promise.resolve();
    this._cache = null; // in-memory copy; null = not yet loaded
  }

  async init() {
    if (!this.initPromise) {
      this.initPromise = this.ensureFile();
    }
    return this.initPromise;
  }

  async ensureFile() {
    await fs.mkdir(path.dirname(this.filePath), { recursive: true });

    try {
      await fs.access(this.filePath);
    } catch {
      await fs.writeFile(
        this.filePath,
        JSON.stringify(this.defaultData, null, 2),
        "utf8"
      );
    }
  }

  async read() {
    await this.init();
    if (this._cache !== null) {
      return this._cache; // read-only callers (GET endpoints) don't mutate — return reference
    }
    const raw = await fs.readFile(this.filePath, "utf8");
    this._cache = JSON.parse(raw);
    return this._cache;
  }

  async write(data) {
    await this.init();
    await fs.writeFile(this.filePath, JSON.stringify(data, null, 2), "utf8");
    this._cache = data; // update cache only after a successful write
  }

  async withWriteLock(mutator) {
    this.queue = this.queue.then(async () => {
      // Clone before mutation so GET readers always see a consistent snapshot.
      const data = JSON.parse(JSON.stringify(
        this._cache !== null ? this._cache : JSON.parse(await fs.readFile(this.filePath, "utf8"))
      ));
      if (this._cache === null) this._cache = data;

      const result = await mutator(data);
      await this.write(data);
      return result;
    });

    return this.queue;
  }
}

module.exports = {
  JsonStore,
};

