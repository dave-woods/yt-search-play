const puppeteer = require('puppeteer');
const fs = require('fs');
const util = require('util');
const path = require('path');
const readFile = util.promisify(fs.readFile);

const clickLike = async (page) => {
  await page.waitForSelector('ytd-toggle-button-renderer')
  await page.click('ytd-toggle-button-renderer')
  console.log('clicked Like')
}

const clickWatchLater = async (page) => {
  await page.waitForSelector('#top-level-buttons ytd-button-renderer')
  const btn1 = await page.$$('#top-level-buttons ytd-button-renderer')
  await btn1[1].click()
  await page.waitForSelector('tp-yt-paper-checkbox')
  await page.click('tp-yt-paper-checkbox')
  console.log('watch later')
}

(async () => {
  if (process.argv.length === 4) {
    const ytUrl = process.argv[2]
    const fn = process.argv[3]
    const browser = await puppeteer.launch({slowMo: 100})
    const page = await browser.newPage()
    const cookiesString = await readFile(path.resolve(__dirname, 'cookies.json'))
    const cookies = JSON.parse(cookiesString)
    await page.setCookie(...cookies)
    await page.goto(ytUrl)
    if (fn === 'like') await clickLike(page)
    else if (fn === 'wl') await clickWatchLater(page)
    await browser.close()
  }
})()
