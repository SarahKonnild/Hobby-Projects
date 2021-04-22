const router = require('express').Router();
const {Client} = require('pg');
const client = new Client();
await client.connect();

router.route('/db').get((req, res) => {
    client.query('SELECT * FROM movies', (err, res) => {
        console.log(res.rows);
    })
})