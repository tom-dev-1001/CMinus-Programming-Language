
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

pub fn processDeclaration(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    const type_id:TypeId = node.left.?.type_id orelse
        return ConvertError.Internal_Error;

    const var_type:Type = convert_data.type_list.getTypeAtIndex(type_id) orelse unreachable;

    const type_info:?type_info_mod.PrimitiveTypeInfo = type_info_mod.getPrimitiveTypeInfo(var_type.type_tag);
    if (type_info == null) {
        return ConvertError.Internal_Error;
    }

    const llvm_type_text:string = type_info.?.backend_name.LLVM;

    convert_data.generated_code.appendFmt(allocator, "\t%{s} = alloca {s}\n", .{ 
        node.token.?.Text, llvm_type_text 
    }) catch return ConvertError.Out_Of_Memory;

    // 2. initializer
    if (node.right) |init_expr| {

        const statements:*ArrayList(string) = allocator.create(ArrayList(string)) catch {
            return ConvertError.Out_Of_Memory;
        };
        statements.* = ArrayList(string).initCapacity(allocator, 0) catch {
            return ConvertError.Out_Of_Memory;
        };

        const final_value:string = try flatten_expression_mod.flattenExpression(allocator, convert_data, init_expr, statements);

        if (statements.items.len > 0) {
            for (0..statements.items.len) |i| {
                convert_data.generated_code.appendFmt(allocator, "\t{s}\n", .{statements.items[i]}) catch return ConvertError.Out_Of_Memory;
            }
        }

        // 3. store
        convert_data.generated_code.appendFmt(allocator, "\tstore {s} {s}, {s}* %{s}\n", .{ 
            llvm_type_text, final_value, llvm_type_text, node.token.?.Text 
        }) catch return ConvertError.Out_Of_Memory;
    }
}

pub fn processGlobalDeclaration(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    const type_id:TypeId = node.left.?.type_id orelse {
        convert_data.setError("global has no type", node.token);
        return ConvertError.Internal_Error;
    };

    const var_type:Type = convert_data.type_list.getTypeAtIndex(type_id) orelse {
        convert_data.setError("invalid type", node.token);
        return ConvertError.Internal_Error;
    };

    const type_info = type_info_mod.getPrimitiveTypeInfo(var_type.type_tag) orelse {
        convert_data.setError("unsupported global type", node.token);
        return ConvertError.Internal_Error;
    };

    const llvm_type_text:string = type_info.backend_name.LLVM;
    const name:string = node.token.?.Text;

    // Default initializer
    var init_value:string = "0";

    if (node.right) |init_expr| {
        switch (init_expr.node_type) {

            .IntegerLiteral => {
                init_value = init_expr.token.?.Text;
            },

            .BoolLiteral => {
                init_value = if (std.mem.eql(u8, init_expr.token.?.Text, "true")) "1" else "0";
            },

            else => {
                convert_data.setError(
                    "global initializer must be constant",
                    init_expr.token,
                );
                return ConvertError.Unimplemented_Node_Type;
            },
        }
    }

    // Emit global
    convert_data.globals.?.appendFmt(allocator, "@{s} = global {s} {s}\n",
        .{ name, llvm_type_text, init_value 
    }) catch return ConvertError.Out_Of_Memory;
}
