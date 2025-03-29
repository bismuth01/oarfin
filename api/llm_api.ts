import dotenv from "dotenv";
import express from "express";
import { GoogleGenAI } from "@google/genai";
import axios from "axios";

dotenv.config();

const app = express();
const PORT = process.env.LLM_PORT;

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

app.use(express.json());

app.get("/status", (req, res) => {
  res.status(200).send("LLM API is running");
});

app.post("/disaster_news", async (req, res) => {
  console.log(req.body.news);
  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.0-flash",
      contents: `${req.body.news}\nThis is the details of a news article. ONLY ANSWER IN YES OR NO. If the news article is based on a natural disaster answer YES else NO`,
    });

    let answer: string | undefined = response.text;
    console.log(answer);

    if (answer) {
      if (answer?.length <= 3) {
        res.status(200).json({ answer: answer });
      }
    } else {
      res.status(500).send("LLM Response length error");
    }
  } catch (error) {
    console.log("LLM response error");

    res.status(500).send("LLM response error");
  }
});

app.listen(PORT, () => {
  console.log(`Listening on ${PORT}`);
});
