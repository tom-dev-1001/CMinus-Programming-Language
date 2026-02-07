


const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../Debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const llvm_utils_mod = @import("llvm_utils.zig");
const llvm_return_mod = @import("llvm_return.zig");
const llvm_declarations_mod = @import("llvm_declarations.zig");
const llvm_if_mod = @import("llvm_if.zig");
const llvm_function_call_mod = @import("llvm_function_call.zig");
const llvm_arrays_mod = @import("llvm_arrays.zig");
const llvm_while_mod = @import("llvm_while.zig");
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
const string = []const u8;
const llvm_print_mod = @import("llvm_print.zig");

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
        try processFunctionBodyNode(allocator, convert_data, child);
    }
}

fn processFunctionBodyNode(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    const node_type:ASTNodeType = node.node_type;

    if (node_type == ASTNodeType.Invalid) {
        convert_data.error_token = node.token;
        return ConvertError.Invalid_Node_Type;
    }

    switch (node_type) {

        ASTNodeType.Return => try llvm_return_mod.processReturn(allocator, convert_data, node),
        ASTNodeType.Declaration => try llvm_declarations_mod.processDeclaration(allocator, convert_data, node),
        ASTNodeType.Print => try llvm_print_mod.processPrint(allocator, convert_data, node, false),
        ASTNodeType.Println => try llvm_print_mod.processPrint(allocator, convert_data, node, true),
        ASTNodeType.FunctionCall => try llvm_function_call_mod.processFunctionCall(allocator, convert_data, node),
        ASTNodeType.IfStatement => try llvm_if_mod.processIf(allocator, convert_data, node),
        ASTNodeType.ArrayDeclaration => try llvm_arrays_mod.processArrayDeclaration(allocator, convert_data, node),
        ASTNodeType.WhileLoop => try llvm_while_mod.processWhile(allocator, convert_data, node),
        else => {
            const detail:string = try convert_data.allocPrint(allocator, "{} not implemented", .{node.node_type});
            convert_data.setError(detail, node.token);
            return ConvertError.Unimplemented_Node_Type;
        },
    }
}