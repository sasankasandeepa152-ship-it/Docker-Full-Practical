
import express from "express";
import fs from "node:fs";
import path from "node:path";

const app = express();

const PORT = Number(process.env.PORT || 3000);
const APP_VERSION = process.env.APP_VERSION || "1.0.0";

const DATA_DIR =
    process.env.DATA_DIR || path.join(process.cwd(), "data");

const COUNT_FILE = path.join(DATA_DIR, "visits.txt");

// Home page
app.get("/", (_req, res) => {
    res.send(`
        <h1>My First Production Docker App</h1>
        <p>Application Version: ${APP_VERSION}</p>
        <p>Port: ${PORT}</p>
        <ul>
            <li><a href="/health">Health Check</a></li>
            <li><a href="/visit">Visit Counter</a></li>
        </ul>
    `);
});

// Health endpoint
app.get("/health", (_req, res) => {
    res.status(200).json({
        status: "healthy"
    });
});

// Visit counter - saves data in a volume
app.get("/visit", (_req, res) => {
    fs.mkdirSync(DATA_DIR, { recursive: true });

    let visits = 0;

    if (fs.existsSync(COUNT_FILE)) {
        visits = Number(
            fs.readFileSync(COUNT_FILE, "utf8")
        ) || 0;
    }

    visits += 1;

    fs.writeFileSync(
        COUNT_FILE,
        String(visits),
        "utf8"
    );

    res.json({
        totalVisits: visits
    });
});

// Start server
app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
});
