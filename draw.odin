package snake;

import rl "vendor:raylib"

draw_snake_tail :: proc(tail : ^[dynamic]SnakeBody, body_size: i32) {
    for body in tail {
        rl.DrawRectangle(body.pos_x * body_size, body.pos_y * body_size, body_size, body_size, rl.GOLD)
    }
}

draw_snake_head :: proc(head: ^SnakeHead, body_size: i32) {
    rl.DrawRectangle(head.pos_x * body_size, head.pos_y * body_size, body_size, body_size, rl.GREEN)
}
draw_apple :: proc(apple: ^Apple, body_size: i32) {
    rl.DrawRectangle(apple.pos_x * body_size, apple.pos_y * body_size, body_size, body_size, rl.RED)
}

draw_level :: proc(level: ^Level, body_size: i32) {
    width := level.width
    height := level.height

    for x : i32 = 0; x < width; x+=1 {
        for y : i32 = 0; y < height; y+=1 {
            index :int = auto_cast (x * width + y)
            if level.cells[index] == Tile.Wall {

                xpos : i32 = auto_cast x
                ypos : i32 = auto_cast y
                rl.DrawRectangle(
                    xpos * body_size, 
                    ypos * body_size, 
                    body_size, 
                    body_size, 
                    rl.LIGHTGRAY)
            }
        }
    }
}