const std = @import("std");
const streams = @import("./streams.zig");
const tokens = @import("./tokens.zig");

const Scanner = @This();
const ScannerError = error{
    UnterminatedName,
    InvalidCharacterForName,
    UnterminatedString,
    UnterminatedExpression,
    UnterminatedComment,
};

char_stream: streams.CharStream,
const whitespace = " \n\t\r";

pub fn read(self: *Scanner, allocator: std.mem.Allocator) !tokens.TokenStream {
    var token_array = std.ArrayList(tokens.Token).init(allocator);
    errdefer token_array.deinit();
    var iterator = self.char_stream.iterator();
    while (iterator.nextExcept(whitespace)) |char| {
        if (try self.readToken(&iterator, char)) |token| {
            try token_array.append(token);
        }
    }
    return tokens.TokenStream.init(try token_array.toOwnedSlice());
}

fn readToken(self: *Scanner, iterator: *streams.CharStream.StreamIterator, char: u8) !?tokens.Token {
    const start = iterator.getLastPos();
    return switch (char) {
        'A'...'Z', 'a'...'z' => read_name: {
            var token = try self.readName(iterator, start);
            if (tokens.Keywords.get(token.lexeme)) |kw_type| {
                token = tokens.Token{
                    .start = token.start,
                    .lexeme = token.lexeme,
                    .token_type = .Keyword,
                    .keyword_type = kw_type,
                };
            } else if (std.mem.eql(u8, token.lexeme, "fn")) {
                token = tokens.Token{
                    .start = token.start,
                    .lexeme = token.lexeme,
                    .token_type = .Fn,
                };
            }
            break :read_name token;
        },
        '"' => try self.readString(iterator, start),
        '>', '<' => read_comparison: {
            if (iterator.isExhausted()) {
                return ScannerError.UnterminatedExpression;
            }
            switch (iterator.getStreamCurrent()) {
                ' ', '=' => |val| {
                    const offset: u4 = if (val == ' ') 1 else 2;
                    const lexeme = try self.char_stream.peekSlice(start, start + offset);
                    const token_type = tokens.ComparisonToken.get(lexeme) orelse unreachable;
                    _ = iterator.next();
                    break :read_comparison tokens.Token{
                        .start = start,
                        .lexeme = lexeme,
                        .token_type = token_type,
                    };
                },
                else => return ScannerError.UnterminatedExpression,
            }
        },
        '!' => if (iterator.isExhausted() or iterator.getStreamCurrent() != '=')
            ScannerError.UnterminatedExpression
        else
            tokens.Token{
                .start = start,
                .lexeme = try self.char_stream.peekSlice(start, start + 2),
                .token_type = .NotEquals,
            },
        '=' => read_assign: {
            if (iterator.isExhausted()) {
                return ScannerError.UnterminatedExpression;
            }
            if (iterator.getStreamCurrent() == '=') {
                _ = iterator.next();
                break :read_assign tokens.Token{
                    .start = start,
                    .lexeme = try self.char_stream.peekSlice(start, start + 2),
                    .token_type = .Equals,
                };
            } else {
                _ = iterator.next();
                break :read_assign tokens.Token{
                    .start = start,
                    .lexeme = try self.char_stream.peekSlice(start, start + 1),
                    .token_type = .Assign,
                };
            }
        },
        '/' => read_slash: {
            var token: tokens.Token = undefined;
            if (iterator.isExhausted()) {
                return ScannerError.UnterminatedExpression;
            } else if (iterator.getStreamCurrent() == '/') {
                _ = iterator.nextUntil("\n\r");
                token = tokens.Token{
                    .start = start,
                    .lexeme = try self.char_stream.peekSlice(start, iterator.getLastPos()),
                    .token_type = .Comment,
                };
                _ = iterator.next();
            } else if (iterator.getStreamCurrent() == '*') {
                token = try self.readMlComment(iterator, start);
            } else {
                token = tokens.Token{
                    .start = start,
                    .lexeme = try self.char_stream.peekSlice(start, start + 1),
                    .token_type = .Div,
                };
            }
            break :read_slash token;
        },
        else => if (tokens.LiteralToken.get(&[1]u8{char})) |token_type| tokens.Token{
            .start = start,
            .lexeme = try self.char_stream.peekSlice(start, start + 1),
            .token_type = token_type,
        } else null,
    };
}

fn readName(self: *Scanner, iterator: *streams.CharStream.StreamIterator, start: usize) !tokens.Token {
    const broken = read_name_blk: {
        while (iterator.next()) |char| {
            switch (char) {
                ' ', '\n', '\t', '\r' => {
                    iterator.stream.pos = iterator.getLastPos();
                    break :read_name_blk true;
                },
                '0'...'9', 'A'...'Z', 'a'...'z' => {
                    continue;
                },
                else => {
                    if (tokens.LiteralToken.has(&[1]u8{char})) {
                        iterator.stream.pos = iterator.getLastPos();
                        break :read_name_blk true;
                    } else {
                        std.log.err("Invalid character for name, {c} at {d}", .{ char, iterator.getLastPos() });
                        return ScannerError.InvalidCharacterForName;
                    }
                },
            }
        }
        break :read_name_blk false;
    };
    if (!broken) return ScannerError.UnterminatedName;
    return tokens.Token{
        .start = start,
        .lexeme = try self.char_stream.peekSlice(start, iterator.stream.getPos()),
        .token_type = .Name,
    };
}

fn readString(self: *Scanner, iterator: *streams.CharStream.StreamIterator, start: usize) !tokens.Token {
    _ = iterator.nextUntil("\"") orelse return ScannerError.UnterminatedString;

    return tokens.Token{
        .start = start,
        .lexeme = try self.char_stream.peekSlice(start, iterator.stream.getPos()),
        .token_type = .Literal,

        .literal_type = .String,
    };
}

fn readMlComment(self: *Scanner, iterator: *streams.CharStream.StreamIterator, start: usize) !tokens.Token {
    const broken = read_comment_blk: {
        while (iterator.next()) |char| {
            if (char != '*') continue;
            const next = iterator.next() orelse return ScannerError.UnterminatedComment;
            if (next == '/') {
                break :read_comment_blk true;
            }
        }
        break :read_comment_blk false;
    };
    if (!broken) {
        return ScannerError.UnterminatedComment;
    }

    return tokens.Token{
        .start = start,
        .lexeme = try self.char_stream.peekSlice(start, iterator.getLastPos()),
        .token_type = .Comment,
    };
}

pub fn freeTokenStream(allocator: std.mem.Allocator, stream: tokens.TokenStream) void {
    allocator.free(stream.buffer);
}
