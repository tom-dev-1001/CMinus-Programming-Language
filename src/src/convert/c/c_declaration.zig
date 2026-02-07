const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const c_utils_mod = @import("c_utils.zig");
const flatten_expression_mod = @import("c_flatten.zig");
const print_expression_mod = @import("c_print_expressions.zig");
const type_info_mod = @import("../../core/type_info.zig");
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
const string = []const u8;
const TypeId = structs_mod.TypeId;
const Type = structs_mod.Type;
const PrimitiveTypeInfo = type_info_mod.PrimitiveTypeInfo;

pub fn processDeclaration(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode, add_new_line:bool, add_tabs:bool) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processDeclaration";

    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.left == null) {
        return ConvertError.Node_Is_Null;
    }

    if (add_tabs == true) {
        try convert_data.addTab(allocator);
    }

    if (convert_data.compiler_settings.separate_expressions == true) {
        try processDeclarationWithFlatten(allocator, convert_data, node);
        return;
    }

    const type_id:TypeId = node.left.?.type_id orelse return ConvertError.Internal_Error;
    const var_type:Type = convert_data.type_list.getTypeAtIndex(type_id) orelse return ConvertError.Internal_Error;
    const type_info:?PrimitiveTypeInfo = type_info_mod.getPrimitiveTypeInfo(var_type.type_tag);
    var c_type:string = undefined;

    if (type_info == null) {
        c_type = var_type.name.?;
    } else {
        c_type = type_info.?.backend_name.C;
    }

    if (node.right == null) {
        convert_data.generated_code.appendFmt(allocator, "{s} {s}", .{
            c_type,
            node.*.token.?.Text,
        }) catch return ConvertError.Out_Of_Memory;
    
        if (add_new_line == true) {
            try convert_data.addNLWithTabs(allocator);
        }
        return;
    }
    if (node.right.?.token == null) {
        return ConvertError.Node_Is_Null;
    }

    const value:string = try print_expression_mod.printExpression(allocator, convert_data, node.right.?, false);

    convert_data.generated_code.appendFmt(allocator, "{s} {s} = {s};", .{
        c_type,
        node.*.token.?.Text,
        value,
    }) catch return ConvertError.Out_Of_Memory;

    if (add_new_line == true) {
        try convert_data.addNLWithTabs(allocator);
    }
}

fn processDeclarationWithFlatten(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    var statements = ArrayList(string).initCapacity(allocator, 0) catch {
        return ConvertError.Out_Of_Memory;
    };

    const left_node:*ASTNode = node.left.?;
    const type_token:Token = left_node.token.?;
    const c_type:?string = c_utils_mod.convertToCType(type_token);

    if (c_type == null) {
        convert_data.error_detail = "go type is null in processDeclaration";
        return ConvertError.Internal_Error;
    }

    const final_value:string = try flatten_expression_mod.flattenExpression(allocator, convert_data, node.right.?, true, &statements);

    if (statements.items.len > 0) {
        for (0..statements.items.len) |i| {
            convert_data.generated_code.appendFmt(allocator, "{s}", .{statements.items[i]}) catch return ConvertError.Out_Of_Memory;
            try convert_data.addNLWithTabs(allocator);
        }
    }

    convert_data.generated_code.appendFmt(allocator, "{s} {s} = {s};", .{
        c_type.?,
        node.*.token.?.Text,
        final_value,
    }) catch return ConvertError.Out_Of_Memory;

    try convert_data.addNLWithTabs(allocator);
}