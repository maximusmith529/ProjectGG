const express = require('express');
const cors = require('cors');

const app = express();
const port = 2364;


app.use(express.json());
app.use(cors());
app.set('view engine', 'ejs');

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


// *=============================================================*
// |                         User Signup                         |
// *=============================================================*
// incoming {username, password}
// outgoing { status }
app.post("/api/users/signup", (req, res) =>{
    const {username, password} = req.body;
    if (!username || !password){
        res.status(400).send("Username and password required");
        return;
    }

    //var data = sanatizeData([username, password]);

    const sql = "CALL create_user_login(?, ?)";
    const params = [username, password];
	db.query(sql, params, function (err, result) {
        if(err){
            return res.status(400).json({error: "SQLError"});
        }

        const response = result[0][0];

        if(response.RESPONSE_STATUS == "ERROR"){
            return res.status(400).json({error: response.RESPONSE_MESSAGE});
        }
        return res.status(200).json({});
    });
});

// *=============================================================*
// |                         User Login                          |
// *=============================================================*
// incoming {username, password}
// outgoing { status, token }
app.post("/api/users/login", (req, res) =>{
    const {username, password} = req.body;
    if (!username || !password){
        res.status(400).send("Username and password required");
        return;
    }

    //var data = sanatizeData([username, password]);

    const sql = "CALL login_user(?, ?)";
    const params = [username, password];
    db.query(sql, params, (err, result) =>{
        if(err){
            return res.status(400).json({error: "SQLError"});
        }

        const response = result[0][0];

        if(response.RESPONSE_STATUS == "ERROR"){
            return res.status(400).json({error: response.RESPONSE_MESSAGE});
        }
        return res.status(200).json(response.RESPONSE_MESSAGE);

        // login_user returns the tokenid for a user's session, return a json of the response and add it to the header
        console.log("Token created: " + response.RESPONSE_MESSAGE);
        res.cookie('name', 'geeksforgeeks');
        res.send("Cookie Set");
        return res.status(200).json({ token: response.RESPONSE_MESSAGE });
    });
});

// *=============================================================*
// |                       Get All Users                         |
// *=============================================================*
// incoming {  }
// outgoing { status }
app.get("/api/users", (req, res) => {
    db.query("SELECT * FROM USER_LOGIN", (err, rows) => {
        if (err) {
            res.status(400).json({ error: err.message });
            return;
        }
        res.json({
            message: "success",
            data: rows,
        });
    });
});

// *=============================================================*
// |                     Get All User Tokens                     |
// *=============================================================*
// incoming {  }
// outgoing { status }
app.get("/api/tokens", (req, res) =>
{
    db.query("SELECT * FROM USER_TOKEN",
        (err, rows) =>
        {
            if (err)
            {
                res.status(400).json({ error: err.message });
                return;
            }
            res.json({
                message: "success",
                data: rows,
            });
        });
}
);

// get games, and then get all reviews
app.get("/api/games", (req, res) =>
{
    db.query("SELECT * FROM GAME", (err, rows) =>
    {
        if (err)
        {
            res.status(400).json({ error: err.message });
            return;
        }
        res.json({
            message: "success",
            data: rows,
        });
    });
});

// get all reviews
app.get("/api/reviews", (req, res) =>
{
    db.query("SELECT * FROM REVIEW", (err, rows) =>
    {
        if (err)
        {
            res.status(400).json({ error: err.message });
            return;
        }
        res.json({
            message: "success",
            data: rows,
        });
    });
});

// get all reviews for a game
app.get("/api/games/:gameID/reviews", (req, res) =>
{
    const gameID = req.params.gameID;
    db.query("SELECT * FROM REVIEW WHERE GAME= ?", [gameID], (err, rows) =>
    {
        if (err)
        {
            res.status(400).json({ error: err.message });
            return;
        }
        res.json({
            message: "success",
            data: rows,
        });
    });
});

// get all reviews from a user
app.get("/api/users/:userID/reviews", (req, res) =>
{
    const userID = req.params.userID;
    db.query("SELECT * FROM REVIEW WHERE USER= ?", [userID], (err, rows) =>
    {
        if (err)
        {
            res.status(400).json({ error: err.message });
            return;
        }
        res.json({
            message: "success",
            data: rows,
        });
    });
});

app.get('/index', (req, res) => {
    res.render('index');
});

app.get('/profile', (req, res) => {
    res.render('profile');
});

app.get('/signup', (req, res) => {
    res.render('signup');
});

app.get('/gamepage', (req, res) => {
    res.render('gamepage');
});

app.get('/gamesearch', (req, res) => {
    db.query("SELECT * FROM GAME", (err, rows) =>
    {
        if (err)
        {
            res.status(400).json({ error: err.message });
            return;
        }
        res.render('gamesearch', {games: rows});
    });
});

// select name from all games
app.get('/games', (req, res) => {
    db.query("SELECT * FROM GAME", (err, rows) =>
    {
        if (err)
        {
            res.status(400).json({ error: err.message });
            return;
        }
        res.json({
            message: "success",
            data: rows[0].GAMEPICTURE
        });
    });
});