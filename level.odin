package snake;

Level :: struct {
    width: i32,
    height: i32,
    cells: []Tile,
}

Tile :: enum { 
    Floor, Wall,
}

init_level :: proc(level: ^Level) {
    width := level.width
    height := level.height

    for x:i32 =0; x < width; x+=1 {
        for y: i32 =0; y < height; y+=1 {
            if x == 0 || x == width -1 || y == 0 || y == height -1 {
                index : int = auto_cast (x * width + y)

                level.cells[index] = Tile.Wall
            }
        }
    }
}

get_cell_value :: proc(level: ^Level, x:int, y:int) -> Tile {
    width : int = auto_cast level.width
    return level.cells[x*width + y]
}