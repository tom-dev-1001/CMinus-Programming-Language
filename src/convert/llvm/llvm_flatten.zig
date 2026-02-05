
const std = @import("std");

const structs_mod = @import("../../core/structs.zig");
const enums_mod = @import("../../core/enums.zig");
const errors_mod = @import("../../core/errors.zig");
const llvm_utils_mod = @import("llvm_utils.zig");
const debugging_scr = @import("../../debugging/debugging.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ConvertData = structs_mod.ConvertData;
const ASTNode = structs_mod.ASTNode;
const AstError = errors_mod.AstError;
const ASTNodeType = enums_mod.ASTNodeType;
const ConvertError = errors_mod.ConvertError;
const Token = structs_mod.Token;
const string = []const u8;
const printing_mod = @import("../../core/printing.zig");
const Type = structs_mod.Type;
const debug_mod = std.debug;
const Symbol = structs_mod.Symbol;
const SymbolId = structs_mod.SymbolId;
const type_info_mod = @import("../../core/type_info.zig");
const SymbolTable = structs_mod.SymbolTable;
const TypeId = structs_mod.TypeId;
const SymbolTag = enums_mod.SymbolTag;


fn convertToI32OperatorText(operator_token: Token) ?string {
    return switch (operator_token.Type) {

        // Arithmetic
        .Plus        => "add i32",
        .Minus       => "sub i32",
        .Multiply    => "mul i32",
        .Divide      => "sdiv i32",
        .Modulus     => "srem i32",

        // Comparisons
        .EqualsEquals        => "icmp eq i32",
        .NotEquals           => "icmp ne i32",
        .LessThan            => "icmp slt i32",
        .LessThanEquals      => "icmp sle i32",
        .GreaterThan         => "icmp sgt i32",
        .GreaterThanEquals   => "icmp sge i32",

        else => null,
    };
}

fn convertToI1OperatorText(operator_token: Token) ?string {
    return switch (operator_token.Type) {

        // Logical
        .AndAnd => "and i1",
        .OrOr   => "or i1",

        // Equality
        .EqualsEquals => "icmp eq i1",
        .NotEquals    => "icmp ne i1",

        else => null,
    };
}

pub fn flattenBinaryExpression(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode, statements:*ArrayList([]const u8)) ConvertError![]const u8 {
    
    convert_data.error_function = "flattenBinaryExpression";
    
    if (node.left == null) {
        convert_data.setError("Internal error: node.left is null in 'flattenBinaryExpression'", node.token);
        return ConvertError.Node_Is_Null;
    }
    if (node.right == null) {
        convert_data.setError("Internal error: node.right is null in 'flattenBinaryExpression'", node.token);
        return ConvertError.Node_Is_Null;
    }
    if (node.token == null) {
        convert_data.setError("Internal error: node.token is null in 'flattenBinaryExpression'", node.token);
        return ConvertError.Node_Is_Null;
    }

    const left_node:*ASTNode = node.left.?;
    const left_type:Type = convert_data.type_list.getTypeAtIndex(left_node.type_id.?) orelse unreachable;

    const token_operator:Token = node.token.?;
    const llvm_operator_text:?string = switch (left_type.type_tag) {
        .Int32 => convertToI32OperatorText(token_operator),
        .Bool => convertToI1OperatorText(token_operator),
        else => {
            unreachable;
        },
    };

    var left_statements = ArrayList(string).initCapacity(allocator, 0) catch {
        return AstError.Out_Of_Memory;
    };
    const left_value:string = try flattenExpression(allocator, convert_data, node.left.?, &left_statements);

    var right_statements = std.ArrayList(string).initCapacity(allocator, 0) catch {
        return AstError.Out_Of_Memory;
    };
    const right_value:string = try flattenExpression(allocator, convert_data, node.right.?, &right_statements);

     const tmp:string = convert_data.newTemp(allocator) catch {
        return ConvertError.Out_Of_Memory;
    };

    const line:[]u8 = std.fmt.allocPrint(allocator, "{s} = {s} {s}, {s}", .{
        tmp, llvm_operator_text.?, left_value, right_value
    }) catch return ConvertError.Out_Of_Memory;

    // Add all parts into the passed-in statements list
    statements.appendSlice(allocator, left_statements.items) catch return ConvertError.Out_Of_Memory;
    statements.appendSlice(allocator, right_statements.items) catch return ConvertError.Out_Of_Memory;
    statements.append(allocator, line) catch return ConvertError.Out_Of_Memory;
    return tmp;
}

fn flattenFunctionCall(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode, statements:*ArrayList([]const u8)) !string {

    const fn_name:string = node.token.?.Text;

    const symbol_table:*const SymbolTable = &convert_data.type_list.symbol_table;

    // lookup symbol
    const symbol_id:SymbolId = symbol_table.getSymbolIdFromName(fn_name) orelse {
        convert_data.setError("undeclared function", node.token);
        return ConvertError.Undeclared_Symbol;
    };

    const symbol:Symbol = symbol_table.getSymbolByIndex(symbol_id) orelse unreachable;

    // function type
    const fn_type:Type = convert_data.type_list.getTypeAtIndex(symbol.type) orelse unreachable;

    if (fn_type.type_tag != .Function) unreachable;

    const fn_data = fn_type.data.Function;

    // arguments
    const arg_nodes:ArrayList(*ASTNode) = node.children orelse {
        convert_data.setError("function call missing arguments", node.token);
        return ConvertError.Internal_Error;
    };

    if (arg_nodes.items.len != fn_data.parameters.items.len) {
        convert_data.setError("argument count mismatch", node.token);
        return ConvertError.Internal_Error;
    }

    // flatten arguments
    var args_text = ArrayList(u8).initCapacity(allocator, 0) catch {
        return ConvertError.Out_Of_Memory;
    };
    defer args_text.deinit(allocator);

    for (arg_nodes.items, 0..) |arg_node, i| {
        const arg_value:string = flattenExpression(allocator, convert_data, arg_node, statements) catch |err| {
            return err;
        };

        const arg_type_id:TypeId = fn_data.parameters.items[i];
        const arg_type:Type = convert_data.type_list.getTypeAtIndex(arg_type_id) orelse unreachable;

        const type_info:?type_info_mod.PrimitiveTypeInfo = type_info_mod.getPrimitiveTypeInfo(arg_type.type_tag);
        if (type_info == null) {
            return ConvertError.Internal_Error;
        }

        const llvm_type:string = type_info.?.backend_name.LLVM;

        std.fmt.format(
            args_text.writer(allocator),
            "{s} {s}{s}",
            .{
                llvm_type,
                arg_value,
                if (i + 1 < arg_nodes.items.len) ", " else "",
            },
        ) catch return ConvertError.Out_Of_Memory;
    }

    // return type
    const ret_type:Type = convert_data.type_list.getTypeAtIndex(fn_data.return_type) orelse unreachable;

    const type_info:?type_info_mod.PrimitiveTypeInfo = type_info_mod.getPrimitiveTypeInfo(ret_type.type_tag);
    if (type_info == null) {
        return ConvertError.Internal_Error;
    }

    const llvm_type_text:string = type_info.?.backend_name.LLVM;

    // emit call
    if (ret_type.type_tag == .Void) {
        const line:string = std.fmt.allocPrint(allocator, "call {s} @{s}({s})", .{
            "void",
            fn_name,
            args_text.items,
        }) catch return ConvertError.Out_Of_Memory;

        statements.append(allocator, line) catch return ConvertError.Out_Of_Memory;

        return "";
    } 

    const tmp:string = convert_data.newTemp(allocator) catch return ConvertError.Out_Of_Memory;

    const line:string = std.fmt.allocPrint(allocator, "{s} = call {s} @{s}({s})", .{
        tmp, llvm_type_text, fn_name, args_text.items
    }) catch return ConvertError.Out_Of_Memory;

    statements.append(allocator, line) catch return ConvertError.Out_Of_Memory;

    return tmp;

}

//returns list of strings and a string, it's recursive. false = strings allowed
pub fn flattenExpression(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode, statements:*ArrayList(string)) ConvertError![]const u8 {
    
    convert_data.error_function = "flattenExpression";

    if (node.token == null) {
        convert_data.log("Error expression: node type: {}\n", .{node.node_type}, .Converting_LLVM_Expressions);
        convert_data.error_detail = "Internal error: node.token is null in 'flattenExpression'";
        return ConvertError.Node_Is_Null;
    }

    //printing_mod.debugPrint("node type: {}\n", .{node.node_type}, "flattenExpression");

    switch (node.node_type) {

        ASTNodeType.BinaryExpression, ASTNodeType.ReturnExpression, ASTNodeType.PrintExpression, ASTNodeType.Parameter, ASTNodeType.BoolExpression => {
            return try flattenBinaryExpression(allocator, convert_data, node, statements);
        },

        ASTNodeType.Identifier => return processIdentifier(allocator, convert_data, node, statements),

        ASTNodeType.IntegerLiteral => {
            return node.token.?.Text;
        },
        ASTNodeType.BoolLiteral => {
            const text:string = node.token.?.Text;
            if (printing_mod.twoSlicesAreTheSame(text, "true") == true) {
                return "1";
            }
            return "0";
        },

        ASTNodeType.Minus => {
            // flatten inner expression first
            const value:string = try flattenExpression(allocator, convert_data, node.left.?, statements);
            // generate a temp
            const tmp:string = try convert_data.newTemp(allocator); // e.g. "%tmp3"

            const left_type:Type = convert_data.type_list.getTypeAtIndex(node.left.?.type_id.?) orelse unreachable;

            const op:string = switch (left_type.type_tag) {
                .Int32 => "sub i32 0, ",
                .Bool  => unreachable, // unary minus on bool is illegal
                .F32   => "fsub float 0.0, ",
                .F64   => "fsub double 0.0, ",
                else => unreachable,
            };

            const line:string = std.fmt.allocPrint(allocator, "{s} = {s}{s}", .{ 
                tmp, op, value 
            }) catch return ConvertError.Out_Of_Memory;

            statements.append(allocator, line) catch return ConvertError.Out_Of_Memory;
            return tmp;
        },
        ASTNodeType.CharLiteral => {
            const text:string = node.token.?.Text;
            if (text.len != 1) unreachable;

            const value:u8 = text[0];

            return std.fmt.allocPrint(allocator, "i8 {}", .{value}) catch return ConvertError.Out_Of_Memory;
        },

        ASTNodeType.StringLiteral => {
            return try convert_data.emitGlobalString(allocator, convert_data, node.token.?.Text);
        },

        ASTNodeType.FunctionCall => {
            return try flattenFunctionCall(allocator, convert_data, node, statements);
        },



        //ASTNodeType.ArrayAccess:

            //return WriteArrayAccess(ref cpp_data, ref node, statements, ref localDefinitions);

        //ASTNodeType.StructVariable:

            //Debug.Assert(node.Left != null);
            //Debug.Assert(node.Left.Token != null);
          //  return $"{node.Token.Value.Text}.{node.Left.Token.Value.Text}";

        else => {
            convert_data.error_detail = std.fmt.allocPrint(allocator, "node type: {}", .{node.node_type}) catch {
                return ConvertError.Out_Of_Memory;
            };
            convert_data.error_token = node.token;
            return ConvertError.Unimplemented_Node_Type;
        },
    }
}

fn createStringLiteral(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!string {
    const id:usize = convert_data.index_count;
    convert_data.index_count += 1;

    const global_name:[]u8 = std.fmt.allocPrint(allocator, ".str.{d}", .{id}) catch return ConvertError.Out_Of_Memory;
    const literal_text:string = node.token.?.Text;
    const literal_length:usize = literal_text.len;

    convert_data.globals.?.appendLineFmt(allocator,  
        "@{s} = private unnamed_addr constant [{} x i8] c\"{s}\\00\"", .{ 
            global_name, literal_length + 1, literal_text 
        },
    ) catch return ConvertError.Out_Of_Memory;

    const ptr_tmp_index:usize = convert_data.temp_var_count;
    convert_data.temp_var_count += 1;

    convert_data.generated_code.appendLineFmt(allocator,
        "\t%t{} = getelementptr [{} x i8], [{} x i8]* @{s}, i32 0, i32 0", .{ 
            ptr_tmp_index, literal_length + 1, literal_length + 1, global_name 
        },
    ) catch return ConvertError.Out_Of_Memory;

    const str_tmp1_index:usize = convert_data.temp_var_count;
    convert_data.temp_var_count += 1;

    convert_data.generated_code.appendLineFmt(allocator,
        "\t%t{} = insertvalue %string undef, i8* %t{}, 0", .{ 
            str_tmp1_index, ptr_tmp_index 
    }) catch return ConvertError.Out_Of_Memory;

    const str_tmp2_index:usize = convert_data.temp_var_count;
    convert_data.temp_var_count += 1;

    convert_data.generated_code.appendLineFmt(
        allocator,
        "\t%t{} = insertvalue %string %t{d}, i64 {}, 1", .{ 
            str_tmp2_index, str_tmp1_index, literal_length 
        },
    ) catch return ConvertError.Out_Of_Memory;
    
    return std.fmt.allocPrint(allocator, "%t{}", .{str_tmp2_index}) catch return ConvertError.Out_Of_Memory;
}

pub fn processIdentifier(allocator:Allocator, convert_data:*ConvertData, node:*ASTNode, statements:*ArrayList(string)) ConvertError![]const u8 {

    convert_data.error_function = "processIdentifier";

    const name:string = node.token.?.Text;

    const symbol_tag:SymbolTag = node.symbol_tag orelse {
        convert_data.setError("symbol tag not set for identifier", node.token);
        return ConvertError.Internal_Error;
    };

    const type_id:TypeId = node.type_id orelse {
        convert_data.setError("type id not set", node.token);
        return ConvertError.Internal_Error;
    };
    const llvm_type:string = try convert_data.typeToLLVM(allocator, type_id, node.token, false);

    switch (symbol_tag) {

        .Parameter => {
            return try convert_data.allocPrint(allocator, "%{s}", .{name});
        },

        .LocalVar => {
            const tmp:string = try convert_data.newTemp(allocator);

            const line:string = try convert_data.allocPrint(allocator, "{s} = load {s}, {s}* %{s}", .{ 
                tmp, llvm_type, llvm_type, name 
            });

            statements.append(allocator, line) catch return ConvertError.Out_Of_Memory;

            return tmp;
        },
        .GlobalVar => {
            const tmp:string = try convert_data.newTemp(allocator);

            const line:string = try convert_data.allocPrint(allocator, "{s} = load {s}, {s}* @{s}", .{ 
                tmp, llvm_type, llvm_type, name 
            });

            statements.append(allocator, line) catch return ConvertError.Out_Of_Memory;

            return tmp;
        },

        else => {
            convert_data.setError("invalid identifier kind", node.token);
            return ConvertError.Internal_Error;
        },
    }
}

