const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const llvm_utils_mod = @import("llvm_utils.zig");
const flatten_expression_mod = @import("llvm_flatten.zig");
const type_info_mod = @import("../../core/type_info.zig");
const llvm_body_mod = @import("llvm_body.zig");
const print = std.debug.print;
const Token = structs_mod.Token;
const ASTData = structs_mod.ASTData;
const ASTNode = structs_mod.ASTNode;
const TokenType = enums_mod.TokenType;
const ConvertError = errors_mod.ConvertError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ConvertData = structs_mod.ConvertData;
const StringBuilder = structs_mod.StringBuilder;
const ASTNodeType = enums_mod.ASTNodeType;
const PrimitiveTypeInfo = type_info_mod.PrimitiveTypeInfo;
const string = []const u8;
const NO_MEMORY = ConvertError.Out_Of_Memory;

pub fn processWhile(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    const base_id:usize = convert_data.newWhileId();

    const cond_label:string = try convert_data.allocPrint(
        allocator, "while.cond.{}", .{ base_id }
    );

    const body_label:string = try convert_data.allocPrint(
        allocator, "while.body.{}", .{ base_id }
    );

    const end_label:string = try convert_data.allocPrint(
        allocator, "while.end.{}", .{ base_id }
    );

    // jump to condition first
    try convert_data.appendFmt(
        allocator, "\tbr label %{s}\n", .{ cond_label }
    );

    // CONDITION 
    try convert_data.appendFmt(
        allocator, "{s}:\n", .{ cond_label }
    );

    var statements = ArrayList(string).initCapacity(allocator, 0) catch return NO_MEMORY;
    defer statements.deinit(allocator);

    const cond_value = try flatten_expression_mod.flattenExpression(allocator, convert_data, node.left.?, &statements);

    for (statements.items) |stmt| {
        try convert_data.appendFmt(
            allocator, "\t{s}\n", .{ stmt }
        );
    }

    try convert_data.appendFmt(allocator, "\tbr i1 {s}, label %{s}, label %{s}\n", .{ 
        cond_value, body_label, end_label 
    });

    // BODY
    try convert_data.appendFmt(
        allocator, "{s}:\n", .{ body_label }
    );

    try llvm_body_mod.processBody(allocator, convert_data, node.right.?);

    // loop back
    try convert_data.appendFmt(
        allocator, "\tbr label %{s}\n", .{ cond_label }
    );

    // END 
    try convert_data.appendFmt(
        allocator, "{s}:\n", .{ end_label }
    );
}
