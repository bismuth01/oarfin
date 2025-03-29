import express from "express";

const app = express();
const PORT = 8080;

app.use(express.json());

app.get("/", (req, res) => {
  res.send("LLM API is running");
});

app.listen(PORT, () => {
  console.log(`Starting on ${PORT}`);
});
