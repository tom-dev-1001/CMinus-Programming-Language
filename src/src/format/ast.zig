

const std = @import("std");
const structs_mod = @import("../core/structs.zig");
const printing_mod = @import("../core/printing.zig");
const enums_mod = @import("../core/enums.zig");
const ast_integers_mod = @import("ast_integers.zig");
const ast_structs_mod = @import("ast_structs.zig");
const ast_strings_mod = @import("ast_strings.zig");
//const ast_pointers_mod = @import("ast_pointers.zig");
const debugging_mod = @import("../debugging/debugging.zig");
const errors_mod = @import("../core/errors.zig");
const ast_functions_mod = @import("ast_functions.zig");
const ast_enum_mod = @import("ast_enums.zig");
const print = std.debug.print;
const Token = structs_mod.Token;
const ASTData = structs_mod.ASTData;
const ASTNode = structs_mod.ASTNode;
const TokenType = enums_mod.TokenType;
const AstError = errors_mod.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const string = []const u8;
const CompilerSettings = structs_mod.CompilerSettings;

pub fn buildASTs(allocator:Allocator, token_list:ArrayList(Token), code:string, compiler_settings:*const CompilerSettings) !ArrayList(*ASTNode) {
    
    if (compiler_settings.output_to_file == false) {
        print("\t{s}Formatting{s}\t\t", .{printing_mod.GREY, printing_mod.RESET});
    }

    var ast_nodes = try ArrayList(*ASTNode).initCapacity(allocator, 0);

    var ast_data:ASTData = .{
        .ast_nodes = &ast_nodes,
        .token_list = token_list,
        .token_index = 0,
        .compiler_settings = compiler_settings,
    }; //A struct to avoid having 5+ parameters

    const token_count:usize = token_list.items.len;

    while (ast_data.token_index < token_count) {

        const index_before:usize = ast_data.token_index;

        processGlobalTokenAST(allocator, &ast_data, false) catch |err| {
            print("\t{s}Error{s}\n", .{printing_mod.RED, printing_mod.RESET});
            try debugging_mod.printAstError(allocator, ast_data, code);
            return err;
        };
        if (index_before == ast_data.token_index) {
            ast_data.token_index += 1;
        }
    }

    if (compiler_settings.output_to_file == false) {
        print("\t{s}Done{s}\n", .{printing_mod.CYAN, printing_mod.RESET});
    }
    return ast_nodes;
}

fn processGlobalTokenAST(allocator:Allocator, ast_data:*ASTData, is_const:bool) !void {

    ast_data.error_function = "processGlobalTokenAST";

    const first_token:Token = try ast_data.getToken();

    switch (first_token.Type) {

        TokenType.Const => {
            ast_data.token_index += 1;
            try processGlobalTokenAST(allocator, ast_data, true);
        },
        TokenType.i32, TokenType.u32, TokenType.Usize => {
            const declaration_node:*ASTNode = try ast_integers_mod.processIntDeclaration(allocator, ast_data, first_token, is_const);
            try ast_data.ast_nodes.append(allocator, declaration_node);
        },
        //TokenType.Multiply => {
            //const pointerNode:*ASTNode = try ast_pointers_mod.processPointerDeclaration(ast_data, firstToken, true, is_const, allocator);
            //try ast_data.ast_nodes.append(allocator.*, pointerNode);
        //},
        TokenType.String => {
            const string_declaration:*ASTNode = try ast_strings_mod.processStringDeclarations(allocator, ast_data, first_token, is_const);
            try ast_data.ast_nodes.append(allocator, string_declaration);
        },
        TokenType.Struct => {
            const struct_declaration_node:*ASTNode = try ast_structs_mod.processStruct(allocator, ast_data);
            try ast_data.ast_nodes.append(allocator, struct_declaration_node);
        },
        TokenType.Enum => {
            const enum_declaration_node:*ASTNode = try ast_enum_mod.processEnum(allocator, ast_data);
            try ast_data.ast_nodes.append(allocator, enum_declaration_node);
        },
        TokenType.Fn => {

            try ast_functions_mod.processFunctionDeclaration(allocator, ast_data);
        },
        else => {
            ast_data.error_detail  = "unimplemented type in ast ";
            ast_data.error_token = first_token;
            return AstError.Unimplemented_Type;
        }
    }
}
