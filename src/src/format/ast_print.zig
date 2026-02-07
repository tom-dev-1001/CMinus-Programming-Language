

const std = @import("std");
const structs_mod = @import("../core/structs.zig");
const enums_mod = @import("../core/enums.zig");
const token_utils_mod = @import("../core/token_utils.zig");
const expressions_mod = @import("../core/expression.zig");
const errors_mod = @import("../core/errors.zig");
const ast_node_utils_mod = @import("../core/ast_node_utils.zig");
const ast_integers_mod = @import("ast_integers.zig");
const ast_pointer_mod = @import("ast_pointers.zig");
const ast_return_mod = @import("ast_return.zig");
const ast_strings_mod = @import("ast_strings.zig");
const ast_utils_mod = @import("ast_utils.zig");
const print = std.debug.print;
const ASTNode = structs_mod.ASTNode;
const TokenType = enums_mod.TokenType;
const ASTData = structs_mod.ASTData;
const Token = structs_mod.Token;
const ASTNodeType = enums_mod.ASTNodeType;
const AstError = errors_mod.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn processPrintF(allocator:Allocator, ast_data:*ASTData, new_line:bool) !*ASTNode {

    ast_data.error_function = "processPrintF";

    var print_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
    const child_list = ArrayList(*ASTNode).initCapacity(allocator, 0) catch {
        return AstError.Out_Of_Memory;
    };
    print_node.children = child_list;

    print_node.node_type = ASTNodeType.PrintF;

    print_node.token = try ast_data.*.getToken();
    //skip print
    ast_data.token_index += 1;

    try ast_data.expectType(TokenType.LeftParenthesis, "missing expected '(' in print");
    ast_data.token_index += 1;

    const index_before:usize = ast_data.token_index;

    try ast_utils_mod.fillNodeInBrackets(allocator, ast_data, print_node, ASTNodeType.PrintExpression);

    const isEmptyPrint:bool = index_before == ast_data.token_index;

    if (isEmptyPrint == true) {

        if (new_line == false) {
            ast_data.error_detail = "empty print function";
            return AstError.Unexpected_Type;
        }
    }

    try ast_data.expectType(TokenType.RightParenthesis, "missing expected ')' in print");
    ast_data.token_index += 1;
    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in print");
    ast_data.token_index += 1;

    return print_node;
}

pub fn processPrint(allocator:Allocator, ast_data:*ASTData, new_line:bool) !*ASTNode {

    ast_data.error_function = "processPrint";

    var print_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
    const child_list = ArrayList(*ASTNode).initCapacity(allocator, 0) catch {
        return AstError.Out_Of_Memory;
    };
    print_node.children = child_list;

    if (new_line == true) {
        print_node.node_type = ASTNodeType.Println;
    } else {
        print_node.node_type = ASTNodeType.Print;
    }

    print_node.token = try ast_data.*.getToken();
    //skip print
    ast_data.token_index += 1;

    try ast_data.expectType(TokenType.LeftParenthesis, "missing expected '(' in print");
    ast_data.token_index += 1;

    const index_before:usize = ast_data.token_index;

    try ast_utils_mod.fillNodeInBrackets(allocator, ast_data, print_node, ASTNodeType.PrintExpression);

    const isEmptyPrint:bool = index_before == ast_data.token_index;

    if (isEmptyPrint == true) {

        if (new_line == false) {
            ast_data.error_detail = "empty print function";
            return AstError.Unexpected_Type;
        }
    }

    try ast_data.expectType(TokenType.RightParenthesis, "missing expected ')' in print");
    ast_data.token_index += 1;
    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in print");
    ast_data.token_index += 1;

    return print_node;
}