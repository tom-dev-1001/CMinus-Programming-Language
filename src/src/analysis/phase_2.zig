
const std = @import("std");
const errors_mod = @import("../core/errors.zig");
const structs_mod = @import("../core/structs.zig");
const enums_mod = @import("../core/enums.zig");
const printing_mod = @import("../core/printing.zig");
const analysis_utils_mod = @import("analysis_utils.zig");
const token_utils_mod = @import("../core/token_utils.zig");
const print = std.debug.print;
const TokenType = enums_mod.TokenType;
const TypeTag = enums_mod.TypeTag;
const ASTNodeType = enums_mod.ASTNodeType;
const TypeId = structs_mod.TypeId;
const SemanticError = errors_mod.SemanticError;
const ArrayList = std.ArrayList;
const string = []const u8;
const SymbolId = structs_mod.SymbolId;
const Allocator = std.mem.Allocator;
const ASTNode = structs_mod.ASTNode;
const Token = structs_mod.Token;
const TypeList = structs_mod.TypeList;
const Type = structs_mod.Type;
const TypeMap = structs_mod.TypeMap;
const Field = structs_mod.Field;
const AnalysisData = structs_mod.AnalysisData;
const EnumVariant = structs_mod.EnumVariant;
const SymbolNameAndId = structs_mod.SymbolNameAndId;
const Symbol = structs_mod.Symbol;
const log = std.log;
const SymbolTag = enums_mod.SymbolTag;

fn setFunctionCallIds(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    analysis_data.error_function = "setFunctionCallIds";

    const token:Token = node.token orelse {
        analysis_data.setError("function call has no token", node.token);
        return SemanticError.Internal_Error;
    };

    const name:string = token.Text;

    const symbol_id:?SymbolId = analysis_data.type_list.symbol_table.lookup(name);
    if (symbol_id == null) {
        const detail:string = std.fmt.allocPrint(allocator, "Undeclared function name: {s}", .{node.token.?.Text}) catch return SemanticError.Out_Of_Memory;
        analysis_data.setError(detail, node.token);
        return SemanticError.Unresolved_Symbol;
    }

    node.symbol_id = symbol_id;
}

