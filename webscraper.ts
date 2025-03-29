import express from "express";
import dotenv from "dotenv";
import axios from "axios";

const app = express();
const PORT = process.env.WEBSCRAPER_PORT;

app.get("/", (req, res) => {
  res.status(200).send("Webscrapper Running");
});

app.listen(PORT, () => {
  console.log(`Listening on ${PORT}`);
});
