const mysql = require('mysql');

const db = mysql.createConnection({
  host     : 'localhost',
  port     : '3306',
  user     : 'dev',
  password : 'password',
  database : 'projectgg_db'
});

db.connect(err => {
  if (err) {
    console.error('Error connecting to MySQL: ' + err.stack);
    return;
  }
  console.log('Connected to MySQL as id ' + db.threadId);
});

module.exports = db;