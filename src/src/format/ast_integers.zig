

const std = @import("std");
const structs_mod = @import("../core/structs.zig");
const enums_mod = @import("../core/enums.zig");
const expressions_mod = @import("../core/expression.zig");
const errors_mod = @import("../core/errors.zig");
const ast_node_utils_mod = @import("../core/ast_node_utils.zig");
const ASTNode = structs_mod.ASTNode;
const ASTData = structs_mod.ASTData;
const Token = structs_mod.Token;
const TokenType = enums_mod.TokenType;
const ASTNodeType = enums_mod.ASTNodeType;
const AstError = errors_mod.AstError;
const Allocator = std.mem.Allocator;

pub fn getValueNodeI32(allocator:Allocator, ast_data:*ASTData) !*ASTNode {

    const value_node:*ASTNode = try expressions_mod.parseBinaryExprAny(allocator, ast_data, 0, ASTNodeType.BinaryExpression);
    return value_node;
}

fn processIntNoValue(allocator:Allocator, ast_data:*ASTData, type_node:*ASTNode, second_token:Token, third_token:Token) AstError!*ASTNode {
    //if not semicolon
    if (third_token.Type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected '=' or ';' in declaration";
        ast_data.error_token = third_token;
        return AstError.Unexpected_Type;
    }

    var default_text:[]u8 = allocator.alloc(u8, 1) catch return AstError.Out_Of_Memory;
    default_text[0] = '0';

    const var_node:*ASTNode =  try ast_node_utils_mod.createDefaultAstNode(allocator);

    var_node.*.node_type = ASTNodeType.IntegerLiteral;
    var_node.*.token = .{ 
        .Text = default_text[0..], 
        .CharNumber = 0, 
        .LineNumber = 0, 
        .Type = TokenType.IntegerValue
    };

    var default_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
    
    default_node.node_type = ASTNodeType.Declaration;
    default_node.token = second_token;
    default_node.left = type_node;
    default_node.right = var_node;
    return default_node;
}

pub fn processIntDeclaration(allocator:Allocator, ast_data:*ASTData, first_token:Token, is_const:bool) AstError!*ASTNode {

    ast_data.error_function = "processIntDeclaration";

    const type_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.VarType;
    type_node.token = first_token;

    //var name expected
    const second_token:Token = try ast_data.getNextToken();
    if (second_token.Type != TokenType.Identifier) {
        ast_data.error_detail = "Missing expected identifier in declaration";
        ast_data.error_token = second_token;
        return AstError.Unexpected_Type;
    }
    const third_token:Token = try ast_data.getNextToken();
    try ast_data.incrementIndex();
    
    //if not equals
    if (third_token.Type != TokenType.Equals) {
        return processIntNoValue(allocator, ast_data, type_node, second_token, third_token);
    }

    const valueNode:*ASTNode = try getValueNodeI32(allocator, ast_data);

    const fourth_token:Token = try ast_data.getToken();
    ast_data.token_index += 1;

    if (fourth_token.Type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected ';' in declaration";
        ast_data.error_token = fourth_token;
        return AstError.Unexpected_Type;
    }

    var node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);

    node.node_type = ASTNodeType.Declaration;
    node.token = second_token;
    node.left = type_node;
    node.right = valueNode;
    node.is_const = is_const;

    return node;
}

pub fn processIntDeclarationFor(allocator:Allocator, ast_data:*ASTData) AstError!*ASTNode {
    //i32 number = 10;
    ast_data.error_function = "processIntDeclarationFor";
    const first_token:Token = try ast_data.getToken();
    try ast_data.incrementIndex();

    var type_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.VarType;
    type_node.token = first_token;

    //var name expected
    const second_token:Token = try ast_data.getToken();
    try ast_data.incrementIndex();
    if (second_token.Type != TokenType.Identifier) {
        ast_data.error_token = second_token;
        ast_data.error_detail = "Missing var name in for loop declaration";
        return AstError.Missing_Expected_Type;
    }
    try ast_data.expectType(TokenType.Equals, "missing expected '=' in declaration");
    try ast_data.incrementIndex();

    const value_node:*ASTNode = try getValueNodeI32(allocator, ast_data);

    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in declaration");
    try ast_data.incrementIndex();

    var declaration_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
    declaration_node.node_type = ASTNodeType.Declaration;
    declaration_node.token = second_token; // variable name
    declaration_node.left = type_node;
    declaration_node.right = value_node;
    return declaration_node;
}
