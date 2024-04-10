const std = @import("std");
const streams = @import("./streams.zig");

pub const TokenType = enum {
    Keyword,
    Name,
    Fn,
    LeftParen,
    RightParen,
    LeftBracket,
    RightBracket,
    LeftCurly,
    RightCurly,
    SingleQuote,
    DoubleQuote,
    SemiColon,
    Colon,
    Literal,
    Assign,
    Equals,
    NotEquals,
    Greater,
    GreaterEquals,
    Lesser,
    LesserEquals,
    Not,
    And,
    Or,
    Plus,
    Minus,
    Mul,
    Div,
    Mod,
    Return,
    Comma,
    If,
    Else,
    Comment,
};

pub const KeywordType = enum {
    CONST,
    VAR,
    AND,
    OR,
    NOT,
    RETURN,
    IF,
    ELSE,
    STRUCT,
    PUBLIC,
    IMPORT,
    ATTR,
    CASE,
};
pub const LiteralType = enum { String, Integer, Float };

pub const Token = struct {
    token_type: TokenType,
    lexeme: []const u8,
    start: usize,
    keyword_type: ?KeywordType = null,
    literal_type: ?LiteralType = null,

    pub fn isKeyword(self: Token) bool {
        return self.keyword_type != null;
    }

    pub fn isLiteral(self: Token) bool {
        return self.literal_type != null;
    }
};

pub const TokenStream = streams.Stream(Token);

pub const Keywords = std.ComptimeStringMap(KeywordType, .{
    .{ "const", .CONST },
    .{ "var", .VAR },
    .{ "and", .AND },
    .{ "or", .OR },
    .{ "not", .NOT },
    .{ "return", .RETURN },
    .{ "if", .IF },
    .{ "else", .ELSE },
    .{ "struct", .STRUCT },
    .{ "pub", .PUBLIC },
    .{ "import", .IMPORT },
    .{ "attr", .ATTR },
    .{ "case", .ATTR },
});
pub const LiteralToken = std.ComptimeStringMap(TokenType, .{
    .{ "(", .LeftParen },
    .{ ")", .RightParen },
    .{ "[", .LeftBracket },
    .{ "]", .RightBracket },
    .{ "{", .LeftCurly },
    .{ "}", .RightCurly },
    .{ ";", .SemiColon },
    .{ ":", .Colon },
    .{ "+", .Plus },
    .{ "-", .Minus },
    .{ "*", .Mul },
    .{ "/", .Div },
    .{ "%", .Div },
    .{ ",", .Comma },
});
pub const ComparisonToken = std.ComptimeStringMap(TokenType, .{
    .{ ">", .Greater },
    .{ "<", .Lesser },
    .{ ">=", .GreaterEquals },
    .{ "<=", .LesserEquals },
});
