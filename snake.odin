package snake;

SnakeHead :: struct {
    pos_x: i32,
    pos_y: i32,
    dir_h: i32,
    dir_v: i32,
    length: i32,
}

SnakeBody :: struct {
    pos_x: i32,
    pos_y: i32,
}

/**
    x: startposition x
    y: startposition y
    h: (h)orizontal direction (-1,0,1)
    v: (v)ertical direction (-1,0,1)
    length: number of tail elements
**/
new_snake :: proc(x,y, h,v, length: i32) -> (head: SnakeHead, tail: [dynamic]SnakeBody) {
    head = SnakeHead{x,y,h,v, length}
    tail = [dynamic]SnakeBody{}

    for i: i32 =length; i>0; i-=1 {
        body := SnakeBody{x - i*h, y- i*v}
        append_elem(&tail, body)
    }
    return head, tail
}