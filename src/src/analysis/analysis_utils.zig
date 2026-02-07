const std = @import("std");
const errors_mod = @import("../core/errors.zig");
const structs_mod = @import("../core/structs.zig");
const enums_mod = @import("../core/enums.zig");
const printing_mod = @import("../core/printing.zig");
const phase_1_mod = @import("phase_1.zig");
const SemanticError = errors_mod.SemanticError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ASTNode = structs_mod.ASTNode;
const Token = structs_mod.Token;
const TypeList = structs_mod.TypeList;
const StringHashMap = std.StringHashMap;
const ASTNodeType = enums_mod.ASTNodeType;
const string = []const u8;
const Type = structs_mod.Type;
const TypeMap = structs_mod.TypeMap;
const TypeId = structs_mod.TypeId;
const TypeTag = enums_mod.TypeTag;
const AnalysisData = structs_mod.AnalysisData;
const SymbolTag = enums_mod.SymbolTag;
const SymbolId = structs_mod.SymbolId;
const Symbol = structs_mod.Symbol;
const SymbolNameAndId = structs_mod.SymbolNameAndId;
const SymbolTable = structs_mod.SymbolTable;
const log = std.log;

pub fn resolveTypeFromAst(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!TypeId {

    analysis_data.error_function = "resolveTypeFromAst";

    switch (node.node_type) {

        ASTNodeType.VarType => {
            const name:string = node.token.?.Text;

            return analysis_data.type_list.type_map.getIdFromName(name) orelse {
                analysis_data.setError("Undeclared type", node.token);
                return SemanticError.Unknown_Type;
            };
        },

        ASTNodeType.Pointer => {
            const child:*ASTNode = node.left orelse { 
                analysis_data.setError("node.left is null in Pointer", node.token);
                return SemanticError.Internal_Error;
            };
            
            const elem_id:TypeId = try resolveTypeFromAst(allocator, analysis_data, child);
            return try getOrCreatePointerType(allocator, analysis_data, elem_id);
        },

        ASTNodeType.Array => {
            const child:*ASTNode = node.left orelse {
                analysis_data.setError("node.left is null in array", node.token);
                return SemanticError.Internal_Error;
            };

            const elem_id:TypeId = try resolveTypeFromAst(allocator, analysis_data, child);
            return try getOrCreateArrayType(allocator, analysis_data, elem_id, node.size);
        },

        ASTNodeType.Parameter => {
            const type_node:*ASTNode = node.left orelse {
                analysis_data.setError("node.left is null in parameter", node.token);
                return SemanticError.Invalid_Type_Expression;
            };
            return resolveTypeFromAst(allocator, analysis_data, type_node);
        },

        else => {
            analysis_data.error_detail = std.fmt.allocPrint(allocator, "nodetype {} invalid", .{node.node_type}) catch return SemanticError.Out_Of_Memory;
            return SemanticError.Invalid_Type_Expression;
        },
    }
}

fn getOrCreatePointerType(allocator:Allocator, analysis_data:*AnalysisData, elem:TypeId) SemanticError!TypeId {

    // 1. Look for existing pointer type
    const type_count:usize = analysis_data.type_list.types.items.len;
    for (0..type_count) |i| {
        const var_type:Type = analysis_data.type_list.types.items[i];

        switch (var_type.data) {
            .Pointer => |p| {
                if (p.elem == elem) {
                    return @intCast(i);
                }
            },
            else => {},
        }
    }

    // 2. Create new one
    const id:TypeId = @intCast(analysis_data.type_list.types.items.len);

    const _type:Type = .{
        .name = null,
        .data = .{
            .Pointer = .{
                .elem = elem,
            },
        },
        .type_tag = .Pointer,
    };

    analysis_data.type_list.types.append(allocator, _type) catch return SemanticError.Out_Of_Memory;

    return id;
}

pub fn getOrCreateArrayType(allocator:Allocator, analysis_data:*AnalysisData, elem:TypeId, len:?usize) SemanticError!TypeId {

    // 1. Look for existing array type
    const type_count:usize = analysis_data.type_list.types.items.len;
    for (0..type_count) |i| {
        const var_type:Type = analysis_data.type_list.types.items[i];

        switch (var_type.data) {
            .Array => |a| {
                if (a.elem == elem and a.len == len) {
                    return @intCast(i);
                }
            },
            else => {},
        }
    }

    // 2. Create new one
    const id:TypeId = @intCast(analysis_data.type_list.types.items.len);

    analysis_data.type_list.types.append(allocator, .{
        .name = null,
        .data = .{
            .Array = .{
                .elem = elem,
                .len = len,
            },
        },
        .type_tag = .Array,
    }) catch return SemanticError.Out_Of_Memory;

    return id;
}

pub fn getOrCreateFunctionType(allocator:Allocator, analysis_data:*AnalysisData, parameter_types:ArrayList(TypeId), return_type:TypeId) !TypeId {

    // 1. Search existing types

    const types:ArrayList(Type) = analysis_data.type_list.types;
    const type_count:usize = types.items.len;

    for (0..type_count) |var_type_index| {

        const var_type:Type = types.items[var_type_index];

        switch (var_type.data) {
            .Function => |func| {
                if (func.return_type != return_type) { 
                    continue;
                }
                if (func.parameters.items.len != parameter_types.items.len) {
                    continue;
                }

                var same:bool = true;
                const parameter_count:usize = func.parameters.items.len;
                for (0..parameter_count) |parameter_index| {

                    const saved_parameter:TypeId = func.parameters.items[parameter_index];
                    const input_parameter:TypeId = parameter_types.items[parameter_index];
                    if (saved_parameter != input_parameter) {
                        same = false;
                        break;
                    }
                }

                if (same) {
                    return @intCast(var_type_index);
                }
            },
            else => {},
        }
    }

    // 3. Create new function type
    const new_type = Type{
        .name = null,
        .data = .{
            .Function = .{
                .parameters = parameter_types,
                .return_type = return_type,
            },
        },
        .type_tag = .Function,
    };

    // 4. Append to type list
    try analysis_data.type_list.types.append(allocator, new_type);

    return @intCast(analysis_data.type_list.types.items.len - 1);
}

pub fn nodeProducesValue(node_type: ASTNodeType) bool {
    return switch (node_type) {
        // Literals
        .IntegerLiteral,
        .FloatLiteral,
        .BoolLiteral,
        .StringLiteral,
        .CharLiteral,
        // Expressions
        .Identifier,
        .BinaryExpression,
        .BoolExpression,
        .BoolComparison,
        .FunctionCall,
        .ArrayAccess,
        .ArrayGroup,
        .ReturnExpression,
        .PrintExpression,
        => true,

        else => false,
    };
}

pub fn addDeclarationSymbol(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode, kind:SymbolTag) SemanticError!void {

    analysis_data.error_function = "addDeclarationSymbol";
    const name:string = node.token.?.Text;
    analysis_data.log("\nadding declaration symbol '{s}'\n", .{name}, .Analysis_Phase2_Declarations);

    // Resolve declared type (NOT initializer)
    const type_node:*ASTNode = node.left orelse {
        analysis_data.setError("node.left is null in declare symbol", node.token);
        return SemanticError.Internal_Error;
    };
    const type_id:TypeId = try resolveTypeFromAst(allocator, analysis_data, type_node);
    analysis_data.log("\ttype id {}\n", .{type_id}, .Analysis_Phase2_Declarations);

    var symbol_table:*SymbolTable = &analysis_data.type_list.symbol_table;

    // === name check + reservation ===
    const get_or_put_result = symbol_table.getOrPut(name) catch {
        return SemanticError.Out_Of_Memory;
    };
    if (get_or_put_result == null) {
        return SemanticError.Internal_Error;
    }

    if (get_or_put_result.?.found_existing) {
        analysis_data.log("\t!!ERROR: name exists: {s}!!", .{name}, .Analysis_Phase2_Declarations);
        analysis_data.setError("symbol already exists", node.token);
        return SemanticError.Duplicate_Symbol;
    }

    // === generate ID only after uniqueness confirmed ===
    const symbol_id:SymbolId = @intCast(symbol_table.all_symbols.items.len);
    analysis_data.log("\tsymbol id {}\n", .{symbol_id}, .Analysis_Phase2_Declarations);

    const symbol:Symbol = .{
        .name = name,
        .kind = kind,
        .type = type_id,
        .is_const = node.is_const,
    };

    symbol_table.all_symbols.append(allocator, symbol) catch {
        return SemanticError.Out_Of_Memory;
    };

    analysis_data.log("\tadded {s} to symbols\n", .{name}, .Analysis_Phase2_Declarations);

    // === commit ID into hashmap ===
    get_or_put_result.?.value_ptr.* = symbol_id;

    analysis_data.log("\tresult value pointer set to: {}\n", .{get_or_put_result.?.value_ptr.*}, .Analysis_Phase2_Declarations);

    node.symbol_id = symbol_id;
    analysis_data.log("\tset to kind: {}\n", .{kind}, .Analysis_Phase2_Declarations);
    node.symbol_tag = kind;
    node.type_id = type_id; 
}


pub fn isScopeCreatingNodeType(node_type:ASTNodeType) bool {
    switch (node_type) {
        .IfBody, .WhileBody, .FunctionDeclaration, .ElseBody, .ForBody, .SwitchBody => {
            return true;
        },
        else => return false,
    }
}