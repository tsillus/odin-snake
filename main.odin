package snake;

import rl "vendor:raylib"
import "core:time"
import "core:fmt"
import mem "core:mem"
import c "core:c/libc"
// import "core:strings"

GameConfig :: struct {
    level_width : i32,
    level_height: i32,
    game_tick: time.Duration,
    tile_size: i32,
}

GameMode :: enum {
    Menu, Game, Editor, Options, Exit
}


//Defines a rectangle on the screen. Passed to drawing functions so they know where to draw stuff to. 
Frame :: struct {
    left  : c.int,
    right : c.int,
    top   : c.int,
    bottom: c.int,
}

WINDOW_WIDTH  : i32 : 1200
WINDOW_HEIGHT : i32 : 900
LEVEL_WIDTH   : i32 : 30
LEVEL_HEIGHT  : i32 : 30


main :: proc() {
    using rl
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

    config := init()

    game_mode := GameMode.Menu

    loop: for {

        switch game_mode {
            case .Menu:    { game_mode = menu(config)}
            case .Game:    { game_mode = game(config); }
            case .Editor:  {}
            case .Options: {}
            case .Exit:    {
                break loop
            }

        }
    }
}

init :: proc() -> GameConfig{
    using rl
    config := GameConfig{
        level_height = LEVEL_HEIGHT,
        level_width = LEVEL_WIDTH,
        game_tick = 200 * time.Millisecond,
        tile_size = min(WINDOW_HEIGHT, WINDOW_WIDTH) / max(LEVEL_HEIGHT, LEVEL_WIDTH),
    }

    flags: ConfigFlags = { .WINDOW_RESIZABLE }
    SetWindowState(flags)

    InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Snake!")
    SetTargetFPS(60)

    return config
}