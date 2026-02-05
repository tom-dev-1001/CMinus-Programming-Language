

const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../Debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const go_function_mod = @import("go_function.zig");
const go_struct_mod = @import("go_struct.zig");
const go_enum_mod = @import("go_enums.zig");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Token = structs_mod.Token;
const ASTData = structs_mod.ASTData;
const ASTNode = structs_mod.ASTNode;
const ConvertData = structs_mod.ConvertData;
const StringBuilder = structs_mod.StringBuilder;
const TokenType = enums_mod.TokenType;
const ConvertError = errors_mod.ConvertError;
const CompilerSettings = structs_mod.CompilerSettings;
const string = []const u8;
const ASTNodeType = enums_mod.ASTNodeType;
const TypeList = structs_mod.TypeList;

pub fn convert(allocator:Allocator, ast_nodes:ArrayList(*ASTNode), code:string, compiler_settings:*const CompilerSettings, type_list:*const TypeList) ConvertError!string {
    
    if (compiler_settings.output_to_file == false) {
        print("\t{s}Converting{s}\t\t", .{printing_mod.GREY, printing_mod.RESET});
    }

    var generated_code:StringBuilder = StringBuilder.init(allocator) catch return ConvertError.Out_Of_Memory;

    var convert_data:ConvertData = .{
        .ast_nodes = ast_nodes,
        .generated_code = &generated_code,
        .compiler_settings = compiler_settings,
        .type_list = type_list,
    };

    convert_data.error_function = "convert";

    const node_count:usize = ast_nodes.items.len;
    if (node_count == 0) {
        return ConvertError.No_AST_Nodes;
    }

    convert_data.generated_code.appendLine(allocator, "package main\n\nimport \"fmt\"\n\n") catch return ConvertError.Out_Of_Memory;

    while (convert_data.node_index < node_count) {

        const previous_index:usize = convert_data.node_index;

        processGlobalNode(allocator, &convert_data) catch |err| {
            print("\t{s}Error{s}\n", .{printing_mod.RED, printing_mod.RESET});
            debugging_mod.printConvertError(allocator, convert_data, code) catch |err2| {
                print("error printing convert data: {}\n",.{err2});
            };
            return err;
        };

        if (previous_index == convert_data.node_index) {
            convert_data.node_index += 1;
        }
    }
    if (compiler_settings.output_to_file == false) {
        print("\t{s}Done{s}\n", .{printing_mod.CYAN, printing_mod.RESET});
    }

    const generated_output:[]u8 = generated_code.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
    return generated_output;
}

fn processGlobalNode(allocator:Allocator, convert_data:*ConvertData) ConvertError!void {

    convert_data.error_function = "processGlobalNode";

    const node:?*ASTNode = convert_data.getNode();

    if (node == null) {
        return ConvertError.Node_Is_Null;
    }

    switch (node.?.node_type) {
        ASTNodeType.FunctionDeclaration => try go_function_mod.processFunctionDeclaration(allocator, convert_data, node.?),
        ASTNodeType.Declaration => return,
        ASTNodeType.StructDeclaration => try go_struct_mod.processStruct(allocator, convert_data, node.?),
        ASTNodeType.EnumDeclaration => try go_enum_mod.processEnum(allocator, convert_data, node.?),
        else => {
            convert_data.error_token = node.?.token;
            convert_data.error_detail = std.fmt.allocPrint(allocator, "{} not implemented yet", .{node.?.node_type}) catch return ConvertError.Out_Of_Memory;
            return ConvertError.Unimplemented_Node_Type;
        },
    }
}