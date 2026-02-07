

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
const ArrayList = std.ArrayList;

fn fillEnum(allocator:Allocator, ast_data:*ASTData) AstError!*ASTNode {

    ast_data.error_function = "fillEnum";

    const enum_member_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
    const child_list = ArrayList(*ASTNode).initCapacity(allocator, 0) catch {
        return AstError.Out_Of_Memory;
    };
    enum_member_node.children = child_list;
    enum_member_node.node_type = ASTNodeType.EnumMembers;
    
    while (ast_data.tokenIndexInBounds()) {
        const first_token:Token = try ast_data.getToken();
        
        if (first_token.Type == TokenType.RightBrace) {
            break;
        }
        try ast_data.incrementIndex();

        if (first_token.Type != TokenType.Identifier) {
            ast_data.error_token = first_token;
            ast_data.error_detail = "Missing identifier in enum";
            return AstError.Missing_Expected_Type;
        }
        const member_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
        member_node.node_type = ASTNodeType.EnumMember;
        member_node.token = first_token;
        enum_member_node.*.children.?.append(allocator, member_node) catch return AstError.Out_Of_Memory;

        try ast_data.expectType(TokenType.Comma, "Missing expected ',' in enum");
        try ast_data.incrementIndex();
    }
    return enum_member_node;
}

pub fn processEnum(allocator:Allocator, ast_data:*ASTData) AstError!*ASTNode {

    ast_data.error_function = "processEnum";

    //enum Thing {
    //   value,
    //   name,
    //}

    try ast_data.incrementIndex();
    const enum_name_token:Token = try ast_data.getToken();

    const enum_declaration_node:*ASTNode = try ast_node_utils_mod.createDefaultAstNode(allocator);
    enum_declaration_node.node_type = ASTNodeType.EnumDeclaration;
    enum_declaration_node.token = enum_name_token;

    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.LeftBrace, "Missing '{' after enum name");
    try ast_data.incrementIndex();

    const enum_member_node:*ASTNode = try fillEnum(allocator, ast_data);

    try ast_data.expectType(TokenType.RightBrace, "Missing '}' after enum name");
    ast_data.token_index += 1;

    enum_declaration_node.right = enum_member_node;

    return enum_declaration_node;
}
