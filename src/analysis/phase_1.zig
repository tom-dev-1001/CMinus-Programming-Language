const std = @import("std");
const errors_mod = @import("../core/errors.zig");
const structs_mod = @import("../core/structs.zig");
const enums_mod = @import("../core/enums.zig");
const printing_mod = @import("../core/printing.zig");
const analysis_utils_mod = @import("analysis_utils.zig");
const TypeTag = enums_mod.TypeTag;
const TypeId = structs_mod.TypeId;
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
const Field = structs_mod.Field;
const AnalysisData = structs_mod.AnalysisData;
const EnumVariant = structs_mod.EnumVariant;
const print = std.debug.print;
const SymbolId = structs_mod.SymbolId;
const SymbolNameAndId = structs_mod.SymbolNameAndId;
const Symbol = structs_mod.Symbol;
const HashSet = structs_mod.HashSet;
const SymbolTable = structs_mod.SymbolTable;
const log = std.log;

fn getStructName(allocator:Allocator, node:*ASTNode, analysis_data:*AnalysisData) SemanticError!void {
    
    analysis_data.error_function = "getStructName";
    
    const struct_name:string = node.*.token.?.Text;
    const id:TypeId = try addType(allocator, analysis_data, struct_name, TypeTag.Struct);
    try analysis_data.type_list.type_map.appendID(allocator, struct_name, id);
}

fn getStructAndEnumNames(allocator:Allocator, analysis_data:*AnalysisData) SemanticError!void {
    
    analysis_data.error_function = "getStructAndEnumNames";

    var node_index:usize = 0;

    while (node_index < analysis_data.node_count) {
        const last_index:usize = node_index;

        const node:*ASTNode = analysis_data.ast_nodes.items[node_index];

        if (node.node_type == ASTNodeType.StructDeclaration) {
            try getStructName(allocator, node, analysis_data);
        }

        if (last_index == node_index) {
            node_index += 1;
        }
    }
}

fn addType(allocator:Allocator, analysis_data:*AnalysisData, name:string, tag:TypeTag) SemanticError!TypeId {
   
    analysis_data.error_function = "addType";

    const id:TypeId = @intCast(analysis_data.type_list.types.items.len);
    const var_type: Type = switch (tag) {
        .None => .{ .name = name, .data = .None, .type_tag = .None },
        .Void => .{ .name = name, .data = .Void, .type_tag = .Void },
        .Int32 => .{ .name = name, .data = .Int32, .type_tag = .Int32 },
        .Int64 => .{ .name = name, .data = .Int64, .type_tag = .Int64 },
        .F32 => .{ .name = name, .data = .F32, .type_tag = .F32 },
        .F64 => .{ .name = name, .data = .F64, .type_tag = .F64 },
        .Bool => .{ .name = name, .data = .Bool, .type_tag = .Bool },
        .Char => .{ .name = name, .data = .Char, .type_tag = .Char },
        .String => .{ .name = name, .data = .String, .type_tag = .String },

        .Struct => .{
            .name = name,
            .data = .{
                .Struct = .{
                    .fields = ArrayList(Field).initCapacity(allocator, 0) catch return SemanticError.Out_Of_Memory,
                },
            },
            .type_tag = .Struct,
        },

        .Enum => .{
            .name = name,
            .data = .{
                .Enum = .{
                    .variants = ArrayList(EnumVariant).initCapacity(allocator, 0) catch return SemanticError.Out_Of_Memory,
                },
            },
            .type_tag = .Enum,
        },

        // These MUST NOT be created here
        .Pointer, .Array, .Function => {
            analysis_data.setError("pointer, array or function shouldn't be added here", null);
            return SemanticError.Internal_Error;
        },
    };
    analysis_data.type_list.types.append(allocator, var_type) catch return SemanticError.Out_Of_Memory;
    return id;
}

fn addPrimitiveTypes(allocator:Allocator, analysis_data:*AnalysisData) SemanticError!void {

    analysis_data.error_function = "addPrimitiveTypes";

    var id:TypeId = undefined;
    id = try addType(allocator, analysis_data, "int", TypeTag.Int32);
    try analysis_data.type_list.type_map.appendID(allocator, "int", id);

    id = try addType(allocator, analysis_data, "i64", TypeTag.Int64);
    try analysis_data.type_list.type_map.appendID(allocator, "i64", id);

    id = try addType(allocator, analysis_data, "bool", TypeTag.Bool);
    try analysis_data.type_list.type_map.appendID(allocator, "bool", id);

    id = try addType(allocator, analysis_data, "string", TypeTag.String);
    try analysis_data.type_list.type_map.appendID(allocator, "string", id);

    id = try addType(allocator, analysis_data, "char", TypeTag.Char);
    try analysis_data.type_list.type_map.appendID(allocator, "char", id);
    
    id = try addType(allocator, analysis_data, "void", TypeTag.Void);
    try analysis_data.type_list.type_map.appendID(allocator, "void", id);

    id = try addType(allocator, analysis_data, "f32", TypeTag.F32);
    try analysis_data.type_list.type_map.appendID(allocator, "f32", id);

    id = try addType(allocator, analysis_data, "f64", TypeTag.F64);
    try analysis_data.type_list.type_map.appendID(allocator, "f64", id);
}

