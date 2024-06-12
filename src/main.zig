const std = @import("std");
const r = @import("raylib");
const Allocator = std.mem.Allocator;

const rect_w = 20;
const rect_h = 20;
const initial_screen_width = 800;
const initial_screen_height = 400;

pub fn main() !void {
    r.setConfigFlags(.{ .window_resizable = true });
    r.initWindow(initial_screen_width, initial_screen_height, "Game Of Life");
    defer r.closeWindow();

    r.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var game: Game = try Game.init(allocator, initial_screen_width / rect_w, initial_screen_height / rect_h);

    var mouse_pos: r.Vector2 = .{ .x = -100, .y = -100 };

    while (!r.windowShouldClose()) {
        mouse_pos = r.getMousePosition();

        if (r.isKeyPressed(.key_space)) {
            game.pause = !game.pause;
        }

        const window_width: usize = @intCast(r.getRenderWidth());
        const window_height: usize = @intCast(r.getRenderHeight());

        const new_grid_width = window_width / rect_w;
        const new_grid_height = window_height / rect_h;

        if (new_grid_width != game.grid_width or new_grid_height != game.grid_height) {
            try game.resize(@max(window_width / rect_w, 1), @max(window_height / rect_h, 1));
        }

        try game.step();
        const x_mouse_pos_cell: usize = @intFromFloat(@divTrunc(mouse_pos.x, rect_w));
        const y_mouse_pos_cell: usize = @intFromFloat(@divTrunc(mouse_pos.y, rect_w));
        if (r.isMouseButtonDown(.mouse_button_left) and mouse_pos.x > 0 and mouse_pos.y > 0) {
            game.drawCell(x_mouse_pos_cell, y_mouse_pos_cell);
        }

        r.beginDrawing();
        defer r.endDrawing();

        r.clearBackground(r.Color.black);

        for (0..game.grid_height) |y| {
            for (0..game.grid_width) |x| {
                const i: usize = x + (y * game.grid_width);
                const color: r.Color = if (game.grid[i] == 1) r.Color.green else if (x == x_mouse_pos_cell and y == y_mouse_pos_cell) r.colorAlpha(r.Color.white, 0.3) else r.Color.black;

                const x_pos = @as(i32, @intCast(x)) * rect_w;
                const y_pos = @as(i32, @intCast(y)) * rect_h;

                const rect: r.Rectangle = .{ .x = @floatFromInt(x_pos), .y = @floatFromInt(y_pos), .width = @floatFromInt(rect_w - 1), .height = @floatFromInt(rect_h) };
                // _ = color;
                // _ = rect;

                r.drawRectangleRec(rect, color);
                r.drawLine(x_pos + rect_w, y_pos, x_pos + rect_w, y_pos - rect_h, r.colorAlpha(r.Color.white, 0.1));
            }
            r.drawLine(0, @intCast(y * rect_h), @intCast(window_width), @intCast(y * rect_h), r.colorAlpha(r.Color.white, 0.1));
        }
    }
}

const Grid = struct { width: usize, heigt: usize, buffer: []u1 };

const Game = struct {
    grid: []u1,
    grid_width: usize,
    grid_height: usize,
    grid_buffer: []u1,
    pause: bool,
    iter: u64,
    allocator: Allocator,

    fn init(allocator: Allocator, grid_width: usize, grid_height: usize) !Game {
        const grid = try allocator.alloc(u1, grid_width * grid_height);
        const grid_buffer = try allocator.alloc(u1, grid_width * grid_height);
        for (grid_buffer) |*cell| cell.* = 0;

        //Random
        const rand = std.crypto.random;
        for (grid) |*cell| cell.* = rand.int(u1);

        return Game{ .allocator = allocator, .grid = grid, .grid_buffer = grid_buffer, .grid_width = grid_width, .grid_height = grid_height, .iter = 0, .pause = false };
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

    fn drawCell(self: *Game, x_pos: usize, y_pos: usize) void {
        for (0..self.grid_height) |y| {
            for (0..self.grid_width) |x| {
                const i: usize = x + (y * self.grid_width);
                if (x == x_pos and y == y_pos) {
                    self.grid[i] = 1;
                    return;
                }
            }
        }
    }

    fn step(self: *Game) !void {
        if (self.pause) {
            return;
        }
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
