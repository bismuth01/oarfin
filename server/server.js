import dotenv from 'dotenv';
dotenv.config();
console.log('Environment variables loaded');

import express from "express";
import axios from "axios";
import cors from "cors";
import { GoogleGenAI } from "@google/genai";
import {MongoClient} from "mongodb";
import sqlite3 from "sqlite3";
const app = express();
app.use(express.json());
app.use(cors());
app.use(express.urlencoded({
    extended: true}))
    const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
// data base integration
const db = new sqlite3.Database('sample.db');

app.get("/create_table", async (req, res) => {
    try {
db.serialize(() => {
  db.run('CREATE TABLE Disaster (eventID INTEGER PRIMARY KEY NOT NULL,latitude REAL NOT NULL,longitude REAL NOT NULL)');
  
});

res.status(200).send("table created");
             }
    catch (error) {
        res.status(500).json({ error: "Failed to fetch data" });
    }
    });

app.post('/websitelink', (req, res) => {
    const { eventID, latitude, longitude } = req.body;

    if (!eventID || !latitude || !longitude) {
        return res.status(400).json({ error: "eventID, Latitude and longitude are required" });
    }

    // 1. Prepare and execute the statement with parameters
    const stmt = db.prepare('INSERT INTO Disaster (eventID, latitude, longitude) VALUES (?, ?, ?)');
    stmt.run(eventID, latitude, longitude, function(err) {
        if (err) {
            return res.status(500).json({ error: err.message });
        }

        // 2. After successful insert, query the data
        db.all('SELECT eventID, latitude, longitude FROM Disaster', (err, rows) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            
            // 3. Log each row
            rows.forEach(row => {
                console.log(`ID: ${row.eventID}, Latitude: ${row.latitude}, Longitude: ${row.longitude}`);
            });

            res.json({ message: 'Data received and stored successfully' });
        });
    });
});
app.get("/get-all-disasters", (req, res) => {
    const sql = "SELECT * FROM disaster";
    
    db.all(sql, [], (err, rows) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json(rows);
    });
});
//start server
const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));