fn getParameterTypes(allocator:Allocator, analysis_data:*AnalysisData, middle_node:*ASTNode, parameter_types:*ArrayList(TypeId)) SemanticError!void {

    analysis_data.error_function = "getParameterTypes";

    //|-.FunctionDeclaration 'add' - base
    //| |-.VarType 'int' - left
    //| |-.Parameters NA - middle
    //| | |-.Parameter 'a' - child
    //| |   |-.VarType 'int' - left
    //| | |-.Parameter 'b' - child
    //| |   |-.VarType 'int' - left

    if (middle_node.children == null) {
        analysis_data.setError("children is null in parameters", middle_node.token);
        return SemanticError.Internal_Error;
    }

    const children:ArrayList(*ASTNode) = middle_node.children.?;

    const child_count:usize = middle_node.children.?.items.len;
    for (0..child_count) |i| {
        const parameter_node:*ASTNode = children.items[i];
        const parameter_type_id:TypeId = try analysis_utils_mod.resolveTypeFromAst(allocator, analysis_data, parameter_node);
        parameter_types.append(allocator, parameter_type_id) catch return SemanticError.Out_Of_Memory;
    }   
}

fn collectFunction(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    analysis_data.error_function = "collectFunction";

    if (node.token == null) {
        analysis_data.setError("function name token is null", node.token);
        return SemanticError.Internal_Error;
    }

    const name:string = node.token.?.Text;
    var symbol_table:*SymbolTable = &analysis_data.type_list.symbol_table;

    // === reserve symbol name ===
    const gop = symbol_table.getOrPut(name) catch {
        return SemanticError.Out_Of_Memory;
    };
    if (gop == null) {
        analysis_data.setError("scope was null", node.token);
        return SemanticError.Internal_Error;
    }

    if (gop.?.found_existing) {
        analysis_data.setError("symbol redefinition", node.token);
        return SemanticError.Duplicate_Symbol;
    }

    // Resolve return type
    const ret_type_ast:*ASTNode = node.left orelse {
        analysis_data.setError("left node is null in function", node.token);
        return SemanticError.Internal_Error;
    };

    const return_type:TypeId = try analysis_utils_mod.resolveTypeFromAst(allocator, analysis_data, ret_type_ast);

    // Resolve params
    var parameter_types = ArrayList(TypeId).initCapacity(allocator, 0) catch {
        return SemanticError.Out_Of_Memory;
    };

    if (node.middle) |middle_node| {
        try getParameterTypes(
            allocator,
            analysis_data,
            middle_node,
            &parameter_types,
        );
    }

    const func_type_id:TypeId = analysis_utils_mod.getOrCreateFunctionType(allocator, analysis_data, parameter_types, return_type) catch {
        return SemanticError.Out_Of_Memory;
    };

    // === create symbol ===
    const symbol_id:SymbolId = @intCast(symbol_table.all_symbols.items.len);

    const symbol:Symbol = .{
        .name = name,
        .kind = .Function,
        .type = func_type_id,
    };

    symbol_table.all_symbols.append(allocator, symbol) catch {
        return SemanticError.Out_Of_Memory;
    };

    // === commit symbol id ===
    gop.?.value_ptr.* = symbol_id;

    node.symbol_id = symbol_id;
    node.type_id = func_type_id;
    node.symbol_tag = .Function;
}


