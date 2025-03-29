import express from "express";
import dotenv from "dotenv";
import axios from "axios";
import { chromium, Browser, Page } from "playwright";

dotenv.config();

const app = express();
const PORT = process.env.WEBSCRAPER_PORT;
app.use(express.json());

app.get("/status", (req, res) => {
  res.status(200).send("Webscrapper Running");
});

app.post("/bbc_news", async (req, res) => {
  const browser: Browser = await chromium.launch({
    headless: true,
  });

  const page: Page = await browser.newPage();

  try {
    await page.goto("https://bbc.com/future-planet");

    const article_urls: string[] = await page.$$eval(
      'a[href*="/news/articles"]',
      (links) =>
        links
          .map((link) => (link as HTMLAnchorElement).href)
          .filter((url) => url.includes("/news/articles")),
    );

    console.log(`${article_urls.length} Articles found`);
    const articles = [];

    for (const url of article_urls) {
      console.log(url);
      if (url) {
        try {
          await page.goto(url);

          const title = await page.title();
          const articleContent = await page.$$eval("article p", (paragraphs) =>
            paragraphs.map((p) => p.textContent?.trim()).filter(Boolean),
          );

          articles.push({
            title: title,
            content: articleContent.join(" "),
          });

          console.log(articles);
        } catch (error) {
          console.log(`Error processing article ${url}: ${error}`);
        }
      }
    }

    await page.close();
    await browser.close();
    res.status(200).json(articles);
  } catch (error) {
    res.status(500).send(`Scraping internal error ${error}`);
  }
});

app.listen(PORT, () => {
  console.log(`Listening on ${PORT}`);
});
