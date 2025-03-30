import express from "express";
import dotenv from "dotenv";
import axios from "axios";
import cors from "cors";
import { chromium, Browser, Page } from "playwright";

dotenv.config();

const app = express();
const PORT = process.env.WEBSCRAPER_PORT;
const LLM_URL = `${process.env.LLM_URL}:${process.env.LLM_PORT}${process.env.LLM_ENDPOINT}`;

// const corsOptions = {
//   origin: process.env.FRONTEND_URL,
//   methods: ["GET"],
//   optionsSuccessStatus: 200,
// };

// app.use(cors(corsOptions));
app.use(express.json());

interface ArticleContent {
  title: string;
  content: string;
}

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function is_disaster_news({
  title,
  content,
}: ArticleContent): Promise<string> {
  const response = await axios.post(
    LLM_URL,
    {
      title: title,
      content: content,
    },
    {
      headers: {
        Origin: `${process.env.WEBSCRAPPER_URL}:${process.env.WEBSCRAPER_PORT}`,
      },
    },
  );

  return response.data.answer;
}

app.get("/status", (req, res) => {
  res.status(200).send("Webscrapper API Running");
});

app.get("/bbc_news", async (req, res) => {
  const browser: Browser = await chromium.launch({
    headless: true,
  });

  const page: Page = await browser.newPage();

  try {
    await page.goto("https://bbc.com/future-planet", {
      waitUntil: "domcontentloaded",
    });

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
          await page.goto(url, { waitUntil: "domcontentloaded" });

          const title = await page.title();
          const articleContent = await page.$$eval("article p", (paragraphs) =>
            paragraphs.map((p) => p.textContent?.trim()).filter(Boolean),
          );

          articles.push({
            url: url,
            title: title,
            content: articleContent.join(" "),
          });

          console.log(articles);
        } catch (error) {
          console.log(`Error processing article ${url}: ${error}`);
        }
      }
    }

    const filtered_article = [];
    for (const article of articles) {
      if (
        (await is_disaster_news({
          title: article.title,
          content: article.content,
        })) === "YES"
      ) {
        filtered_article.push(article);
      }
      await sleep(2000);
    }

    await page.close();
    await browser.close();
    res.status(200).json(filtered_article);
  } catch (error) {
    res.status(500).send(`Scraping internal error ${error}`);
  }
});

app.get("/ndtv_news", async (req, res) => {
  const browser: Browser = await chromium.launch({
    headless: true,
  });

  const page: Page = await browser.newPage();

  try {
    await page.goto("https://www.ndtv.com/world", {
      waitUntil: "domcontentloaded",
    });

    const article_urls: string[] = await page.$$eval(
      "a[data-tb-title]",
      (links) =>
        links
          .map((link) => (link as HTMLAnchorElement).href)
          .filter((url) => url.includes("/world-news/")),
    );

    console.log(`${article_urls.length} Articles found`);
    const articles = [];

    for (const url of article_urls) {
      console.log(url);
      if (url) {
        try {
          await page.goto(url, { waitUntil: "domcontentloaded" });

          const title = await page.title();
          const intro = page.locator("div.Art-exp_wr p");

          const articleContent: string[] = [];
          for (const content of await intro.all()) {
            articleContent.push((await content.textContent()) as string);
          }

          articles.push({
            url: url,
            title: title,
            content: articleContent.join(" "),
          });

          console.log(articles);
        } catch (error) {
          console.log(`Error processing article ${url}: ${error}`);
        }
      }
    }

    const filtered_article = [];
    for (const article of articles) {
      if (
        (await is_disaster_news({
          title: article.title,
          content: article.content,
        })) === "YES"
      ) {
        filtered_article.push(article);
      }
      await sleep(2000);
    }

    await page.close();
    await browser.close();
    res.status(200).json(filtered_article);
  } catch (error) {
    res.status(500).send(`Scraping internal error ${error}`);
  }
});

app.get("/reddit_news", async (req, res) => {
  try {
    const response = await axios.get(
      "https://www.reddit.com/r/DisasterUpdate.json",
    );

    const posts = [];
    for (const post of response.data.data.children) {
      const title = post.data.title;
      const type = post.data.is_video === true ? "video" : "image";
      const post_link = post.data.url;

      posts.push({
        title: title,
        type: type,
        post_link: post_link,
      });
    }

    res.status(200).json(posts);
  } catch (error) {
    res.status(500).send(`Scraping internal error ${error}`);
  }
});

app.listen(PORT, () => {
  console.log(`Listening on ${PORT}`);
});
