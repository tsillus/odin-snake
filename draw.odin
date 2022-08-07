package snake;

import rl "vendor:raylib"
import "core:strings"
import "core:time"
import c "core:c/libc"
import "core:testing"
import "core:fmt"


Vector :: struct {
    x: c.int,
    y: c.int,
}

TextAnimation :: struct {
    text            : cstring,
    start           : Vector,
    delta           : Vector,
    start_time      : time.Time,
    duration        : time.Duration,
    start_color     : rl.Color,
    end_color       : rl.Color,
    start_font_size : c.int,
    end_font_size   : c.int,

}

add_animation :: proc(animations: ^[dynamic]TextAnimation, text: string, 
    start, delta: Vector, 
    start_time: time.Time, duration: time.Duration, 
    start_color, end_color: rl.Color, 
    start_font_size, end_font_size: c.int) {
    animation := TextAnimation{
        text            = strings.clone_to_cstring(text),   // usually "+1" .. "+15". leaks 4 bytes
        start           = start,
        delta           = delta,
        start_time      = start_time,
        duration        = duration,
        start_color     = start_color,
        end_color       = end_color,
        start_font_size = start_font_size,
        end_font_size   = end_font_size,
    }

    append_elem(animations, animation)
}

draw_animations :: proc(animations: ^[dynamic]TextAnimation) {
    now := time.now()
    expired_animations := [dynamic]int{}
    defer delete(expired_animations)
    for i := 0; i < len(animations); i += 1 {
        animation := animations[i]
        using animation

        if start_time._nsec > now._nsec do continue
        if time.time_add(start_time, duration)._nsec < now._nsec{
            append_elem(&expired_animations, i)
            continue  
        } 


        time_passed := time.diff(animation.start_time, now)
        progress := f32(time_passed) / f32(animation.duration)
        
        d_x : c.int = auto_cast ( f32(start.x) + progress * f32(delta.x))
        d_y : c.int = auto_cast ( f32(start.y) + progress * f32(animation.delta.y))

        d_font_size : c.int = auto_cast ( f32(start_font_size) + progress * f32(end_font_size - start_font_size) )

        d_color : rl.Color = rl.Color{
            r = auto_cast ( f32(start_color.r) + progress * f32(end_color.r - start_color.r)),
            g = auto_cast ( f32(start_color.g) + progress * f32(end_color.g - start_color.g)),
            b = auto_cast ( f32(start_color.b) + progress * f32(end_color.b - start_color.b)),
            a = auto_cast ( f32(start_color.a) + progress * f32(end_color.a - start_color.a)),
        }

        // proc(text: cstring, posX, posY: c.int, fontSize: c.int, color: Color)
        rl.DrawText(text, d_x, d_y, d_font_size, d_color)
    }

    for i := len(expired_animations) -1; i >= 0; i -= 1 {
        index := expired_animations[i]
        fmt.println("removing TextAnimation", animations[i].text)
        delete_cstring(animations[i].text)
        ordered_remove(animations, index)
    }
}

// @(test)
// test_draw_animations :: proc(t : ^testing.T) {
//     animations := [dynamic]TextAnimation{}
//     // add_animation(&animations, )
// }

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