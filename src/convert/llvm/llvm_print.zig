const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const enums_mod = @import("../../core/enums.zig");
const errors_mod = @import("../../core/errors.zig");
const llvm_utils_mod = @import("llvm_utils.zig");
const debugging_mod = @import("../../debugging/debugging.zig");
const flatten_expressions_mod = @import("llvm_flatten.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ConvertData = structs_mod.ConvertData;
const ASTNode = structs_mod.ASTNode;
const AstError = errors_mod.AstError;
const ASTNodeType = enums_mod.ASTNodeType;
const ConvertError = errors_mod.ConvertError;
const Token = structs_mod.Token;
const string = []const u8;
const printing_mod = @import("../../core/printing.zig");
const Type = structs_mod.Type;
const debug_mod = std.debug;
const Symbol = structs_mod.Symbol;
const SymbolId = structs_mod.SymbolId;
const type_info_mod = @import("../../core/type_info.zig");
const SymbolTable = structs_mod.SymbolTable;
const TypeId = structs_mod.TypeId;
const SymbolTag = enums_mod.SymbolTag;
const StringBuilder = structs_mod.StringBuilder;

fn getPrintfFormatForType(convert_data:*ConvertData, type_id:TypeId) ?string {

    const var_type:Type = convert_data.type_list.getTypeAtIndex(type_id) orelse unreachable;

    const type_info = type_info_mod.getPrimitiveTypeInfo(var_type.type_tag);
    if (type_info == null) {
        unreachable;
    }

    return type_info.?.printf_code;
}

pub fn processPrint(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode, new_line:bool) ConvertError!void {

    var statements = ArrayList(string).initCapacity(allocator, 0) catch return ConvertError.Out_Of_Memory;
    defer statements.deinit(allocator);

    var format_builder = ArrayList(u8).initCapacity(allocator, 0) catch return ConvertError.Out_Of_Memory;
    defer format_builder.deinit(allocator);

    var values_builder = ArrayList(string).initCapacity(allocator, 0) catch return ConvertError.Out_Of_Memory;
    defer values_builder.deinit(allocator);

    // 1. Flatten all arguments
    for (node.children.?.items) |arg| {
        const value_name:string = try flatten_expressions_mod.flattenExpression(allocator, convert_data, arg, &statements);

        if (arg.type_id == null) {
            convert_data.setError("type id is null", arg.token);
            return ConvertError.Internal_Error;
        }

        // ---- FORMAT STRING PART ----
        const print_code_text:string = getPrintfFormatForType(convert_data, arg.type_id.?) orelse unreachable;

        format_builder.appendSlice(allocator, print_code_text) catch return ConvertError.Out_Of_Memory;

        const type_id:TypeId = arg.type_id orelse {
            convert_data.setError("type id not set", node.token);
            return ConvertError.Internal_Error;
        };
        const llvm_type:string = try convert_data.typeToLLVM(allocator, type_id, arg.token, true);

        const typed_value:string = std.fmt.allocPrint(allocator, "{s} {s}", .{ 
            llvm_type, value_name 
        }) catch return ConvertError.Out_Of_Memory;

        values_builder.append(allocator, typed_value) catch return ConvertError.Out_Of_Memory;
    }

    // newline
    if (new_line) {
        format_builder.append(allocator, 0x0A) catch return ConvertError.Out_Of_Memory;
    }

    // 2. Emit temp statements
    for (statements.items) |line| {
        try convert_data.appendFmt(allocator, "\t{s}\n", .{ line });
    }

    // 3. Emit format string
    const format_result:string = format_builder.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;

    const fmt_ptr:?string = try convert_data.emitGlobalString(allocator, convert_data, format_result);

    if (fmt_ptr == null) unreachable;

    // 4. Emit printf call
    try convert_data.appendFmt(allocator, "\tcall i32 (i8*, ...) @printf({s}", .{ 
        fmt_ptr.? 
    });

    for (values_builder.items) |value| {
        try convert_data.appendFmt(allocator, ", {s}", .{ value });
    }

    try convert_data.appendCode(allocator, ")\n");
}
