const express = require('express');
var http = require('http');
const mongoose = require('mongoose');

const app = express();
const port = process.env.PORT || 3000;
var server = http.createServer(app);

var io = require('socket.io')(server);

// Middleware
app.use(express.json());

// DB
const DB = 'mongodb+srv://asish918:mongodb918@cluster0.0yoe2jg.mongodb.net/?retryWrites=true&w=majority';

mongoose.connect(DB).then(() => {
    console.log('Connected to MongoDB...');
}).catch((err) => {
    console.log(err);
})

server.listen(port, "0.0.0.0", () => {
    console.log(`Server started and running on PORT ${port}...`);
});