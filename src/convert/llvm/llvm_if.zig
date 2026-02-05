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

pub fn processIf(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    const base_id:usize = convert_data.newIfId();

    const merge_label:string = try convert_data.allocPrint(allocator, "if.end.{}", .{
        base_id
    });

    // Entry jump → first condition
    try convert_data.appendFmt(allocator, "\tbr label %if.cond.{}.0\n", .{
        base_id
    });

    var if_node:*ASTNode = node;
    var index:usize = 0;

    // ----- IF / ELSE-IF CHAIN -----
    while (true) {

        const cond_label:string = try convert_data.allocPrint(allocator, "if.cond.{}.{}", .{ 
            base_id, index
        });

        const then_label:string = try convert_data.allocPrint(allocator, "if.then.{}.{}", .{ 
            base_id, index 
        });

        // condition block
        try convert_data.appendFmt(allocator, "{s}:\n", .{
            cond_label
        });

        var statements = ArrayList([]const u8).initCapacity(allocator, 0) catch return ConvertError.Out_Of_Memory;
        defer statements.deinit(allocator);

        const cond_value:string = try flatten_expression_mod.flattenExpression(allocator, convert_data, if_node.left.?,  &statements);

        for (statements.items) |stmt| {
            try convert_data.appendFmt(allocator, "\t{s}\n", .{
                stmt
            });
        }

        // determine false branch
        var false_label:string = undefined;

        if (findElseIf(if_node)) |_| {

            false_label = try convert_data.allocPrint(allocator, "if.cond.{}.{}", .{ 
                base_id, index + 1 
            });

        } else if (findElse(node) != null) {

            false_label = try convert_data.allocPrint(allocator, "if.else.{}", .{
                base_id
            });

        } else {
            false_label = merge_label;
        }

        try convert_data.appendFmt(allocator, "\tbr i1 {s}, label %{s}, label %{s}\n", .{ 
            cond_value, then_label, false_label 
        });

        // then block
        try convert_data.appendFmt(allocator, "{s}:\n", .{
            then_label
        });

        try llvm_body_mod.processBody(allocator, convert_data, if_node.right.?);

        try convert_data.appendFmt(allocator, "\tbr label %{s}\n", .{
            merge_label
        });

        // advance to else-if if present
        if (findElseIf(if_node)) |next_if| {
            if_node = next_if;
            index += 1;
        } else {
            break;
        }
    }

    // ----- ELSE BLOCK -----
    if (findElse(node)) |else_node| {

        const else_label:string = try convert_data.allocPrint(allocator, "if.else.{}", .{
            base_id
        });

        try convert_data.appendFmt(allocator, "{s}:\n", .{
            else_label
        });

        try llvm_body_mod.processBody(allocator, convert_data, else_node.right.?);

        try convert_data.appendFmt(allocator, "\tbr label %{s}\n", .{
            merge_label
        });
    }

    // ----- MERGE -----
    try convert_data.appendFmt(allocator, "{s}:\n", .{
        merge_label
    });
}


fn findElseIf(node:*ASTNode) ?*ASTNode {
    if (node.children == null) return null;

    for (node.children.?.items) |child| {
        if (child.node_type == .IfStatement) {
            return child;
        }
    }
    return null;
}

fn findElse(node:*ASTNode) ?*ASTNode {
    if (node.children == null) return null;

    for (node.children.?.items) |child| {
        if (child.node_type == .Else) {
            return child;
        }
    }
    return null;
}

fn findElseIfOrElse(node:*ASTNode) ?*ASTNode {
    if (node.children == null) return null;

    // first prefer else-if
    for (node.children.?.items) |child| {
        if (child.node_type == .IfStatement) {
            return child;
        }
    }

    // otherwise else
    for (node.children.?.items) |child| {
        if (child.node_type == .Else) {
            return child;
        }
    }

    return null;
}
