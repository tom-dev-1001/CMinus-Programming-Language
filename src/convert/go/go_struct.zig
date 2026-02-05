const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const go_utils_mod = @import("go_utils.zig");
const flatten_expression_mod = @import("go_flatten.zig");
const print_expression_mod = @import("go_print_expressions.zig");
const go_body_mod = @import("go_body.zig");
const go_assignment_mod = @import("go_assignment.zig");
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

fn printStructMembers(allocator:Allocator, convert_data:*ConvertData, member_list:*const ArrayList(*ASTNode)) ConvertError!void { 
    const member_count:usize = member_list.items.len;
    if (member_count != 0) {

        for (0..member_count) |member_index| {

            const member_node:*ASTNode = member_list.items[member_index];
            const var_name:Token = member_node.token.?;

            if (member_node.left == null) {
                convert_data.error_detail = "member type node is null in struct";
                return ConvertError.Node_Is_Null;
            }
            const type_node:*ASTNode = member_node.left.?;

            const go_type_text:?[]const u8 = go_utils_mod.convertToGoType(type_node.token.?);
            if (go_type_text == null) {
                convert_data.error_detail = "Invalid go type";
                return ConvertError.Invalid_Var_Type;
            }
            try convert_data.appendCodeFmt(allocator, "\t{s} {s}\n", .{var_name.Text, go_type_text.?});
        }
    }
}

pub fn processStruct(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //|-.StructDeclaration 'Person' - base
    //| |-.StructMembers NA - right
    //| | |-.StructMember 'age' - child
    //| |   |-.VarType 'int' - left
    //| | |-.StructMember 'name' - child
    //| |   |-.VarType 'string' - left

    convert_data.error_function = "processStruct";

    if (node.token == null) {
        convert_data.error_detail = "no struct name";
        return ConvertError.Node_Is_Null;
    }
    if (node.right == null) {
        convert_data.error_detail = "members node is null in struct";
        return ConvertError.Node_Is_Null;
    }
    const struct_name:Token = node.token.?;

    const struct_members_node:*ASTNode = node.right.?;
    if (struct_members_node.children == null) {
        convert_data.error_detail = "member list is null in struct";
        return ConvertError.Node_Is_Null;
    }

    try convert_data.appendCodeFmt(allocator, "type {s} struct {{\n", .{struct_name.Text});


    const member_list:ArrayList(*ASTNode) = struct_members_node.children.?;

    try printStructMembers(allocator, convert_data, &member_list);

    try convert_data.appendCode(allocator, "}\n");
}