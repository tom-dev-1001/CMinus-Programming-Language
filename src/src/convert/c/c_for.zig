
const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const c_utils_mod = @import("c_utils.zig");
const flatten_expression_mod = @import("c_flatten.zig");
const print_expression_mod = @import("c_print_expressions.zig");
const c_body_mod = @import("c_body.zig");
const c_assignment_mod = @import("c_assignment.zig");
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

fn processForConditionNode(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    
    const for_condition_node:*ASTNode = node.left.?;

    const for_declaration_node:?*ASTNode = for_condition_node.*.left;
    if (for_declaration_node == null) {
        return ConvertError.Node_Is_Null;
    }
    if (for_declaration_node.?.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (for_declaration_node.?.left == null) {
        return ConvertError.Node_Is_Null;
    }
    const var_name_text:[]const u8 = for_declaration_node.?.token.?.Text;
    if (for_declaration_node.?.right == null) {
        return ConvertError.Node_Is_Null;
    }
    const declaration_value_text:[]const u8 = try print_expression_mod.printExpression(allocator, convert_data, for_declaration_node.?.right.?, false);

    const for_comparison_node:?*ASTNode = for_condition_node.*.middle;
    if (for_comparison_node == null) {
        return ConvertError.Node_Is_Null;
    }
    const comparison_text:[]const u8 = try print_expression_mod.printExpression(allocator, convert_data, for_comparison_node.?, false);

    const for_assignment_node:?*ASTNode = for_condition_node.*.right;
    if (for_assignment_node == null) {
        return ConvertError.Node_Is_Null;
    }
    const assignment_text:[]const u8 = try print_expression_mod.printExpression(allocator, convert_data, for_assignment_node.?, false);

    convert_data.generated_code.appendFmt(allocator, "for (size_t {s} = {s}; {s}; {s}) {{", .{
        var_name_text,
        declaration_value_text,
        comparison_text,
        assignment_text
    }) catch return ConvertError.Out_Of_Memory;
}

pub fn processFor(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    //-ForLoop - root
    //|-ForCondition - left
    //|-ForBody - right

    //-ForCondition
    //|-Declaration - Left
    //|-Comparison  - Middle
    //|-Assignment  - Right
    
    if (node.right == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.left == null) {
        return ConvertError.Node_Is_Null;
    }

    try convert_data.addTab(allocator);

    //if (compiler_settings.separate_expressions == true) {
        //try processDeclarationWithFlatten(allocator, convert_data, node);
        //return;
    //}

    try processForConditionNode(allocator, convert_data, node);

    convert_data.incrementIndexCount();
    try convert_data.addNLWithTabs(allocator);

    if (node.right == null) {
        convert_data.error_detail = "node.Right is null";
        return ConvertError.Node_Is_Null;
    }

    try c_body_mod.processBody(allocator, convert_data, node.right.?);
    convert_data.decrementIndexCount();

    convert_data.generated_code.append(allocator, "}") catch return ConvertError.Out_Of_Memory;
    try convert_data.addNLWithTabs(allocator);
}
