const axios = require("axios").default;
const puppeteer = require("puppeteer-core");
const yargs = require("yargs");
const { hideBin } = require("yargs/helpers");

async function getWSEndpoint(port) {
  if (!port) {
    throw Error(
      `No debugging port specified - you won't be able to connect to the Discord app without this!`
    );
  }
  const { data } = await axios.get(`http://localhost:${port}/json/version`);
  return data.webSocketDebuggerUrl;
}

async function doInDiscord(port, server, fn) {
  const serverXPath = `//div[contains(@aria-label, "Servers")]//div[@role="treeitem" and contains(@aria-label, "${server}")]`;

  const browserWSEndpoint = await getWSEndpoint(port);
  const browser = await puppeteer.connect({
    browserWSEndpoint,
    defaultViewport: null,
  });
  const pages = await browser.pages();
  const page = pages[0];
  try {
    const serverBtn = await page.waitForXPath(serverXPath, {
      timeout: 9000,
    });
    await serverBtn.evaluate((btn) => btn.click());
    await fn(page);
  } finally {
    browser.disconnect();
  }
}

async function sit(port, server, channel) {
  const connectXPath = `//*[@role="button" and contains(@aria-label, "${channel} (voice channel)")]`;
  await doInDiscord(port, server, async (page) => {
    const connectBtn = await page.waitForXPath(connectXPath, {
      timeout: 3000,
    });
    await connectBtn.evaluate((btn) => btn.click());
    // Wait a half-second before clicking again to go to the video pane
    await page.waitForTimeout(500);
    await connectBtn.evaluate((btn) => btn.click());
  });
}

async function stand(port, server) {
  const disconnectXPath = '//button[@aria-label="Disconnect"]';
  await doInDiscord(port, server, async (page) => {
    try {
      const disconnectBtn = await page.waitForXPath(disconnectXPath, {
        timeout: 3000,
      });

      await disconnectBtn.evaluate((btn) => btn.click());
    } catch (err) {
      console.warn(
        "Didn't detect the disconnect button, assuming we're already disconnected."
      );
    }
  });
}

async function main() {
  const args = yargs(hideBin(process.argv)).argv;

  const { port, server, channel } = args;

  if (!!args.sit && !!args.stand) {
    throw Error(
      "Don't specify both --sit and --stand at the same time ya dingus!"
    );
  }
  if (!args.sit && !args.stand) {
    throw Error("You must supply either --sit or --stand!");
  }

  if (!!args.sit) {
    await sit(port, server, channel || "General");
    console.log("sat");
  } else {
    await stand(port, server);
    console.log("stood");
  }
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
