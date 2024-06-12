const std = @import("std");
const r = @import("raylib");
const Allocator = std.mem.Allocator;

const rect_w = 5;
const rect_h = 5;

pub fn main() !void {
    const screenWidth = 400;
    const screenHeight = 400;
    r.setConfigFlags(.{ .window_resizable = true });
    r.initWindow(screenWidth, screenHeight, "Game Of Life");
    defer r.closeWindow();

    r.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var game: Game = try Game.init(allocator, screenWidth / rect_w, screenHeight / rect_h);

    while (!r.windowShouldClose()) {
        r.beginDrawing();
        defer r.endDrawing();

        const window_width: usize = @intCast(r.getRenderWidth());
        const window_height: usize = @intCast(r.getRenderHeight());

        const new_grid_width = window_width / rect_w;
        const new_grid_height = window_height / rect_h;

        r.clearBackground(r.Color.black);

        for (0..game.grid_height) |y| {
            for (0..game.grid_width) |x| {
                const i: usize = x + (y * game.grid_width);
                const color: r.Color = if (game.grid[i] == 1) r.Color.green else r.Color.black;

                const rect: r.Rectangle = .{ .x = @floatFromInt(@as(i32, @intCast(x)) * rect_w), .y = @floatFromInt(@as(i32, @intCast(y)) * rect_h), .width = @floatFromInt(rect_w), .height = @floatFromInt(rect_h) };
                r.drawRectangleRec(rect, color);
            }
        }

        if (new_grid_width != game.grid_width or new_grid_height != game.grid_height) {
            try game.resize(@max(window_width / rect_w, 1), @max(window_height / rect_h, 1));
        }
        try game.step();
    }
}

const Grid = struct { width: usize, heigt: usize, buffer: []u1 };

const Game = struct {
    grid: []u1,
    grid_buffer: []u1,
    iter: u64,
    grid_width: usize,
    grid_height: usize,
    allocator: Allocator,

    fn init(allocator: Allocator, grid_width: usize, grid_height: usize) !Game {
        const grid = try allocator.alloc(u1, grid_width * grid_height);
        const grid_buffer = try allocator.alloc(u1, grid_width * grid_height);
        for (grid_buffer) |*cell| cell.* = 0;

        //Random
        const rand = std.crypto.random;
        for (grid) |*cell| cell.* = rand.int(u1);

        return Game{ .allocator = allocator, .grid = grid, .grid_buffer = grid_buffer, .grid_width = grid_width, .grid_height = grid_height, .iter = 0 };
    }

    fn resizeGrid(grid: *[]u1, width: usize, new_grid: *[]u1, new_width: usize) void {
        const height = grid.len / width;
        const new_height = new_grid.len / new_width;

        if (new_width > width) {
            for (0..height) |y| {
                for (0..width) |x| {
                    const index: usize = x + (y * width);
                    const new_index: usize = x + (y * new_width);

                    if (new_index < new_grid.len) {
                        new_grid.*[new_index] = grid.*[index];
                    }
                }
            }
        } else {
            for (0..new_height) |y| {
                for (0..new_width) |x| {
                    const index: usize = x + (y * new_width);
                    const new_index: usize = x + (y * width);
                    if (new_index >= grid.len) {
                        new_grid.*[index] = 0;
                    } else {
                        new_grid.*[index] = grid.*[new_index];
                    }
                }
            }
        }
    }

    fn resize(self: *Game, new_width: usize, new_height: usize) !void {
        var grid_new = try self.allocator.alloc(u1, new_width * new_height);
        var grid_buffer_new = try self.allocator.alloc(u1, new_width * new_height);

        resizeGrid(&self.grid, self.grid_width, &grid_new, new_width);
        self.grid = grid_new;

        resizeGrid(&self.grid_buffer, self.grid_width, &grid_buffer_new, new_width);
        self.grid_buffer = grid_buffer_new;

        self.grid_width = new_width;
        self.grid_height = new_height;
    }

    fn step(self: *Game) !void {
        const grid = self.grid;

        const width = self.grid_width;
        const height = self.grid_height;

        const width2: i32 = @intCast(width);
        const neighbours = [8]i32{ -width2 - 1, -width2, -width2 + 1, -1, 1, width2 - 1, width2, width2 + 1 };

        for (0..height) |y| {
            for (0..width) |x| {
                const i: usize = x + (y * width);

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
                    self.grid_buffer[i] = 0;
                    continue;
                }
                if (grid[i] == 0 and ngbs == 3) {
                    self.grid_buffer[i] = 1;
                    continue;
                }
                self.grid_buffer[i] = grid[i];
            }
        }
        self.iter += 1;

        //swap buffers
        const temp = self.grid;
        self.grid = self.grid_buffer;
        self.grid_buffer = temp;
    }
};
