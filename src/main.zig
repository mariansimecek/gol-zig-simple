const std = @import("std");

pub fn main() !void {
    const width = 60;
    const height = 20;

    const rand = std.crypto.random;
    var grid: [width * height]u1 = undefined;
    for (&grid, 0..) |*cell, i| {
        _ = i;
        cell.* = rand.int(u1);
    }

    var iter: usize = 0;
    while (true) {
        iter += 1;
        printGrid(&grid, width, height, iter);
        nextStep(&grid, width, height);
        std.time.sleep(1_000_000_00);
    }
}

const stdout = std.io.getStdOut().writer();

pub fn printGrid(grid: []const u1, width: comptime_int, height: comptime_int, iter: usize) void {
    // clear terminal
    stdout.print("\x1B[2J\x1B[H", .{}) catch {};
    std.debug.print("Iter: {d}\n", .{iter});
    for (0..height) |y| {
        var char_row: [width]u8 = undefined;
        for (0..width) |x| {
            const ch = if (grid[x + (y * width)] == 1) "#" else " ";
            char_row[x] = ch[0];
        }
        stdout.print("{s}\n", .{char_row}) catch {};
    }
}

pub fn nextStep(grid: []u1, width: comptime_int, height: comptime_int) void {
    var buffer: [width * height]u1 = undefined;
    for (0..height) |y| {
        for (0..width) |x| {
            buffer[x + (y * width)] = grid[x + (y * width)];
        }
    }

    for (0..height) |y| {
        for (0..width) |x| {
            const i: usize = x + (y * width);
            var ngbs: usize = 0;

            if (y > 0 and x > 0 and grid[i - width - 1] == 1) {
                ngbs += 1;
            }
            if (y > 0 and grid[i - width] == 1) {
                ngbs += 1;
            }
            if (y > 0 and x < width and grid[i - width + 1] == 1) {
                ngbs += 1;
            }
            if (x > 0 and grid[i - 1] == 1) {
                ngbs += 1;
            }
            if (x < width - 1 and grid[i + 1] == 1) {
                ngbs += 1;
            }
            if (y < height - 1 and x > 0 and grid[i + width - 1] == 1) {
                ngbs += 1;
            }
            if (y < height - 1 and grid[i + width] == 1) {
                ngbs += 1;
            }
            if (y < height - 1 and x < width - 1 and grid[i + width + 1] == 1) {
                ngbs += 1;
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
    @memcpy(grid, &buffer);
}
