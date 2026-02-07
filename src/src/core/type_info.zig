
const enums_mod = @import("enums.zig");
const string = []const u8;
const TypeTag = enums_mod.TypeTag;
const LanguageTarget = enums_mod.LanguageTarget;

pub const BackendNames = struct {
    LLVM: []const u8,
    Go:   []const u8,
    C:    []const u8,
};

pub const PrimitiveTypeInfo = struct {
    name:string,
    type_tag:TypeTag,
    bit_size:usize,
    size_of:usize,
    backend_name:BackendNames,
    printf_code:?string,
};

pub const I32_INFO:PrimitiveTypeInfo = .{
    .name = "int",
    .bit_size = 32,
    .size_of = 4,
    .type_tag = .Int32,
    .backend_name = .{
        .LLVM = "i32",
        .C = "int32_t",
        .Go = "int",
    },
    .printf_code = "%i",
};

pub const I64_INFO:PrimitiveTypeInfo = .{
    .name = "i64",
    .bit_size = 64,
    .size_of = 8,
    .type_tag = .Int64,
    .backend_name = .{
        .LLVM = "i64",
        .C = "int64_t",
        .Go = "int64",
    },
    .printf_code = "%i",
};

pub const BOOL_INFO:PrimitiveTypeInfo = .{
    .name = "bool",
    .bit_size = 8,
    .size_of = 1,
    .type_tag = .Bool,
    .backend_name = .{
        .LLVM = "i1",
        .C = "bool",
        .Go = "bool",
    },
    .printf_code = "%d",
};

pub const STRING_INFO:PrimitiveTypeInfo = .{
    .name = "string",
    .bit_size = 128,
    .size_of = 16,
    .type_tag = .String,
    .backend_name = .{
        .LLVM = "%string",
        .C = "string",
        .Go = "string",
    },
    .printf_code = "%s",
};

pub const CHAR_INFO:PrimitiveTypeInfo = .{
    .name = "char",
    .bit_size = 8,
    .size_of = 1,
    .type_tag = .Char,
    .backend_name = .{
        .LLVM = "i8",
        .C = "char",
        .Go = "byte",
    },
    .printf_code = "%c",
};

pub const F32_INFO:PrimitiveTypeInfo = .{
    .name = "f32",
    .bit_size = 32,
    .size_of = 4,
    .type_tag = .F32,
    .backend_name = .{
        .LLVM = "float",
        .C = "float",
        .Go = "float32",
    },
    .printf_code = "%f",
};

pub const F64_INFO:PrimitiveTypeInfo = .{
    .name = "f64",
    .bit_size = 64,
    .size_of = 8,
    .type_tag = .F64,
    .backend_name = .{
        .LLVM = "double",
        .C = "double",
        .Go = "float64",
    },
    .printf_code = "%f",
};

pub const VOID_INFO:PrimitiveTypeInfo = .{
    .name = "void",
    .bit_size = 8,
    .size_of = 1,
    .type_tag = .Void,
    .backend_name = .{
        .LLVM = "void",
        .C = "void",
        .Go = "",
    },
    .printf_code = null,
};

pub fn getPrimitiveTypeInfo(type_tag:TypeTag) ?PrimitiveTypeInfo {
    
    switch (type_tag) {
        .String => return STRING_INFO,
        .Bool => return BOOL_INFO,
        .Char => return CHAR_INFO,
        .F32 => return F32_INFO,
        .F64 => return F64_INFO,
        .Void => return VOID_INFO,
        .Int32 => return I32_INFO,
        .Int64 => return I64_INFO,
        else => return null,
    }
}
