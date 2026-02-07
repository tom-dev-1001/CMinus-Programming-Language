
const std = @import("std");
const errors_mod = @import("../core/errors.zig");
const structs_mod = @import("../core/structs.zig");
const enums_mod = @import("../core/enums.zig");
const printing_mod = @import("../core/printing.zig");
const phase_1_mod = @import("phase_1.zig");
const phase_2_mod = @import("phase_2.zig");
const debugging_mod = @import("../debugging/debugging.zig");
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
const AnalysisData = structs_mod.AnalysisData;
const CompilerSettings = structs_mod.CompilerSettings;
const print = std.debug.print;
const SymbolTable = structs_mod.SymbolTable;
const HashSet = structs_mod.HashSet;
const Symbol = structs_mod.Symbol;
const SymbolNameAndId = structs_mod.SymbolNameAndId;
const Scope = structs_mod.Scope;
const SymbolId = structs_mod.SymbolId;

pub fn analyseCode(allocator:Allocator, ast_nodes:*ArrayList(*ASTNode), code:string, compiler_settings:*const CompilerSettings) SemanticError!TypeList {

    const types = ArrayList(Type).initCapacity(allocator, 0) catch return SemanticError.Out_Of_Memory;
    const type_map:TypeMap = try structs_mod.newTypeTypeMap(allocator);
    
    const symbol_table:SymbolTable = .{
        .all_symbols = ArrayList(Symbol).initCapacity(allocator, 0) catch return SemanticError.Out_Of_Memory,
        .scopes = ArrayList(Scope).initCapacity(allocator, 0) catch return SemanticError.Out_Of_Memory,
    };

    var type_list:TypeList = .{
        .type_map = type_map,
        .types = types,
        .symbol_table = symbol_table,
    };

    type_list.createScope(allocator) catch return SemanticError.Out_Of_Memory;
    
    var analysis_data:AnalysisData = .{
        .ast_nodes = ast_nodes,
        .compiler_settings = compiler_settings,
        .node_count = ast_nodes.items.len,
        .node_index = 0,
        .type_list = &type_list,
    };

    analysis_data.log("Created scope: {}", .{analysis_data.type_list.symbol_table.current_scope_index.?}, .Analysis_Phase2_Scopes);

    phase_1_mod.runSemanticCheckingPhase1(allocator, &analysis_data) catch |err| {
        type_list.printAllTypes();
        print("\t{s}Error{s}\n", .{printing_mod.RED, printing_mod.RESET});
        debugging_mod.printSemanticError(allocator, analysis_data, code) catch return SemanticError.Out_Of_Memory;
        return err;
    };
    phase_2_mod.runSemanticCheckingPhase2(allocator, &analysis_data) catch |err| {
        type_list.printAllTypes();
        print("\t{s}Error{s}\n", .{printing_mod.RED, printing_mod.RESET});
        debugging_mod.printSemanticError(allocator, analysis_data, code) catch return SemanticError.Out_Of_Memory;
        return err;
    };

    return type_list;
}