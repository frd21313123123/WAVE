const fs = require("node:fs/promises");
const path = require("node:path");

class JsonStore {
  constructor(filePath, defaultData) {
    this.filePath = filePath;
    this.defaultData = defaultData;
    this.initPromise = null;
    this.queue = Promise.resolve();
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
    const raw = await fs.readFile(this.filePath, "utf8");
    return JSON.parse(raw);
  }

  async write(data) {
    await this.init();
    await fs.writeFile(this.filePath, JSON.stringify(data, null, 2), "utf8");
  }

  async withWriteLock(mutator) {
    this.queue = this.queue.then(async () => {
      const data = await this.read();
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

