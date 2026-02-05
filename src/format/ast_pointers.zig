

const std = @import("std");
const structs_mod = @import("../core/structs.zig");
const expressions_mod = @import("../core/expression.zig");
const enums_mod = @import("../core/enums.zig");
const errors_mod = @import("../core/errors.zig");
const token_utils_mod = @import("../core/token_utils.zig");
const ast_node_utils_mod = @import("../core/ast_node_utils.zig");
const ASTNode = structs_mod.ASTNode;
const Token = structs_mod.Token;
const ASTData = structs_mod.ASTData;
const TokenType = enums_mod.TokenType;
const AstError = errors_mod.AstError;
const ASTNodeType = enums_mod.ASTNodeType;
const Allocator = std.mem.Allocator;

pub fn processPointerDeclaration(allocator:Allocator, ast_data:*ASTData, first_token:Token, is_global:bool, is_const:bool) !*ASTNode {
    //i32 number = 10;

    ast_data.error_function = "processPointerDeclaration";
    const type_node:?*ASTNode = try expressions_mod.createComplexDeclarations(allocator, ast_data);

    const name_token:Token = try ast_data.getToken();

    if (name_token.Type != TokenType.Identifier) {
        ast_data.error_detail = "Expected varname after array type";
        return AstError.Missing_Expected_Type;
    }

    const equalsToken:Token = try ast_data.getNextToken(ast_data);

    if (equalsToken.Type != TokenType.Equals) {
        ast_data.ErrorDetail = "Expected equals after array name, uninitialised arrays not implemented yet";
        return AstError.Missing_Expected_Type;
    }
    ast_data.token_index += 1;

    const valueNode:*ASTNode = try expressions_mod.parseBinaryExprAny(ast_data, 0, ASTNodeType.BinaryExpression, allocator);
    const end_token:Token = try ast_data.getToken();

    if (end_token.Type != TokenType.Semicolon) {

        ast_data.token_index -= 1;

        if (end_token.Type != TokenType.Semicolon) {
            ast_data.error_detail = "Missing expected ';' after declaration";
            return AstError.Missing_Expected_Type;
        }
    }
    ast_data.token_index += 1;

    type_node.?.Token = first_token;

    var node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);

    node.node_type = ASTNodeType.PointerDeclaration;
    node.token = name_token;
    node.left = type_node.?;
    node.right = valueNode;
    node.is_global = is_global;
    node.is_const = is_const;

    return node;
}