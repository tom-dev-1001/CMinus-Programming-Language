


const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../Debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const print_expression_mod = @import("go_print_expressions.zig");
const go_utils_mod = @import("go_utils.zig");
const go_return_mod = @import("go_return.zig");
const go_declarations_mod = @import("go_declaration.zig");
const go_print_mod = @import("go_print.zig");
const go_if_mod = @import("go_if.zig");
const go_for_mod = @import("go_for.zig");
const go_assignment_mod = @import("go_assignment.zig");
const go_array_mod = @import("go_array.zig");
const go_switch_mod = @import("go_switch.zig");
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

const NO_NEW_LINE:bool = false;
const NEW_LINE:bool = true;
const NO_TABS:bool = false;
const TABS:bool = true;

const string = []const u8;


pub fn processBody(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    convert_data.error_function = "processBody";

    //NodeType Type
    //Children body nodes

    if (node.children == null) {
        convert_data.error_detail = "node.children is null";
        return ConvertError.Node_Is_Null;
    } 

    const child_count:usize = node.children.?.items.len;
    if (child_count == 0) {
        return;
    }
    for (0..child_count) |i| {

        const child:*ASTNode = node.children.?.items[i];
        try processFunctionBodyNode(allocator, convert_data, child, NEW_LINE, TABS);
    }
}

fn processStructMemberAccess(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    
    convert_data.error_function = "processStructMemberAccess";
    
    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.*.left == null) {
        return ConvertError.Node_Is_Null;
    }

    try convert_data.addTab(allocator);
    try convert_data.appendCodeFmt(allocator, "{s}.", .{node.token.?.Text});
    try processFunctionBodyNode(allocator, convert_data, node.left.?, NEW_LINE, NO_TABS);
}

fn processFunctionBodyNode(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode, add_new_line:bool, add_tabs:bool) ConvertError!void {

    convert_data.error_function = "processFunctionBodyNode";
    const node_type:ASTNodeType = node.node_type;

    if (node_type == ASTNodeType.Invalid) {
        convert_data.error_token = node.token;
        return ConvertError.Invalid_Node_Type;
    }

    switch (node_type) {

        ASTNodeType.StructMemberAccess => try processStructMemberAccess(allocator, convert_data, node),
        ASTNodeType.Return => try go_return_mod.processReturn(allocator, convert_data, node),
        ASTNodeType.Declaration => try go_declarations_mod.processDeclaration(allocator, convert_data, node, add_new_line, add_tabs),
        ASTNodeType.Print => try go_print_mod.processPrint(allocator, convert_data, node, false),
        ASTNodeType.Println => try go_print_mod.processPrint(allocator, convert_data, node, true),
        ASTNodeType.IfStatement => try go_if_mod.processIfStatement(allocator, convert_data, node, add_new_line, add_tabs),
        ASTNodeType.WhileLoop => try go_if_mod.processWhile(allocator, convert_data, node),
        ASTNodeType.ForLoop => try go_for_mod.processFor(allocator, convert_data, node),
        ASTNodeType.Assignment => try go_assignment_mod.processAssignment(allocator, convert_data, node, add_new_line, add_tabs),
        ASTNodeType.SwitchStatement => try go_switch_mod.printSwitch(allocator, convert_data, node),
        ASTNodeType.ArrayDeclaration => try go_array_mod.processArrayDeclaration(allocator, convert_data, node),
        ASTNodeType.Continue => { 
            try convert_data.addTab(allocator);
            convert_data.generated_code.append(allocator, "continue\n") catch return ConvertError.Out_Of_Memory;
            try convert_data.addTabs(allocator);
        },
        ASTNodeType.Break => { 
            try convert_data.addTab(allocator);
            convert_data.*.generated_code.append(allocator, "break\n") catch return ConvertError.Out_Of_Memory;
            try convert_data.addTabs(allocator);
        },
        ASTNodeType.FunctionCall => {
            const function_call_text:string = try print_expression_mod.printExpression(allocator, convert_data, node, true);
            try convert_data.addTab(allocator);
            convert_data.generated_code.appendFmt(allocator, "{s}\n", .{function_call_text}) catch return ConvertError.Out_Of_Memory;
            try convert_data.addTabs(allocator);
        },
        ASTNodeType.PrintF => {
            try go_print_mod.processPrintF(allocator, convert_data, node);
        },
        else => {   
            convert_data.error_token = node.token;
            convert_data.error_detail = std.fmt.allocPrint(allocator, "{} not implemented yet", .{node.node_type}) catch return ConvertError.Out_Of_Memory;
            return ConvertError.Unimplemented_Node_Type;
        },
    }
}