fn resolveGlobalVariables(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    analysis_data.error_function = "resolveGlobalVariables";

    if (node.node_type != ASTNodeType.Declaration) {
        return;
    }

    // 1. Name
    const name_token:Token = node.token orelse {
        analysis_data.setError("no token in ast", null);
        return SemanticError.Internal_Error;
    };
    const var_name:string = name_token.Text;

    analysis_data.log("Adding global variable: '{s}'", .{var_name}, .Analysis_Phase1_Globals);

    var symbol_table:*SymbolTable = &analysis_data.type_list.symbol_table;

    // === reserve name in symbol map ===
    const gop = symbol_table.getOrPut(var_name) catch {
        return SemanticError.Out_Of_Memory;
    };
    if (gop == null) {
        analysis_data.setError("scope was null", name_token);
        return SemanticError.Internal_Error;
    }

    if (gop.?.found_existing) {
        analysis_data.setError("symbol redefinition", node.token);
        return SemanticError.Duplicate_Symbol;
    }

    // 2. Type AST
    const type_ast:*ASTNode = node.left orelse {
        analysis_data.setError("global variable has no left node", node.token);
        return SemanticError.Internal_Error;
    };

    const type_id:TypeId = try analysis_utils_mod.resolveTypeFromAst(allocator, analysis_data, type_ast);

    // 3. Insert symbol
    const symbol_id:SymbolId = @intCast(symbol_table.all_symbols.items.len);
    analysis_data.log("added symbol id: {}", .{symbol_id}, .Analysis_Phase1_Globals);

    symbol_table.all_symbols.append(allocator, .{
        .name = var_name,
        .kind = .GlobalVar,
        .type = type_id,
        .is_const = node.is_const,
    }) catch {
        return SemanticError.Out_Of_Memory;
    };

    // === commit symbol id ===
    gop.?.value_ptr.* = symbol_id;

    // 4. Annotate AST
    node.symbol_id = symbol_id;
    node.type_id = type_id;
    node.symbol_tag = .GlobalVar;
}


fn resolveStructBodies(allocator:Allocator, analysis_data:*AnalysisData) SemanticError!void {

    analysis_data.error_function = "resolveStructBodies";

    for (0..analysis_data.node_count) |i| {

        const node:*ASTNode = analysis_data.ast_nodes.items[i];

        if (node.node_type != ASTNodeType.StructDeclaration) {
            continue;
        }

        // 1. Struct name
        if (node.token == null) {
            return SemanticError.Internal_Error;
        }

        const struct_name:string = node.token.?.Text;

        // 2. Lookup TypeId
        const struct_id:TypeId = analysis_data.type_list.type_map.getIdFromName(struct_name) orelse {
            analysis_data.setError("struct name undeclared", node.token);
            return SemanticError.Unknown_Type;
        };
        
        var struct_type:*Type = analysis_data.getTypeFromId(struct_id);

        switch (struct_type.data) {
            .Struct => {
            },
            else => {
                analysis_data.setError("type is not a struct in struct def", node.token);
                return SemanticError.Internal_Error;
            },
        }
                
        struct_type.data = .{
            .Struct = .{
                .fields = ArrayList(Field).initCapacity(allocator, 0) catch return SemanticError.Out_Of_Memory,
            },
        };
        
        // 5. Get members node
        const members_node:*ASTNode = node.right orelse {
            analysis_data.setError("node.right is null in struct", node.token);
            return SemanticError.Internal_Error;
        };

        const members:ArrayList(*ASTNode) = members_node.children orelse {
            analysis_data.setError("children is null in struct", node.token);
            return SemanticError.Internal_Error;
        };

        // 6. Walk members
        for (members.items) |member_node| {

            if (member_node.node_type != ASTNodeType.StructMember) {
                analysis_data.setError("struct member != ASTNodeType.StructMember", member_node.token);
                return SemanticError.Internal_Error;
            }

            if (member_node.token == null) {
                analysis_data.setError("struct member token is null", member_node.token);
                return SemanticError.Internal_Error;
            }

            const field_name:[]const u8 = member_node.token.?.Text;

            const type_ast:*ASTNode = member_node.left orelse {
                analysis_data.setError("struct member.left is null", member_node.token);
                return SemanticError.Internal_Error;
            };

            const field_type_id:TypeId = try analysis_utils_mod.resolveTypeFromAst(allocator, analysis_data, type_ast);

            //Get the pointer again just in case the append invalidated it
            struct_type = analysis_data.getTypeFromId(struct_id);

            const field:Field = .{
                .name = field_name,
                .type = field_type_id,
            };

            struct_type.data.Struct.fields.append(allocator, field) catch {
                return SemanticError.Out_Of_Memory;
            };
        }
    }
}

fn getFunctionsAndGlobals(allocator:Allocator, analysis_data:*AnalysisData) SemanticError!void {
    
    analysis_data.error_function = "getFunctionsAndGlobals";

    for (0..analysis_data.node_count) |i| {
        const node:*ASTNode = analysis_data.ast_nodes.items[i];
        switch (node.node_type) {
            .FunctionDeclaration => try collectFunction(allocator, analysis_data, node),
            .Declaration => try resolveGlobalVariables(allocator, analysis_data, node),
            else => {}
        }
    }

}

pub fn runSemanticCheckingPhase1(allocator:Allocator, analysis_data:*AnalysisData) SemanticError!void {
   
    analysis_data.error_function = "runSemanticCheckingPhase1";

    try addPrimitiveTypes(allocator, analysis_data);
    try getStructAndEnumNames(allocator, analysis_data);
    try resolveStructBodies(allocator, analysis_data);
    try getFunctionsAndGlobals(allocator, analysis_data);
}