const express = require('express');
var http = require('http');
const mongoose = require('mongoose');
const Room = require('./models/Room');
const getWord  = require('./api/getWord')

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

io.on('connection', (socket) => {
    console.log("Connected to socket.io...");
    socket.on('create-game', async({nickname, name, occupancy, maxRounds}) => {
        try {
            const existingRoom = await Room.findOne(name);
            if(existingRoom){
                socket.emit('notCorrectGame', 'Room with that name already exists!');
                return;
            }

            let room = new Room();
            const word = getWord(); 
            room.word = word;
            room.name = name;
            room.occupancy = occupancy;
            room.maxRounds = maxRounds;

            let player = {
                socketID: socket.id,
                nickname,
                isPartyLeader: true,
            }
            room.players.push(player);
            room = await room.save();
            socket.join(room);
            io.to(name).emit('updateRoom', room);
        } catch (error) {
            console.log(error);
        }
    })
})

server.listen(port, "0.0.0.0", () => {
    console.log(`Server started and running on PORT ${port}...`);
});