
const std = @import("std");
const structs_mod = @import("../core/structs.zig");
const enums_mod = @import("../core/enums.zig");
const expressions_mod = @import("../core/expression.zig");
const errors_mod = @import("../core/errors.zig");
const ast_node_utils_mod = @import("../core/ast_node_utils.zig");
const ast_integers_mod = @import("ast_integers.zig");
const ast_bool_mod = @import("ast_bools.zig");
const ast_variable_mod = @import("ast_variables.zig");
const ast_functions_mod = @import("ast_functions.zig");
const ASTNode = structs_mod.ASTNode;
const TokenType = enums_mod.TokenType;
const ASTData = structs_mod.ASTData;
const Token = structs_mod.Token;
const ASTNodeType = enums_mod.ASTNodeType;
const AstError = errors_mod.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn fillRegularForLoop(allocator:Allocator, ast_data:*ASTData, for_node:*ASTNode) AstError!void {

    ast_data.error_function = "fillRegularForLoop";

    const left_node:*ASTNode = try ast_integers_mod.processIntDeclarationFor(allocator, ast_data);
    const middle_node:*ASTNode = try ast_bool_mod.getValueNodeBool(allocator, ast_data);

    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in for");
    try ast_data.incrementIndex();

    const no_semicolon_expected:bool = false;
    const right_node = try ast_variable_mod.processVariableName(allocator, ast_data, no_semicolon_expected);
    for_node.node_type = ASTNodeType.ForCondition;
    for_node.left = left_node;
    for_node.middle = middle_node;
    for_node.right = right_node;
}

pub fn processFor(allocator:Allocator, ast_data:*ASTData) AstError!*ASTNode {

    ast_data.error_function = "processFor";
    var for_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);

    for_node.node_type = ASTNodeType.ForLoop;
    for_node.token = try ast_data.getToken();

    const for_condition_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);

    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.LeftParenthesis, "missing expected '(' in for");
    try ast_data.incrementIndex();

    //get bracket contents
    try fillRegularForLoop(allocator, ast_data, for_condition_node);
    try ast_data.expectType(TokenType.RightParenthesis, "missing expected ')' in for");
    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.LeftBrace, "missing expected '{' in for");
    try ast_data.incrementIndex();

    const body_node = try ast_functions_mod.buildBodyBlock(allocator, ast_data, ASTNodeType.ForBody);

    try ast_data.expectType(TokenType.RightBrace, "missing expected '}' in for");
    try ast_data.incrementIndex();

    for_node.left = for_condition_node;
    for_node.right = body_node;
    
    return for_node;
}