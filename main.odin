package snake;

import rl "vendor:raylib"
import "core:time"
import "core:fmt"
import c "core:c/libc"
import mem "core:mem"



Apple :: struct {
    pos_x: i32,
    pos_y: i32,
    spawned: time.Time,
    ttl: time.Duration,
}

respawn_apple:: proc(apple:^Apple) {
    
    apple.pos_x = c.rand() % 30
    apple.pos_y = c.rand() % 30
}

GameState :: enum {
    Init, Running, Paused, Fail, GameOver,
}

WINDOW_WIDTH  : i32 = 1200
WINDOW_HEIGHT : i32 = 900


main :: proc() {

    tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracker, context.allocator)
    defer mem.tracking_allocator_destroy(&tracker)
    context.allocator = mem.tracking_allocator(&tracker)
    defer if len(tracker.allocation_map) > 0 {
        fmt.eprintln()
        for _, v in tracker.allocation_map {
            fmt.eprintf("%v - leaked %v bytes\n", v.location, v.size)
        }
    }

    using rl
    last_tick := time.now()

    flags: ConfigFlags = { .WINDOW_RESIZABLE }
    SetWindowState(flags)

    InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Snake!")
    SetTargetFPS(60)

    game_map := Level{30,30, make([]Tile, 30*30)}
    defer delete(game_map.cells)

    body_size : i32 = WINDOW_HEIGHT / game_map.width

    tick : time.Duration = 500 * time.Millisecond   // game tick length

    game_state := GameState.Init

    head: SnakeHead;
    tail: [dynamic]SnakeBody;
    apple: Apple;

    for !WindowShouldClose() {

        switch game_state {
            case .Init: {
                init_level(&game_map)
                
                head, tail = new_snake(15, 15, 0, -1, 5)
                apple = Apple{pos_x=1,pos_y=2,spawned=last_tick,ttl=15 * time.Second}
                last_tick = time.now()
                game_state = .Running
                fallthrough
            }

            case .Running: {
                // 1. Handle events

                #partial switch key : KeyboardKey = GetKeyPressed(); key {
                    case .DOWN:  { head.dir_h =  0; head.dir_v =  1}
                    case .UP:    { head.dir_h =  0; head.dir_v = -1}
                    case .LEFT:  { head.dir_h = -1; head.dir_v =  0}
                    case .RIGHT: { head.dir_h =  1; head.dir_v =  0}
                }

                // 2. Update Game state
                now := time.now()
                if time.diff(last_tick, now) > tick {
                    append_elem(&tail, SnakeBody{head.pos_x, head.pos_y})

                    if len(tail) >= auto_cast head.length do ordered_remove(&tail, 0)

                    head.pos_x = head.pos_x + head.dir_h
                    head.pos_y = head.pos_y + head.dir_v

                    last_tick = now
                }

                // 3. Collision Detection
                if get_cell_value(&game_map, auto_cast head.pos_x, auto_cast head.pos_y) != Tile.Floor {
                    game_state = .Fail
                    continue
                }
                for body, index in tail {
                    if body.pos_x == head.pos_x && body.pos_y == head.pos_y {
                        game_state = .Fail
                        continue
                    }
                }
                if head.pos_x == apple.pos_x && head.pos_y == apple.pos_y {
                    respawn_apple(&apple)
                    head.length += 3
                }

                
                // 4. Draw!
                BeginDrawing()
                ClearBackground(BLACK)

                draw_level(&game_map, body_size)
                draw_snake_tail(&tail, body_size)
                draw_snake_head(&head, body_size)
                draw_apple(&apple, body_size)

                EndDrawing()
            }

            case .Fail: {
                delete(tail)
                game_state = .GameOver
            }

            case .GameOver: {

                #partial switch key : KeyboardKey = GetKeyPressed(); key {
                    case .ENTER: {
                        game_state = .Init
                    }
                }

                BeginDrawing()
                ClearBackground(BLACK)

                draw_level(&game_map, body_size)

                EndDrawing()

                DrawText("G A M E   O V E R !", 190, 200, 30, RED);
                DrawText("Press enter to restart", 190, 250, 30, LIGHTGRAY);
            }

            case .Paused: {

            }


        }
    
    }

    CloseWindow()
}