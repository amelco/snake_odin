package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

Vec2 :: struct { x,y : i32 }

Direction :: enum { up, down, left, right}

Snake :: struct 
{
    pos : Vec2,
    size : i32,
    speed : f32,
    direction : Direction,
}

// constants
ASPECT_RATIO  : f32 : 16/9.0
WINDOW_WIDTH  : i32 : 800
WINDOW_HEIGHT : f32 : f32(WINDOW_WIDTH) / ASPECT_RATIO
WORLD_WIDTH   : i32 : WINDOW_WIDTH / 10
WORLD_HEIGHT  : i32 : i32(WINDOW_HEIGHT / 10.0)
CELL_SIZE     : i32 : WINDOW_WIDTH / WORLD_WIDTH

// globals
snake     : Snake
positions : [dynamic]Vec2;
food      : Vec2 = {-1, -1};
grow      : bool = false;
debug     : bool = true;
has_food  : bool = false;
game_over : bool = false;


grid_draw :: proc() 
{
    for y := CELL_SIZE; y < i32(WINDOW_HEIGHT) - CELL_SIZE + 1; y += CELL_SIZE 
    {
        rl.DrawLine(CELL_SIZE, y, WINDOW_WIDTH - CELL_SIZE, y, rl.WHITE);
        for x := CELL_SIZE; x < WINDOW_WIDTH - CELL_SIZE + 1; x += CELL_SIZE 
        {
            rl.DrawLine(x, CELL_SIZE, x, i32(WINDOW_HEIGHT) - CELL_SIZE, rl.WHITE);
        }
    }
    
}

snake_init :: proc()
{
    snake.pos.x = 0;
    snake.pos.y = 0;
    snake.size = 1;
    snake.speed = 1;
    snake.direction = Direction.right;

    append(&positions, Vec2{snake.pos.x, snake.pos.y});
}

snake_update :: proc()
{
    if grow 
    {
        append(&positions, snake.pos);
        grow = false;
    }

    if snake.direction == Direction.right { snake.pos.x += 1 }
    if snake.direction == Direction.left  { snake.pos.x -= 1 }
    if snake.direction == Direction.up    { snake.pos.y -= 1 }
    if snake.direction == Direction.down  { snake.pos.y += 1 }

    // positions update
    for i := len(positions); i > 0; i -= 1
    {
        if i > 1
        {
            positions[i-1] = positions[i - 2];
        }
    }
    positions[0] = snake.pos;

    if snake.pos == food 
    {
        grow = true;
        has_food = false;
        food = {-1, -1}
    }
}

snake_draw :: proc()
{
    for i := len(positions); i > 0; i -= 1
    {
        x := positions[i-1].x + 1;
        y := positions[i-1].y + 1;
        rl.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, rl.YELLOW);
    }
}

food_draw :: proc()
{
    x : = food.x + 1;
    y : = food.y + 1;
    if x > 0 && y > 0
    {
        rl.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, rl.RED);
    }
}

create_food :: proc()
{
    food.x = rand.int31_max(WORLD_WIDTH - 3);
    food.y = rand.int31_max(WORLD_HEIGHT - 3);
    has_food = true;
    fmt.print("food created!\n");
}

check_game_over :: proc()
{
    for i := 1; i < len(positions); i += 1
    {
        if snake.pos.x == positions[i].x && snake.pos.y == positions[i].y
        {
            game_over = true;
        }
    }
}

main :: proc()
{
    rl.InitWindow(800, 450, "raylib [core] example - basic window");
    defer rl.CloseWindow();

    snake_init();
    rl.SetTargetFPS(60);

    time_elapsed : f32 = 0;
    total_time   : f64 = 0;
    for rl.WindowShouldClose() == false 
    {
        if game_over 
        {
            rl.BeginDrawing();
            defer rl.EndDrawing();

            rl.ClearBackground(rl.GRAY);
            snake_draw();
            text_size := rl.MeasureText("GAME OVER", 20);
            rl.DrawText("GAME OVER", WINDOW_WIDTH / 2 - (text_size / 2), i32(WINDOW_HEIGHT) / 2, 20, rl.BLACK);
            continue;
        }

        rl.ClearBackground(rl.BLUE);
        if rl.IsKeyPressed(rl.KeyboardKey.DOWN)  && snake.direction != Direction.up    { snake.direction = Direction.down }
        if rl.IsKeyPressed(rl.KeyboardKey.UP)    && snake.direction != Direction.down  { snake.direction = Direction.up }
        if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) && snake.direction != Direction.left  { snake.direction = Direction.right }
        if rl.IsKeyPressed(rl.KeyboardKey.LEFT)  && snake.direction != Direction.right { snake.direction = Direction.left }
        if (debug)
        {
            if rl.IsKeyPressed(rl.KeyboardKey.W)  { snake.speed += 1 }
            if rl.IsKeyPressed(rl.KeyboardKey.S)  { snake.speed -= 1 }
            if rl.IsKeyPressed(rl.KeyboardKey.Q)  { grow = true }
            if rl.IsKeyPressed(rl.KeyboardKey.D)  { if debug {debug = false;} else {debug = true;} }
        }

        rl.BeginDrawing();
        defer rl.EndDrawing();

        dt := rl.GetFrameTime();
        total_time += f64(dt);
        time_elapsed += dt;
        if time_elapsed >= 1 / snake.speed
        {
            if !has_food
            {
                if int(total_time) % 2 == 0
                {
                    create_food();
                }
            }
            snake_update();
            check_game_over();
            time_elapsed = 0;
        }

        if debug { grid_draw(); }
        food_draw();
        snake_draw();
    }
    
}
