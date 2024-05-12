const options = { cors: true };
const httpServer = require("http").createServer();
const io = require("socket.io")(httpServer, options);
const { Field } = require("./js/backend");

const board = new Field();

let players = { 'X': "", 'O': "" };
let started = false;
let activePlayer = 'X';
let gameOver = false;

io.on ("connection", socket => {
    if (io.sockets.sockets.size > 2) {
        console.log("Pokój pełen!");
        socket.disconnect();
    }

    const sockId = socket.id;
    joinPlayers(sockId);

    const id = getKeyByValue(players, sockId);
    socket.emit('clientId', id);

    if (io.sockets.sockets.size == 2 && !started) {
        started = true;
        io.emit('start', activePlayer);
        console.log(`Zaczęto mecz o ${new Date().getTime()}`);
    }

    if (started) {
        socket.emit('continue', activePlayer, board.get());
    }

    socket.on ('turn', (turn) => {
        console.log (`Tura ${id}: ${turn.x}, ${turn.y}`);
    
        if (gameOver) {
            return;
        }
    
        switchPlayers();
        board.setField(turn.x, turn.y, id);
    
        io.emit('turn', {
            'x': turn.x,
            'y': turn.y,
            'next': activePlayer
        });
    
        overObj = board.checkGameOver(id);
        gameOver = overObj['over'];
        
        if (gameOver) {
            console.log(overObj['id'] != ' ' ? `Wygrana: ${id}!` : 'Remis!');
            io.emit('over', overObj);
    
            board.reset();
            started = false;
            gameOver = false;
        }
    });
    
    socket.on('disconnect', () => {
        let key = getKeyByValue (players, socket.id);
        players[key] = "";
    });
});

httpServer.listen(8080);
console.log('Server: 8080.');

function joinPlayers (clientId) {
    for (const k in players) {
        if (players[k] == "") {
            players[k] = clientId;
            return;
        }
    }
}

function getKeyByValue(obj, value) {
    return Object.keys(obj).find(key => obj[key] === value);
}

function switchPlayers() {
    if (activePlayer == 'X') {
        activePlayer = 'O';
    }
    else {
        activePlayer = 'X';
    }
}