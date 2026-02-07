

const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const enums_mod = @import("../../core/enums.zig");
const printing_mod = @import("../../core/printing.zig");
const error_mod = @import("../../core/errors.zig");
const Token = structs_mod.Token;
const TokenType = enums_mod.TokenType;
const ConvertError = error_mod.ConvertError;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn convertToGoType(token:Token) ?[]const u8 {
    switch (token.Type) {
        TokenType.i8, TokenType.u8 => return "int8",
        TokenType.i16, TokenType.u16 => return "int16",
        TokenType.Int, TokenType.i32, TokenType.u32 => return "int",
        TokenType.i64, TokenType.u64, TokenType.Usize => return "int64",
        TokenType.f32 => return "float32",
        TokenType.f64 => return "float64",
        TokenType.String => return "string",
        TokenType.Char => return "byte",
        TokenType.Bool => return "bool",
        TokenType.Void => return "",
        else => return null,
    }
}



