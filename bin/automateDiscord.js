const axios = require("axios").default;
const puppeteer = require("puppeteer-core");
const argv = require("yargs").argv;

const DISCORD_DEBUG_PORT = process.env.DISCORD_DEBUG_PORT;

const DISCORD_CHANNEL_NAME = process.env.DISCORD_CHANNEL_NAME || "General";
const DISCORD_SERVER_NAME = process.env.DISCORD_SERVER_NAME;

const serverXPath = `//a[@aria-label="${DISCORD_SERVER_NAME}"]`;

const connectXPath = `//div[@role="button" and contains(@aria-label, "${DISCORD_CHANNEL_NAME} (voice channel)")]`;
const disconnectXPath = '//button[@aria-label="Disconnect"]';

async function getWSEndpoint() {
  if (!DISCORD_DEBUG_PORT) {
    throw Error(
      `Environment variable DISCORD_DEBUG_PORT not found - you won't be able to connect to the Discord app without this!`
    );
  }
  const { data } = await axios.get(
    `http://localhost:${DISCORD_DEBUG_PORT}/json/version`
  );
  return data.webSocketDebuggerUrl;
}

async function doInDiscord(fn) {
  const browserWSEndpoint = await getWSEndpoint();
  const browser = await puppeteer.connect({
    browserWSEndpoint,
  });
  const pages = await browser.pages();
  const page = pages[0];
  try {
    await page.waitForXPath(serverXPath, { timeout: 9000 });
    const [serverBtn] = await page.$x(serverXPath);
    await serverBtn.click();
    await fn(page);
  } finally {
    browser.disconnect();
  }
}

async function sit() {
  await doInDiscord(async (page) => {
    await page.waitForXPath(connectXPath, { timeout: 3000 });
    const [connectBtn] = await page.$x(connectXPath);
    await connectBtn.click();
  });
}

async function stand() {
  await doInDiscord(async (page) => {
    try {
      await page.waitForXPath(disconnectXPath, { timeout: 3000 });
      const [disconnectBtn] = await page.$x(disconnectXPath);
      await disconnectBtn.click();
    } catch (err) {
      console.warn(
        "Didn't detect the disconnect button, assuming we're already disconnected."
      );
    }
  });
}

async function main() {
  if (!!argv.sit && !!argv.stand) {
    throw Error(
      "Don't specify both --sit and --stand at the same time ya dingus!"
    );
  }
  if (!argv.sit && !argv.stand) {
    throw Error("You must supply either --sit or --stand!");
  }

  if (!!argv.sit) {
    await sit();
    console.log("sat");
  } else {
    await stand();
    console.log("stood");
  }
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
