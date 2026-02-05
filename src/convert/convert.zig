

const std = @import("std");
const structs_mod = @import("../core/structs.zig");
const printing_mod = @import("../core/printing.zig");
const enums_mod = @import("../core/enums.zig");
const debugging_mod = @import("../Debugging/debugging.zig");
const errors_mod = @import("../core/errors.zig");
const go_convert_mod = @import("go/go_convert.zig");
const llvm_convert_mod = @import("llvm/llvm_convert.zig");
const c_convert_mod = @import("c/c_convert.zig");
const ASTNode = structs_mod.ASTNode;
const ConvertError = errors_mod.ConvertError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const LanguageTarget = enums_mod.LanguageTarget;
const CompilerSettings = structs_mod.CompilerSettings;
const string = []const u8;
const TypeList = structs_mod.TypeList;

pub fn convertCode(allocator:Allocator, ast_nodes:ArrayList(*ASTNode), code:string, compiler_settings:*const CompilerSettings, type_list:*const TypeList) ConvertError!string {
    switch (compiler_settings.language_target) {
        LanguageTarget.LLVM => return try llvm_convert_mod.convert(allocator, ast_nodes, code, compiler_settings, type_list),
        LanguageTarget.Go => return try go_convert_mod.convert(allocator, ast_nodes, code, compiler_settings, type_list),
        LanguageTarget.C => return try c_convert_mod.convert(allocator, ast_nodes, code, compiler_settings, type_list),
    }
}