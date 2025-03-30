import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import { GoogleGenAI } from "@google/genai";
import axios from "axios";

dotenv.config();

const app = express();
const PORT = process.env.LLM_PORT;

// const corsOptions = {
//   origin: `${process.env.WEBSCRAPER_URL}:${process.env.WEBSCRAPER_PORT}`,
//   methods: ["POST", "GET"],
//   optionsSuccessStatus: 200,
// };

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

//app.use(cors(corsOptions));
app.use(express.json());

app.get("/status", (req, res) => {
  res.status(200).send("LLM API is running");
});

app.post("/is_disaster_news", async (req, res) => {
  console.log(req.body);
  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.0-flash",
      contents: `Title: ${req.body.title}\n Content: ${req.body.news}\nThis is the details of a news article. ONLY ANSWER IN YES OR NO. If the news article is based on a natural disaster answer YES else NO`,
    });

    let answer: string | undefined = response.text;
    console.log(answer);

    if (answer) {
      answer = answer.trim().toUpperCase();
      if (answer.includes("YES")) {
        res.status(200).json({ answer: "YES" });
      } else if (answer.includes("NO")) {
        res.status(200).json({ answer: "NO" });
      } else {
        res.status(400).json({ error: "Invalid response format" });
      }
    } else {
      res.status(500).json({ error: "Empty LLM response" });
    }
  } catch (error) {
    console.error("LLM response error:", error);
    res.status(500).json({ error: "LLM processing error" });
  }
});

app.listen(PORT, () => {
  console.log(`Listening on ${PORT}`);
});
