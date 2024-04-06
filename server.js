const express = require('express');
const app = express();
const port = 2364;

app.use(express.json());

// require database
const db = require('./database.js');
const { ok } = require('assert');

app.listen(port, () =>
{
    console.log(`Server is running on port ${port}`);
});

app.get("/", (req, res) =>
{
    res.send("Hello World!");
});

app.get("/test", (req, res) =>
{
    res.send("You've reached the api");
});


