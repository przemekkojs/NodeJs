//const socket = io("ws://54.90.217.103:8080/");
let clientId;
let activeId;

let nickname = window.prompt('Podaj nazwę użytkownika', "")
document.getElementById('username').innerText = `Witaj, ${nickname}`;

socket.on('clientId', (id) => {
    clientId = id;  
});

socket.on('start', (startId) => {
    activeId = startId;

    document.getElementById('current-turn').classList.remove('hide');
    document.getElementById('clientId').innerHTML = clientId == startId ? 'Twój ruch' : 'Ruch przeciwnika';
});

socket.on('continue', (active, board) => {
    activeId = active;

    for (y = 0; y < board.length; y++) {
        for (x = 0; x < board.length; x++) {
            setPool (x, y, board[y][x]);
        }
    }

    document.getElementById('current-turn').classList.remove('hide');
    document.getElementById('clientId').innerHTML = (clientId == activeId ? 'Twój ruch' : 'Ruch przeciwnika');
});

socket.on('turn', (turn) => {
    const {x, y, next} = turn;
    let good = setPool (x, y, activeId);
    
    if (!good) {
        return;
    }

    activeId = next;
    document.getElementById('clientId').innerHTML = (clientId == activeId ? 'Twój ruch' : 'Ruch przeciwnika');
});

socket.on('over', (overObj) => {
    winnerId = overObj['id'];

    if (winnerId != 0) {
        document.getElementById('winnerId').innerHTML = clientId == winnerId ? 'Wygrana!' : 'Przegrana!';
    }
    else {
        document.getElementById('winnerId').innerHTML = 'Remis!';
    }

    socket.disconnect();

    document.getElementById('popup').classList.remove('hide');
    document.getElementById('current-turn').classList.add('hide');
});

function setPool (x, y, id) {
    let pool = getPool(x, y);
    if (pool.innerText != 'X' && pool.innerText != 'O') { 
        pool.innerText = id; 
        return true;
    }

    return false;
}

function getPool(x, y) {
    return document.getElementById(`x${x}y${y}`)
}

function restart() {
    window.location.reload();
}

function turn (x, y) {
    console.log(`Turn ${clientId}: (${x}, ${y})`)

    if (activeId != clientId) {
        return;
    }

    if (getPool(x, y).innerText == 'X' || getPool(x, y).innerText == 'O') {
        return;
    }

    console.log('send');
    socket.emit('turn', {
        'x' : x,
        'y' : y
    });
}