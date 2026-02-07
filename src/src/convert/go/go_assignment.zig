

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

pub fn processAssignment(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode, add_new_line:bool, add_tabs:bool) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processDeclaration";

    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }

    if (add_tabs == true) {
        try convert_data.addTab(allocator);
    }

    //if (convert_data.compiler_settings.separate_expressions == true) {
        //try processDeclarationWithFlatten(allocator, convert_data, node);
        //return;
    //}

    const value:[]const u8 = try print_expression_mod.printExpression(allocator, convert_data, node, false);

    convert_data.generated_code.appendFmt(allocator, "{s}", .{
        value,
    }) catch return ConvertError.Out_Of_Memory;
    
    if (add_new_line == true) {
        try convert_data.addNLWithTabs(allocator);
    }
}