

const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../Debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const type_info_mod = @import("../../core/type_info.zig");
const llvm_utils_mod = @import("llvm_utils.zig");
const llvm_return_mod = @import("llvm_return.zig");
const llvm_declarations_mod = @import("llvm_declarations.zig");
const llvm_if_mod = @import("llvm_if.zig");
const llvm_function_call_mod = @import("llvm_function_call.zig");
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
const TypeId = structs_mod.TypeId;
const Type = structs_mod.Type;
const NO_MEMORY = ConvertError.Out_Of_Memory;

const flatten_expression_mod = @import("llvm_flatten.zig");

pub fn processArrayDeclaration(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    
    const base_type_id:TypeId = node.type_id orelse std.debug.panic("base id null in array dec", .{});

    const elem_type:Type = convert_data.type_list.getTypeAtIndex(base_type_id) orelse unreachable;
    const second_type_id:TypeId = elem_type.data.Array.elem;

    const second_type:Type = convert_data.type_list.getTypeAtIndex(second_type_id) orelse unreachable;

    const type_info = type_info_mod.getPrimitiveTypeInfo(second_type.type_tag) orelse return ConvertError.Internal_Error;

    const llvm_elem_type_text:string = type_info.backend_name.LLVM;

    //Presume it exists for now
    const group:*ASTNode = node.right orelse {
        convert_data.setError("node.right is null in array declaration", node.token);
        return ConvertError.Internal_Error;
    };

    const values:ArrayList(*ASTNode) = group.children orelse {
        convert_data.setError("node.children is null in array declaration", node.token);
        return ConvertError.Internal_Error;
    };

    const count:usize = values.items.len;
    node.size = count;

    convert_data.generated_code.appendFmt(allocator, "\t%{s} = alloca [{d} x {s}]\n", .{
        node.token.?.Text,
        count,
        llvm_elem_type_text,
    }) catch return NO_MEMORY;

    for (values.items, 0..) |elem_node, i| {

        // Flatten initializer expression
        var statements = ArrayList(string).initCapacity(allocator, 0) catch return NO_MEMORY;

        const flattened_value:string = try flatten_expression_mod.flattenExpression(allocator, convert_data, elem_node, &statements);

        for (statements.items) |stmt| {
            convert_data.generated_code.appendFmt(allocator, "\t{s}\n", .{
                stmt
            }) catch return NO_MEMORY;
        }

        const temp:string = try convert_data.getTempVarName(allocator);

        // GEP
        convert_data.generated_code.appendFmt(allocator, "\t%{s} = getelementptr [{d} x {s}], ptr %{s}, i64 0, i64 {d}\n", .{
            temp,
            count,
            llvm_elem_type_text,
            node.token.?.Text,
            i,
        }) catch return NO_MEMORY;

        // Store
        convert_data.generated_code.appendFmt(allocator, "\tstore {s} {s}, ptr {s}\n", .{
            llvm_elem_type_text,
            flattened_value,
            temp,
        }) catch return NO_MEMORY;
    }

}