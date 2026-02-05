

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

pub fn convertToCType(token: Token) ?[]const u8 {
    switch (token.Type) {
        TokenType.i8 => return "int8_t",
        TokenType.u8 => return "uint8_t",
        TokenType.i16 => return "int16_t",
        TokenType.u16 => return "uint16_t",
        TokenType.Int, TokenType.i32 => return "int32_t",
        TokenType.u32 => return "uint32_t",
        TokenType.i64 => return "int64_t",
        TokenType.u64 => return "uint64_t",
        TokenType.Usize => return "size_t",
        TokenType.f32 => return "float",
        TokenType.f64 => return "double",
        TokenType.String => return "const char*",
        TokenType.Char => return "char",
        TokenType.Bool => return "bool",
        TokenType.Void => return "void",
        else => return null,
    }
}



