


const std = @import("std");
const structs_mod = @import("../../core/structs.zig");
const printing_mod = @import("../../core/printing.zig");
const enums_mod = @import("../../core/enums.zig");
const debugging_mod = @import("../../debugging/debugging.zig");
const errors_mod = @import("../../core/errors.zig");
const llvm_utils_mod = @import("llvm_utils.zig");
const flatten_expression_mod = @import("llvm_flatten.zig");
const type_info_mod = @import("../../core/type_info.zig");
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
const PrimitiveTypeInfo = type_info_mod.PrimitiveTypeInfo;
const string = []const u8;


pub fn processReturn(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processReturn";

    if (node.right == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.right.?.token == null) {
        return ConvertError.Node_Is_Null;
    }

    const statements:*ArrayList(string) = allocator.create(ArrayList(string)) catch {
        return ConvertError.Out_Of_Memory;
    };
    statements.* = ArrayList(string).initCapacity(allocator, 0) catch {
        return ConvertError.Out_Of_Memory;
    };

    const final_value:string = try flatten_expression_mod.flattenExpression(allocator, convert_data, node.right.?, statements);

    if (statements.items.len > 0) {
        for (0..statements.items.len) |i| {
            convert_data.generated_code.appendFmt(allocator, "\t{s}\n", .{statements.items[i]}) catch return ConvertError.Out_Of_Memory;
        }
    }
    if (convert_data.function_type_id == null) {
        convert_data.setError("function_type_id is null in return", node.token);
        return ConvertError.Internal_Error;
    }
    const return_type_text:?string = convert_data.getReturnType();
    if (return_type_text == null) {
        convert_data.setError("return type text null in return", node.token);
        return ConvertError.Invalid_Return_Type;
    }

    convert_data.generated_code.appendFmt(allocator, "\tret {s} {s}\n", .{
        return_type_text.?,
        final_value,
    }) catch return ConvertError.Out_Of_Memory;
}