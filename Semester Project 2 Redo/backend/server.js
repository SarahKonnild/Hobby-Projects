const express = require('express');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

const sqlRouter = require('./api/sql');
app.use('/db', sqlRouter);

app.get('/', function(req, res){
    res.sendFile(__dirname + '');
})

app.listen(port, () => {
    console.log("Server is running on port: " + port);
});