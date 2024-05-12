class Field {
    empty = ' ';
    field = [
        [this.empty, this.empty, this.empty],
        [this.empty, this.empty, this.empty],
        [this.empty, this.empty, this.empty]
    ];

    get () { return this.field;}

    reset () {
        this.field = [
            [this.empty, this.empty, this.empty],
            [this.empty, this.empty, this.empty],
            [this.empty, this.empty, this.empty]
        ];
    }

    getField (x, y) { return this.field[y][x]; }
    setField (x, y, what) { this.field[y][x] = what; }

    checkForWin (what) { 
        // columns
        for (let index = 0; index < 3; index++) {
            if (this.field[0][index] == what && this.field[1][index] == what && this.field[2][index] == what) {
                console.log('A'); //////////////////////
                return true;
            }
        }

        // rows
        for (let index = 0; index < 3; index++) {
            if (this.field[index][0] == what && this.field[index][1] == what && this.field[index][2] == what) {
                console.log('B'); //////////////////////
                return true;
            }
        }
        
        

        if (
            (this.field[0][0] == what && this.field[1][1] == what && this.field[2][2] == what) ||
            (this.field[2][0] == what && this.field[1][1] == what && this.field[0][2] == what)
        ) {
            console.log('C'); //////////////////////
            return true;
        }

        return false;
    }

    draw () {
        for (let y = 0; y < 3; y++) {
            for (let x = 0; x < 3; x++) {
                if (this.field[y][x] == this.empty) {
                    return false;
                }
            }
        }

        return true;
    }

    checkGameOver(id) {
        let fieldFull = this.draw();            
        let win = this.checkForWin(id);

        return {
            "over": (fieldFull || win),
            "id": win ? id : ' '
        };
    }
}

module.exports.Field = Field;