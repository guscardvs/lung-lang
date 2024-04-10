const std = @import("std");

const Self = @This();

allocator: std.mem.Allocator,
filename: ?[]const u8,
binary_path: []const u8,
extra_args: [][]const u8,

pub fn init(allocator: std.mem.Allocator) !Self {
    var iterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer iterator.deinit();

    const binary_path = iterator.next() orelse unreachable;
    const filename = iterator.next();
    var extra_args = std.ArrayList([]const u8).init(allocator);

    while (iterator.next()) |arg| {
        try extra_args.append(arg);
    }

    return Self{
        .allocator = allocator,
        .filename = filename,
        .binary_path = binary_path,
        .extra_args = try extra_args.toOwnedSlice(),
    };
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.extra_args);
}
