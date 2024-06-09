const std = @import("std");

const WIDTH = 40;
const HEIGHT = 40;
const GRID_SIZE = WIDTH * HEIGHT;

pub fn main() !void {
    var game: Game = undefined;
    game.init();

    while (true) {
        game.step();
        try game.terminalPrint();
        std.time.sleep(1_000_000_00);
    }
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
    fn terminalPrint(self: *Game) !void {
        const stdout = std.io.getStdOut().writer();
        const grid = &self.grid;
        // clear terminal
        stdout.print("\x1B[2J\x1B[H", .{}) catch {};
        var print_buffer: [(WIDTH * 2 + 1) * HEIGHT * 8]u8 = undefined;
        var print_buffer_len: usize = 0;

        try stdout.print("Iter: {any}\n", .{self.iter});

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
