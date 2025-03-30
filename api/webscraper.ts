import express from "express";
import dotenv from "dotenv";
import axios from "axios";
import cors from "cors";
import { chromium, Browser, Page } from "playwright";
import cache from "./cache";

dotenv.config();

const app = express();
const PORT = process.env.WEBSCRAPER_PORT;
const LLM_URL = `${process.env.LLM_URL}:${process.env.LLM_PORT}${process.env.LLM_ENDPOINT}`;

const USER_AGENT =
  "Mozilla/5.0 (compatible; OarfinBot/1.0; +http://www.yourdomain.com)";
const REDDIT_API_HEADERS = {
  "User-Agent": USER_AGENT,
  Accept: "application/json",
};

const CACHE_KEYS = {
  BBC: "bbc_news",
  NDTV: "ndtv_news",
  REDDIT: "reddit_news",
};

const CACHE_TTL = {
  BBC: 300,
  NDTV: 300,
  REDDIT: 120,
};

app.use(express.json());
app.use(cors());

interface ArticleContent {
  title: string;
  content: string;
}

interface Article {
  url: string;
  title: string;
  content: string;
}

interface RedditPost {
  title: string;
  type: string;
  post_link: string;
  reddit_link: string;
  thumbnail: string;
  created: string;
}

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function is_disaster_news({
  title,
  content,
}: ArticleContent): Promise<string> {
  try {
    const response = await axios.post(
      LLM_URL,
      { title, content },
      {
        headers: {
          Origin: `${process.env.WEBSCRAPPER_URL}:${process.env.WEBSCRAPER_PORT}`,
        },
      },
    );
    return response.data.answer;
  } catch (error) {
    console.error("LLM API Error:", error);
    throw new Error("Failed to check if content is disaster news");
  }
}

async function scrapePage(browser: Browser, url: string): Promise<Article[]> {
  const page = await browser.newPage();
  const articles: Article[] = [];

  try {
    await page.goto(url, { waitUntil: "domcontentloaded" });
    return articles;
  } catch (error) {
    console.error(`Error scraping page ${url}:`, error);
    throw error;
  } finally {
    await page.close();
  }
}

app.get("/status", (req, res) => {
  res.status(200).json({ status: "Webscraper API Running" });
});

app.get("/bbc_news", async (req, res) => {
  try {
    const cachedData = cache.get(CACHE_KEYS.BBC);
    if (cachedData) {
      console.log("Serving BBC news from cache");
      res.status(200).json(cachedData);
      return;
    }

    const browser: Browser = await chromium.launch({
      headless: true,
      args: [
        "--disable-dev-shm-usage",
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-gpu",
      ],
    });

    try {
      const page = await browser.newPage();
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

      const articles: Article[] = [];
      for (const url of article_urls) {
        try {
          await page.goto(url, { waitUntil: "domcontentloaded" });
          const title = await page.title();
          const articleContent = await page.$$eval("article p", (paragraphs) =>
            paragraphs.map((p) => p.textContent?.trim()).filter(Boolean),
          );

          articles.push({
            url,
            title,
            content: articleContent.join(" "),
          });
        } catch (error) {
          console.error(`Error processing BBC article ${url}:`, error);
        }
      }

      const filtered_articles = [];
      for (const article of articles) {
        try {
          if ((await is_disaster_news(article)) === "YES") {
            filtered_articles.push(article);
          }
          await sleep(2000);
        } catch (error) {
          console.error("Error filtering article:", error);
        }
      }

      cache.set(CACHE_KEYS.BBC, filtered_articles, CACHE_TTL.BBC);
      res.status(200).json(filtered_articles);
    } finally {
      await browser.close();
    }
  } catch (error) {
    console.error("BBC scraping error:", error);
    res.status(500).json({ error: "Failed to scrape BBC news" });
  }
});

app.get("/ndtv_news", async (req, res) => {
  try {
    const cachedData = cache.get(CACHE_KEYS.NDTV);
    if (cachedData) {
      console.log("Serving NDTV news from cache");
      res.status(200).json(cachedData);
      return;
    }

    const browser: Browser = await chromium.launch({
      headless: true,
      args: [
        "--disable-dev-shm-usage",
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-gpu",
      ],
    });

    try {
      const page = await browser.newPage();
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

      const articles: Article[] = [];
      for (const url of article_urls) {
        try {
          await page.goto(url, { waitUntil: "domcontentloaded" });
          const title = await page.title();
          const intro = page.locator("div.Art-exp_wr p");
          const articleContent = await Promise.all(
            (await intro.all()).map(async (content) => content.textContent()),
          );

          articles.push({
            url,
            title,
            content: articleContent.filter(Boolean).join(" "),
          });
        } catch (error) {
          console.error(`Error processing NDTV article ${url}:`, error);
        }
      }

      const filtered_articles = [];
      for (const article of articles) {
        try {
          if ((await is_disaster_news(article)) === "YES") {
            filtered_articles.push(article);
          }
          await sleep(2000);
        } catch (error) {
          console.error("Error filtering article:", error);
        }
      }

      cache.set(CACHE_KEYS.NDTV, filtered_articles, CACHE_TTL.NDTV);
      res.status(200).json(filtered_articles);
    } finally {
      await browser.close();
    }
  } catch (error) {
    console.error("NDTV scraping error:", error);
    res.status(500).json({ error: "Failed to scrape NDTV news" });
  }
});

app.get("/reddit_news", async (req, res) => {
  try {
    const cachedData = cache.get(CACHE_KEYS.REDDIT);
    if (cachedData) {
      console.log("Serving Reddit news from cache");
      res.status(200).json(cachedData);
      return;
    }

    const response = await axios.get(
      "https://www.reddit.com/r/DisasterUpdate.json",
      {
        headers: REDDIT_API_HEADERS,
        timeout: 10000,
      },
    );

    const posts: RedditPost[] = response.data.data.children.map(
      (post: any) => ({
        title: post.data.title,
        type: post.data.is_video ? "video" : "image",
        post_link: post.data.url,
        reddit_link: `https://reddit.com${post.data.permalink}`,
        thumbnail: post.data.thumbnail,
        created: new Date(post.data.created_utc * 1000).toISOString(),
      }),
    );

    cache.set(CACHE_KEYS.REDDIT, posts, CACHE_TTL.REDDIT);
    res.status(200).json(posts);
  } catch (error) {
    console.error("Reddit API Error:", error);
    res.status(500).json({ error: "Failed to fetch Reddit posts" });
  }
});

app.get("/cache-stats", (req, res) => {
  const stats = cache.getStats();
  const keys = cache.keys();
  const cacheInfo = Object.fromEntries(
    keys.map((key) => [
      key,
      {
        ttl: cache.getTtl(key),
        expiresIn: Math.round(((cache.getTtl(key) || 0) - Date.now()) / 1000),
      },
    ]),
  );

  res.status(200).json({ stats, activeKeys: cacheInfo });
});

app.listen(PORT, () => {
  console.log(`Webscraper API listening on port ${PORT}`);
});
