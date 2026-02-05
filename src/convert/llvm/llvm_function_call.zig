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
const TypeId = structs_mod.TypeId;
const Type = structs_mod.Type;


pub fn processFunctionCall(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processFunctionCall";

    var statements = ArrayList(string).initCapacity(allocator, 0) catch {
        return ConvertError.Out_Of_Memory;
    };

    const final_value:string = try flatten_expression_mod.flattenExpression(allocator, convert_data, node, &statements);

    _ = final_value;

    if (statements.items.len > 0) {
        for (0..statements.items.len) |i| {
            convert_data.generated_code.appendFmt(allocator, "\t{s}\n", .{statements.items[i]}) catch return ConvertError.Out_Of_Memory;
        }
    }
    //const type_id:TypeId = node.type_id orelse {
        //convert_data.setError("identifier has no type", node.token);
        //return ConvertError.Internal_Error;
    //};

    //const var_type:Type = convert_data.type_list.getTypeAtIndex(type_id) orelse unreachable;

    //const type_info:?type_info_mod.PrimitiveTypeInfo = type_info_mod.getPrimitiveTypeInfo(var_type.type_tag);
    //if (type_info == null) {
        //return ConvertError.Internal_Error;
    //}
    //const llvm_type:string = type_info.?.backend_name.LLVM;

    //convert_data.generated_code.appendFmt(allocator, "\tcall {s} {s}\n", .{
      //  llvm_type,
        //final_value,
    //}) catch return ConvertError.Out_Of_Memory;
}