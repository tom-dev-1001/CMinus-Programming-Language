

const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../Debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const llvm_function_mod = @import("llvm_function.zig");
const llvm_declarations_mod = @import("llvm_declarations.zig");
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
const CompilerSettings = structs_mod.CompilerSettings;
const string = []const u8;
const TypeList = structs_mod.TypeList;
const StringHashMap = std.StringHashMap;
const GlobalStrings = structs_mod.GlobalStrings;

pub fn convert(allocator:Allocator, ast_nodes:ArrayList(*ASTNode), code:string, compiler_settings:*const CompilerSettings, type_list:*const TypeList) ConvertError!string {

    var generated_code:StringBuilder = StringBuilder.init(allocator) catch return ConvertError.Out_Of_Memory;

    var llvm_declarations= StringBuilder.init(allocator) catch {
        return ConvertError.Out_Of_Memory;
    };
    var globals = StringBuilder.init(allocator) catch {
        return ConvertError.Out_Of_Memory;
    };
    const global_strings:GlobalStrings = .{
        .definitions = StringHashMap(string).init(allocator),
    };

    var convert_data:ConvertData = .{
        .ast_nodes = ast_nodes,
        .generated_code = &generated_code,
        .declarations = &llvm_declarations,
        .globals = &globals,
        .compiler_settings = compiler_settings,
        .type_list = type_list,
        .global_strings = global_strings,
    };

    convert_data.error_function = "convert";

    const node_count:usize = ast_nodes.items.len;
    if (node_count == 0) {
        return ConvertError.No_AST_Nodes;
    }

    convert_data.declarations.?.appendLine(allocator, "declare i32 @printf(i8*, ...)\n%string = type { i8*, i64 }\n\n") catch return ConvertError.Out_Of_Memory;

    while (convert_data.node_index < node_count) {

        const previous_index:usize = convert_data.node_index;

        processGlobalNode(allocator, &convert_data) catch |err| {
            print("{s}Error{s}\n", .{printing_mod.RED, printing_mod.RESET});
            debugging_mod.printConvertError(allocator, convert_data, code) catch |err2| {
                print("error printing convert data: {}\n",.{err2});
            };
            return err;
        };

        if (previous_index == convert_data.node_index) {
            convert_data.node_index += 1;
        }
    }
    //print("{s}Done{s}\n", .{printing_mod.CYAN, printing_mod.RESET});

    var output_builder = StringBuilder.init(allocator) catch return ConvertError.Out_Of_Memory;
    const declarations:[]u8 = llvm_declarations.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
    const generated_main_code:[]u8 = generated_code.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
    const global_code:[]u8 = globals.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;

    output_builder.append(allocator, declarations) catch return ConvertError.Out_Of_Memory;
    output_builder.append(allocator, global_code) catch return ConvertError.Out_Of_Memory;
    output_builder.append(allocator, "\n\n") catch return ConvertError.Out_Of_Memory;
    output_builder.append(allocator, generated_main_code) catch return ConvertError.Out_Of_Memory;

    const combined_output:[]u8 = output_builder.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
    return combined_output;
}

fn processGlobalNode(allocator:Allocator, convert_data:*ConvertData) ConvertError!void {

    convert_data.error_function = "processGlobalNode";

    const node:?*ASTNode = convert_data.getNode();

    if (node == null) {
        return ConvertError.Node_Is_Null;
    }

    switch (node.?.node_type) {
        ASTNodeType.FunctionDeclaration => try llvm_function_mod.processFunctionDeclaration(allocator, convert_data, node.?),
        ASTNodeType.Declaration => try llvm_declarations_mod.processGlobalDeclaration(allocator, convert_data, node.?),
        else => return ConvertError.Unimplemented_Node_Type,
    }
}