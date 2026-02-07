
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

fn processNoValueArrayDeclaration(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    const var_name:Token = node.token.?;

    const type_text:[]const u8 = try print_expression_mod.printExpression(allocator, convert_data, node.left.?, false);

    const array_size:usize = node.left.?.size;

    convert_data.generated_code.appendFmt(allocator, "var {s} {s}", .{
        var_name.Text,
        type_text
    }) catch return ConvertError.Out_Of_Memory;

    if (array_size != 0) {
        
        convert_data.generated_code.appendFmt(allocator, " = make({s}, {})", .{
            type_text,
            array_size
        }) catch return ConvertError.Out_Of_Memory;
    }

    try convert_data.addNLWithTabs(allocator);
}

pub fn processArrayDeclaration(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //| | |-.ArrayDeclaration 'array' - child
    //| |   |-.Array NA - left
    //| |     |-.VarType 'int' - left
    //| |   |-.ArrayGroup '1' - right
    //| |     |-.IntegerLiteral '1' - child
    //| |     |-.IntegerLiteral '2' - child
    //| |     |-.IntegerLiteral '3' - child
    //| |     |-.IntegerLiteral '4' - child
    //| |     |-.IntegerLiteral '5' - child

    const is_invalid_declaration:bool = 
            node.token == null or
            node.left == null;

    if (is_invalid_declaration == true) {
        convert_data.error_token = node.*.token;
        convert_data.error_detail = "invalid array declaration";
        return ConvertError.Internal_Error;
    }

    try convert_data.addTab(allocator);

    if (node.right == null) {
        try processNoValueArrayDeclaration(allocator, convert_data, node);
        return;
    }

    const var_name:Token = node.token.?;

    const type_text:[]const u8 = try print_expression_mod.printExpression(allocator, convert_data, node.left.?, false);
    const array_value:[]const u8 = try print_expression_mod.printExpression(allocator, convert_data, node.right.?, false);

    if (node.right.?.node_type != ASTNodeType.ArrayGroup) {

        convert_data.generated_code.appendFmt(allocator, "var {s} {s} = {s}", .{
            var_name.Text,
            type_text,
            array_value,
        }) catch return ConvertError.Out_Of_Memory;

    } else {

        convert_data.generated_code.appendFmt(allocator, "var {s} {s} = {s}{s}", .{
            var_name.Text,
            type_text,
            type_text,
            array_value,
        }) catch return ConvertError.Out_Of_Memory;
    }
    try convert_data.addNLWithTabs(allocator);
}