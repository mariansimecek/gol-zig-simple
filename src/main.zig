const std = @import("std");

pub fn main() !void {
    const width = 80;
    const height = 80;

    const rand = std.crypto.random;
    var grid: [width * height]u1 = undefined;
    for (&grid) |*cell| {
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
    var print_buffer: [(width * 2 + 1) * height * 8]u8 = undefined;
    var print_buffer_len: usize = 0;

    std.debug.print("Iter: {d}\n", .{iter});
    for (0..height) |y| {
        for (0..width) |x| {
            const ch: []const u8 = if (grid[x + (y * width)] == 1) "\x1b[7m  \x1b[0m" else "  ";
            std.mem.copyForwards(u8, print_buffer[print_buffer_len..], ch);
            print_buffer_len += ch.len;
        }
        std.mem.copyForwards(u8, print_buffer[print_buffer_len..], "\n");
        print_buffer_len += 1;
    }

    const result = print_buffer[0..print_buffer_len];
    stdout.print("{s}", .{result}) catch {};
}

pub fn nextStep(grid: []u1, width: comptime_int, height: comptime_int) void {
    var buffer: [width * height]u1 = undefined;
    for (0..height) |y| {
        for (0..width) |x| {
            buffer[x + (y * width)] = grid[x + (y * width)];
        }
    }

    const neighbours = [8]comptime_int{ -width - 1, -width, -width + 1, -1, 1, width - 1, width, width + 1 };

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
