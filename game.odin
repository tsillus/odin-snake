package snake;

import rl "vendor:raylib"
import "core:time"
import "core:fmt"
import "core:strings"
import c "core:c/libc"


Apple :: struct {
    pos_x: i32,
    pos_y: i32,
    spawned: time.Time,
    ttl: time.Duration,
}

respawn_apple:: proc(apple:^Apple) {
    apple.pos_x = (c.rand() % 28) + 1
    apple.pos_y = (c.rand() % 28) + 1
    apple.spawned = time.now()
}

GameState :: enum {
    Init, Running, Paused, Fail, GameOver,
}

game :: proc(config: GameConfig) -> GameMode {
    using rl
    last_tick := time.now()

    game_map := Level{
        width = config.level_width,
        height = config.level_height, 
        cells = make([]Tile, config.level_width*config.level_height),
    }
    defer delete(game_map.cells)

    game_state := GameState.Init

    head: SnakeHead;
    tail: [dynamic]SnakeBody; defer delete(tail)
    apple: Apple;

    score_animations: [dynamic]TextAnimation;
    defer {
        for i := 0; i < len(score_animations); i+=1 {
            delete_cstring(score_animations[i].text)
        }
        delete(score_animations)
    }

    final_score : cstring
    
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
                    case .P:     { game_state = .Paused }
                }

                // 2. Update Game state
                now := time.now()
                if time.diff(last_tick, now) > config.game_tick {
                    append_elem(&tail, SnakeBody{head.pos_x, head.pos_y})

                    if len(tail) >= auto_cast head.length do ordered_remove(&tail, 0)

                    head.pos_x = head.pos_x + head.dir_h
                    head.pos_y = head.pos_y + head.dir_v

                    last_tick = now
                }

                // 3. Collision Detection
                // The snake crashed against a wall
                if get_cell_value(&game_map, auto_cast head.pos_x, auto_cast head.pos_y) != Tile.Floor {
                    game_state = .Fail
                    continue
                }
                
                //  The snake into itself
                for body, index in tail {
                    if body.pos_x == head.pos_x && body.pos_y == head.pos_y {
                        game_state = .Fail
                        continue
                    }
                }
                time_taken := time.diff(apple.spawned, now)
                
                // It took too long for the player to reach the apple.
                if time_taken > apple.ttl {
                    respawn_apple(&apple)
                    head.score -= auto_cast (apple.ttl / time.Second)
                }

                //  The player reached the apple in time.                    
                if head.pos_x == apple.pos_x && head.pos_y == apple.pos_y {
                    
                    score : i32 = auto_cast ((apple.ttl - time_taken) / time.Second)
                    head.score += auto_cast score
                    respawn_apple(&apple)
                    head.length += 3

                    add_animation(
                        &score_animations, fmt.tprintf("+%d", score), 
                        Vector{head.pos_x * i32(config.tile_size) +2, head.pos_y * i32(config.tile_size) +2}, Vector{0, -50},     // coordinates
                        now, 3 * time.Second,                               // time frame
                        rl.Color{0, 0, 0, 255}, rl.Color{0, 0, 0, 0},       // colors
                        50, 50                                              // font sizes 
                    )
                    add_animation(
                        &score_animations, fmt.tprintf("+%d", score), 
                        Vector{head.pos_x * i32(config.tile_size), head.pos_y * i32(config.tile_size)}, Vector{0, -50},     // coordinates
                        now, 3 * time.Second,                               // time frame
                        rl.Color{200, 200, 200, 255}, rl.Color{200, 200, 200, 0},   // colors
                        50, 50                                              // font sizes 
                    )
                    
                }

                
                // 4. Draw!
                BeginDrawing()
                ClearBackground(BLACK)

                draw_level(&game_map, config.tile_size)
                draw_snake_tail(&tail, config.tile_size)
                draw_snake_head(&head, config.tile_size)
                draw_apple(&apple, config.tile_size)
                
                // buffer: [64]u8
                // score_string := strings.unsafe_string_to_cstring(fmt.bprintf(buffer[:], "Score: %d\x00", head.score))

                score_string := strings.clone_to_cstring(fmt.tprintf("Score: %d", head.score))
                defer delete_cstring(score_string)
                DrawText(score_string, 900, 20, 45, Color{ 211, 176, 131, 255 });

                draw_animations(&score_animations)

                EndDrawing()
            }

            case .Fail: {
                delete(tail)
                final_score = strings.clone_to_cstring(fmt.tprintf("Final Score: %d", head.score))
                defer delete_cstring(final_score)
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

                draw_level(&game_map, config.tile_size)
                
                DrawText("G A M E   O V E R !", 190, 200, 40, RED);
                DrawText(final_score, 190, 250, 30, RED);
                DrawText("Press enter to restart", 190, 300, 30, LIGHTGRAY);

                EndDrawing()

            }

            case .Paused: {
                #partial switch key : KeyboardKey = GetKeyPressed(); key {
                    case .P:  { game_state = .Running }
                }

                BeginDrawing()
                ClearBackground(BLACK)

                draw_level(&game_map, config.tile_size)
                draw_snake_tail(&tail, config.tile_size)
                draw_snake_head(&head, config.tile_size)
                
                DrawText("G A M E   P A U S E D", 190, 200, 40, RED);
                DrawText("Press P to continue", 190, 250, 30, LIGHTGRAY);
                
                EndDrawing()

            }


        }
    
    }

    return GameMode.Exit
}