package snake;

import c "core:c/libc"
import rl "vendor:raylib"
import "core:fmt"


MENU_TEXT : []cstring : {"Play\x00", "Level Editor\x00", "Options\x00", "Quit\x00"}


MenuElement :: struct {
    text: cstring,
    transition: GameMode,
}

MENU_POINTS : []MenuElement = {
    MenuElement{MENU_TEXT[0], GameMode.Game},
    MenuElement{MENU_TEXT[1], GameMode.Editor},
    MenuElement{MENU_TEXT[2], GameMode.Options},
    MenuElement{MENU_TEXT[3], GameMode.Exit},
}

SELECTED_MENU := 0


/*
 [ ] Display Menu points "Start Game", "Editor", "Options", "Quit"
 [ ] Animate Selection with ↑ and ↓ arrow
 [ ] <Enter> executes the Option.

 */

 menu :: proc(config:GameConfig) -> GameMode {
    using rl
    width : f32 = f32(WINDOW_WIDTH)
    height: f32 = f32(WINDOW_HEIGHT)
    menu_frame := Frame{ c.int(0.2 * width), c.int(width), c.int(0.4 * height), c.int(0.8 * height)}
    menu_len := len(MENU_POINTS)

    #partial switch key : KeyboardKey = GetKeyPressed(); key {
        case .DOWN:  { SELECTED_MENU = (SELECTED_MENU + 1 ) %% menu_len;}
        case .UP:    { SELECTED_MENU = (SELECTED_MENU - 1) %% menu_len;}
        case .Q:     { return GameMode.Exit }
        case .ENTER: { return MENU_POINTS[SELECTED_MENU].transition }
    }

 
    BeginDrawing()
    {
        ClearBackground(BLACK)
        draw_menu(menu_frame)
    }
    EndDrawing()



    return GameMode.Menu
 }

 draw_menu :: proc(frame: Frame) {
    using frame
    height := frame.bottom - frame.top
    step_size := int(height) / len(MENU_POINTS)


    for i := 0;i < len(MENU_POINTS); i+=1 {
        menu_point := MENU_POINTS[i]
        if SELECTED_MENU == i {
            rl.DrawText(menu_point.text,left, top + c.int(i * step_size), 30, rl.LIME)
        } else {
            rl.DrawText(menu_point.text,left, top + c.int(i * step_size), 30, rl.DARKGRAY)
        }
    }
    

 }