fn resolveExpressionType(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!TypeId {

    analysis_data.error_function = "resolveExpressionType";

    //analysis_data.log("\tnode type in resolveExpression {} token: {s}", .{node.node_type, node.token.?.Text});

    switch (node.node_type) {

        // LITERALS

        .IntegerLiteral => {
            const type_id:TypeId = analysis_data.type_list.type_map.getIdFromName("int") orelse {
                analysis_data.setError("int primitive not found", node.token);
                return SemanticError.Internal_Error;
            };
            node.type_id = type_id;
            return type_id;
        },

        .FloatLiteral => {
            const type_id:TypeId = analysis_data.type_list.type_map.getIdFromName("f32") orelse {
                analysis_data.setError("float primitive not found", node.token);
                return SemanticError.Internal_Error;
            };
            node.type_id = type_id;
            node.symbol_tag = .None;            
            return type_id;
        },

        .BoolLiteral => {
            const type_id:TypeId = analysis_data.type_list.type_map.getIdFromName("bool") orelse {
                analysis_data.setError("bool primitive not found", node.token);
                return SemanticError.Internal_Error;
            };
            node.type_id = type_id;
            node.symbol_tag = .None;            
            return type_id;
        },

        .StringLiteral => {
            const type_id:TypeId = analysis_data.type_list.type_map.getIdFromName("string") orelse {
                analysis_data.setError("string primitive not found", node.token);
                return SemanticError.Internal_Error;
            };
            node.type_id = type_id;
            node.symbol_tag = .None;            
            return type_id;
        },

        .CharLiteral => {
            const type_id:TypeId = analysis_data.type_list.type_map.getIdFromName("char") orelse {
                analysis_data.setError("char primitive not found", node.token);
                return SemanticError.Internal_Error;
            };
            node.type_id = type_id;
            node.symbol_tag = .None;            
            return type_id;
        },

        .VarType => {
            const token:Token = node.token orelse { 
                analysis_data.setError("token is null in vartype", node.token);
                return SemanticError.Internal_Error;
            };
            const type_id:TypeId = analysis_data.type_list.type_map.getIdFromName(token.Text) orelse {
                analysis_data.setError("unknown type", node.token);
                return SemanticError.Unresolved_Symbol;
            };
            node.type_id = type_id;
            node.symbol_tag = .None;            
            return type_id;
        },

        // IDENTIFIER
        .Identifier => {
            const identifier_token:Token = node.token orelse {
                analysis_data.setError("node.token is null in identifier", node.token);                
                return SemanticError.Internal_Error;
            };
            const identifier_name:string = identifier_token.Text;
            
            const symbol_id:?SymbolId = analysis_data.type_list.symbol_table.getAllScopes(identifier_name);
            
            if (symbol_id == null) {
                analysis_data.log("\t\tnot found in idenfitier: '{s}'\n", .{identifier_name}, .Analysis_Phase2_Identifiers);
                analysis_data.log("\t\tcurrent scope: {}", .{analysis_data.type_list.symbol_table.current_scope_index.?}, .Analysis_Phase2_Identifiers);
                analysis_data.setError("Undeclared identifier", node.token);
                return SemanticError.Unresolved_Symbol;
            }

            //const symbol_id:SymbolId = gop.?.value_ptr.*;

            const symbol:Symbol = analysis_data.type_list.symbol_table.all_symbols.items[symbol_id.?];
            node.type_id = symbol.type;
            node.symbol_tag = symbol.kind;
            return symbol.type;
        },

        // BINARY EXPRESSION
        .BinaryExpression, .BoolExpression, .ReturnExpression => {
            const left:*ASTNode = node.left orelse {
                analysis_data.setError("node.left is null in expression", node.token);                
                return SemanticError.Internal_Error;
            };
            const right:*ASTNode = node.right orelse {
                analysis_data.setError("node.right is null in expression", node.token);                
                return SemanticError.Internal_Error;
            };
            if (node.token == null) {
                analysis_data.setError("node.token is null in expression", node.token);    
                return SemanticError.Internal_Error;
            }

            //analysis_data.log("\tSetting node type: {}", .{node.node_type});

            const left_type:TypeId = try resolveExpressionType(allocator, analysis_data, left);
            const right_type:TypeId = try resolveExpressionType(allocator, analysis_data, right);

            const operator_token_type:TokenType = node.token.?.Type;

            //analysis_data.log("\t\toperator token type: {}", .{operator_token_type});

            // arithmetic
            if (token_utils_mod.isArithmeticOperator(operator_token_type)) {

                //analysis_data.log("\t\tis arithmetic operator", .{});

                if (left_type != right_type) {
                    analysis_data.setError("incompatible types", left.token);
                    return SemanticError.Type_Mismatch;
                }

                //analysis_data.log("\t\tnode type set: {}", .{left_type});

                node.type_id = left_type;
                return left_type;
            }

            // comparisons → bool
            if (token_utils_mod.isComparisonOperator(operator_token_type)) {

                //analysis_data.log("\t\tis comparison operator", .{});

                if (left_type != right_type) {
                    analysis_data.setError("incompatible types", left.token);                    
                    return SemanticError.Type_Mismatch;
                }

                const bool_type:TypeId = analysis_data.type_list.type_map.getIdFromName("bool") orelse return SemanticError.Internal_Error;

                //analysis_data.log("\t\tnode type set: {}", .{bool_type});

                node.type_id = bool_type;
                return bool_type;
            }

            analysis_data.setError("invalid operator", node.token);
            return SemanticError.Invalid_Operator;
        },

        // FUNCTION CALL
        .FunctionCall => {
            if (node.symbol_id == null) {
                try setFunctionCallIds(allocator, analysis_data, node);
            }
            const symbol_id:SymbolId = node.symbol_id.?;

            const symbol:Symbol = analysis_data.type_list.symbol_table.all_symbols.items[symbol_id];

            const func_type:Type = analysis_data.type_list.types.items[symbol.type];

            node.symbol_tag = .Function;

            switch (func_type.data) {

                .Function => |fn_data| {

                    if (node.children) |child_node| {

                        if (child_node.items.len != fn_data.parameters.items.len) {
                            return SemanticError.Invalid_Argument_Count;
                        }

                        for (child_node.items, fn_data.parameters.items) |arg, param_type| {

                            const arg_type:TypeId = try resolveExpressionType(allocator, analysis_data, arg);
                            
                            if (arg_type != param_type) {
                                return SemanticError.Type_Mismatch;
                            }
                        }
                    }

                    node.type_id = fn_data.return_type;
                    return fn_data.return_type;
                },
                else => { 
                    analysis_data.setError("data is not a function in function call", node.token);
                    return SemanticError.Internal_Error;
                },
            }
        },

        // ARRAY ACCESS
        .ArrayAccess => {

            const index:*ASTNode = node.left orelse {
                analysis_data.setError("left node is null in ArrayAccess", node.token);
                return SemanticError.Internal_Error;
            };

            const index_type:TypeId = try resolveExpressionType(allocator, analysis_data, index);

            const int_type:TypeId = analysis_data.type_list.type_map.getIdFromName("int") orelse {
                analysis_data.setError("left node is null in ArrayAccess", node.token);
                return SemanticError.Internal_Error;
            };

            if (index_type != int_type) {
                analysis_data.setError("type is not an int in array access", node.token);
                return SemanticError.Invalid_Array_Index;
            }

            const token:Token = node.token orelse {
                analysis_data.setError("Token is null in array access", node.token);
                return SemanticError.Internal_Error;
            };
            const array_name:string = token.Text;

            const symbol_id:?SymbolId = analysis_data.type_list.symbol_table.getAllScopes(array_name);
            if (symbol_id == null) {
                analysis_data.setError("undeclared name, array access", node.token);
                return SemanticError.Unresolved_Symbol;
            }

            const symbol:Symbol = analysis_data.type_list.symbol_table.all_symbols.items[symbol_id.?];

            const array_type:Type = analysis_data.type_list.types.items[symbol.type];

            switch (array_type.data) {
                .Array => |arr| {
                    node.type_id = arr.elem;
                    return arr.elem;
                },
                else => return SemanticError.Not_An_Array,
            }
        },

        // ARRAY LITERAL
        .ArrayGroup => {

            const children:ArrayList(*ASTNode) = node.children orelse { 
                analysis_data.setError("node.children is null", node.token);
                return SemanticError.Empty_Array;
            };
            if (children.items.len == 0) {
                analysis_data.setError("array group length is zero", node.token);
                return SemanticError.Empty_Array;
            }

            const first_type:TypeId = try resolveExpressionType(allocator, analysis_data, children.items[0]);

            for (children.items[1..]) |elem| {
                const type_id:TypeId = try resolveExpressionType(allocator, analysis_data, elem);
                if (type_id != first_type) {
                    return SemanticError.Type_Mismatch;
                }
            }

            return 0;
        },

        .Array => {
            return 0;
        },

        .Print, .Println => {

            if (node.children != null) {
                for (node.children.?.items) |child| {
                    _ = try resolveExpressionType(allocator, analysis_data, child);
                }
            }
            return 0;
        },

        else => {
            analysis_data.error_detail = std.fmt.allocPrint(allocator, "Unsupported expression type: {}\n", .{node.node_type}) catch {
                return SemanticError.Out_Of_Memory;
            };
            analysis_data.error_token = node.token;
            return SemanticError.Invalid_Expression;
        },
    }
}

fn checkExpressionsRecursive(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    // 1. Recurse first (post-order)
    if (node.left) |l| {
        try checkExpressionsRecursive(allocator, analysis_data, l);
    }

    if (node.middle) |m| {
        try checkExpressionsRecursive(allocator, analysis_data, m);
    }

    if (node.right) |r| {
        try checkExpressionsRecursive(allocator, analysis_data, r);
    }

    if (node.children) |children| {
        for (children.items) |child| {
            try checkExpressionsRecursive(allocator, analysis_data, child);
        }
    }

    // 2. Resolve *this* node if it produces a value
    if (analysis_utils_mod.nodeProducesValue(node.node_type)) {
        const type_id:TypeId = try resolveExpressionType(allocator, analysis_data, node);
        node.type_id = type_id;
    }
}

fn checkExpressions(allocator:Allocator, analysis_data:*AnalysisData) SemanticError!void {
    const node_count:usize = analysis_data.ast_nodes.items.len;

    if (node_count == 0) {
        return;
    }
    for (0..node_count) |i| {
        const node:*ASTNode = analysis_data.ast_nodes.items[i];
        try checkExpressionsRecursive(allocator, analysis_data, node);
    }
}

fn analyzeCondition(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    const cond:*ASTNode = node.left orelse return SemanticError.Internal_Error;
    const cond_type:TypeId = try resolveExpressionType(allocator, analysis_data, cond);

    const bool_type:TypeId = analysis_data.type_list.type_map.getIdFromName("bool") orelse return SemanticError.Internal_Error;

    if (cond_type != bool_type) {
        return SemanticError.Condition_Not_Bool;
    }
}

fn addParametersToScope(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    if (node.children == null) {
        analysis_data.logString("\t!!!Children is null!!!! return", .Analysis_Phase2_Parameters);
        return;
    }
    analysis_data.log("\tchild count: {}", .{node.children.?.items.len}, .Analysis_Phase2_Parameters);
    for (node.children.?.items) |parameter_node| {
        analysis_data.logString("\tlooping", .Analysis_Phase2_Parameters);
        try analysis_utils_mod.addDeclarationSymbol(allocator, analysis_data, parameter_node, .Parameter);
    }
}

fn setArraySize(analysis_data:*AnalysisData, array_node:*ASTNode) SemanticError!void {

    analysis_data.error_function = "setArraySize";

    const type_node:*ASTNode = array_node.left orelse {
        analysis_data.setError("type node is null in array declaration", array_node.token);
        return SemanticError.Internal_Error;
    };

    const value_node:*ASTNode = array_node.right orelse {
        analysis_data.setError("type value is null in array declaration", array_node.token);
        return SemanticError.Internal_Error;
    };

    if (value_node.children == null) {
        return;
    }

    type_node.size = value_node.children.?.items.len;
}

fn analyzeNode(allocator:Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    if (analysis_utils_mod.isScopeCreatingNodeType(node.node_type)) {
        try analysis_data.type_list.createScope(allocator);
        analysis_data.log("Created scope: {}", .{analysis_data.type_list.symbol_table.current_scope_index.?}, .Analysis_Phase2_Scopes);
    }

    if (node.node_type == .FunctionDeclaration) {

        analysis_data.log("Scope: {}", .{analysis_data.type_list.symbol_table.current_scope_index.?}, .Analysis_Phase2_Parameters);
        analysis_data.log("!!is fn declaration!!", .{}, .Analysis_Phase2_Parameters);

        if (node.middle) |middle| {

            analysis_data.log("\tmiddle not null", .{}, .Analysis_Phase2_Parameters);
            try addParametersToScope(allocator, analysis_data, middle);
        }
    }

    switch (node.node_type) {

        .ArrayDeclaration => {

            const is_global_definition:bool = analysis_data.type_list.symbol_table.current_scope_index == 0;

            try setArraySize(analysis_data, node);

            //globals are already added in phase 1
            if (is_global_definition == false) {
                try analysis_utils_mod.addDeclarationSymbol(allocator, analysis_data, node, .LocalVar);
            }
            if (node.left) |left| {
                _ = try resolveExpressionType(allocator, analysis_data, left);
            }
            if (node.right) |right| {
                _ = try resolveExpressionType(allocator, analysis_data, right);
            }
        },
        .Declaration, .PointerDeclaration => {

            const is_global_definition:bool = analysis_data.type_list.symbol_table.current_scope_index == 0;

            //globals are already added in phase 1
            if (is_global_definition == false) {
                try analysis_utils_mod.addDeclarationSymbol(allocator, analysis_data, node, .LocalVar);
            }
            if (node.left) |left| {
                _ = try resolveExpressionType(allocator, analysis_data, left);
            }
            if (node.right) |right| {
                _ = try resolveExpressionType(allocator, analysis_data, right);
            }
        },

        .BinaryExpression,
        .BoolExpression,
        .ReturnExpression,
        .PrintExpression,
        .Identifier,
        .FunctionCall,
        .ArrayAccess,
        .Println,
        .Print,
        .ArrayGroup => {
            _ = try resolveExpressionType(allocator, analysis_data, node);
        },

        .IfStatement,
        .WhileLoop => {
            try analyzeCondition(allocator, analysis_data, node);
        },

        else => {},
    }

    // recurse
    if (node.left) |left| try analyzeNode(allocator, analysis_data, left);
    if (node.middle) |middle| try analyzeNode(allocator, analysis_data, middle);
    if (node.right) |right| try analyzeNode(allocator, analysis_data, right);

    if (node.children) |children| {
        for (children.items) |child| {
            try analyzeNode(allocator, analysis_data, child);
        }
    }

    if (analysis_utils_mod.isScopeCreatingNodeType(node.node_type) == true) {
        analysis_data.type_list.deleteLastScope();
    }
}

pub fn runSemanticCheckingPhase2(allocator:Allocator, analysis_data:*AnalysisData) SemanticError!void {

    for (0..analysis_data.node_count) |i| {
        const node:*ASTNode = analysis_data.ast_nodes.items[i];
        try analyzeNode(allocator, analysis_data, node);
    }

}
