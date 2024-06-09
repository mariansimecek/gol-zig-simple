const std = @import("std");
const r = @import("raylib");

const WIDTH = 600;
const HEIGHT = 300;
const GRID_SIZE = WIDTH * HEIGHT;

pub fn main() !void {
    const screenWidth = WIDTH * 2;
    const screenHeight = HEIGHT * 2;
    // r.setConfigFlags(.{ .window_resizable = true });
    r.initWindow(screenWidth, screenHeight, "Game Of Life");
    defer r.closeWindow();

    r.setTargetFPS(60);

    var game: Game = undefined;
    game.init();

    while (!r.windowShouldClose()) {
        r.beginDrawing();
        defer r.endDrawing();

        const window_width = r.getRenderWidth();
        const window_height = r.getRenderHeight();

        r.clearBackground(r.Color.black);

        const rect_w = @divFloor(window_width, WIDTH);
        const rect_h = @divFloor(window_height, HEIGHT);

        for (0..HEIGHT) |y| {
            for (0..WIDTH) |x| {
                const i: usize = x + (y * WIDTH);
                const color: r.Color = if (game.grid[i] == 1) r.Color.green else r.Color.black;

                const rect: r.Rectangle = .{ .x = @floatFromInt(@as(i32, @intCast(x)) * rect_w), .y = @floatFromInt(@as(i32, @intCast(y)) * rect_h), .width = @floatFromInt(rect_w), .height = @floatFromInt(rect_h) };
                r.drawRectangleRec(rect, color);
            }
        }
        // std.debug.print("size: {d}x{d}\n", .{ rect_w, rect_h });
        game.step();
    }

    // terminal loop
    // while (true) {
    //     game.step();
    //     try terminalPrint(&game);
    //     std.time.sleep(1_000_000_00);
    // }
}

const Game = struct {
    grid: [GRID_SIZE]u1 = undefined,
    iter: u64 = 0,

    fn init(self: *Game) void {
        self.*.iter = 0;
        const rand = std.crypto.random;
        for (&self.grid) |*cell| {
            cell.* = rand.int(u1);
        }
    }
    fn step(self: *Game) void {
        const grid = &self.grid;
        var buffer: [WIDTH * HEIGHT]u1 = undefined;
        for (0..HEIGHT) |y| {
            for (0..WIDTH) |x| {
                buffer[x + (y * WIDTH)] = grid[x + (y * WIDTH)];
            }
        }

        const neighbours = [8]comptime_int{ -WIDTH - 1, -WIDTH, -WIDTH + 1, -1, 1, WIDTH - 1, WIDTH, WIDTH + 1 };

        for (0..HEIGHT) |y| {
            for (0..WIDTH) |x| {
                const i: usize = x + (y * WIDTH);

                var ngbs: usize = 0;
                inline for (neighbours) |offset| {
                    const possible_index: i32 = offset + @as(i32, @intCast(i));
                    if (possible_index >= 0 and possible_index < grid.len) {
                        const ni: usize = @intCast(possible_index);
                        if (grid[ni] == 1) {
                            ngbs += 1;
                        }
                    }
                }

                if (grid[i] == 1 and (ngbs < 2 or ngbs > 3)) {
                    buffer[i] = 0;
                    continue;
                }
                if (grid[i] == 0 and ngbs == 3) {
                    buffer[i] = 1;
                    continue;
                }
                buffer[i] = grid[i];
            }
        }
        self.iter += 1;
        @memcpy(grid, &buffer);
    }
};

pub fn terminalPrint(game: *Game) !void {
    const stdout = std.io.getStdOut().writer();
    const grid = &game.grid;
    // clear terminal
    stdout.print("\x1B[2J\x1B[H", .{}) catch {};
    var print_buffer: [(WIDTH * 2 + 1) * HEIGHT * 8]u8 = undefined;
    var print_buffer_len: usize = 0;

    try stdout.print("Iter: {any}\n", .{game.iter});

    for (0..HEIGHT) |y| {
        for (0..WIDTH) |x| {
            const ch: []const u8 = if (grid[x + (y * WIDTH)] == 1) "\x1b[7m  \x1b[0m" else "  ";
            std.mem.copyForwards(u8, print_buffer[print_buffer_len..], ch);
            print_buffer_len += ch.len;
        }
        std.mem.copyForwards(u8, print_buffer[print_buffer_len..], "\n");
        print_buffer_len += 1;
    }

    const result = print_buffer[0..print_buffer_len];
    try stdout.print("{s}", .{result});
}
