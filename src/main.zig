const std = @import("std");
const code_sample_mod = @import("core//code_samples/code_samples.zig");
const parse_code_mod = @import("parse/parse_code.zig");
const struct_mod = @import("core/structs.zig");
const debugging_mod = @import("debugging/debugging.zig");
const ast_mod = @import("format/ast.zig");
const convert_mod = @import("convert/convert.zig");
const static_analysis_mod = @import("analysis/static_analysis.zig");
const enums_mod = @import("core/enums.zig");
const error_mod = @import("core/errors.zig");
const debugPrint = std.debug.print;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const Token = struct_mod.Token;
const ASTNode = struct_mod.ASTNode;
const ArrayList = std.ArrayList;
const TypeList = struct_mod.TypeList;
const LanguageTarget = enums_mod.LanguageTarget;
const CompilerSettings = struct_mod.CompilerSettings;
const ASTData = struct_mod.ASTData;
const string = []const u8;
const Child = std.process.Child;
const console_mod = @import("core/console.zig");
const Console = console_mod.Console;
const DebugSettings = struct_mod.DebugSettings;

pub const std_options:std.Options = .{
    .log_level = .debug,
};

const builtin = @import("builtin");

pub fn enableWindowsAnsiColors() void {
    if (builtin.os.tag != .windows) return;
    
    const windows = std.os.windows;
    const ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;
    const STD_OUTPUT_HANDLE: windows.DWORD = @bitCast(@as(i32, -11));
    
    const handle = windows.kernel32.GetStdHandle(STD_OUTPUT_HANDLE);
    if (handle == windows.INVALID_HANDLE_VALUE) return;
    
    var mode: windows.DWORD = 0;
    if (windows.kernel32.GetConsoleMode(handle.?, &mode) == 0) return;
    
    mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    _ = windows.kernel32.SetConsoleMode(handle.?, mode);
}

fn convertCode(allocator:Allocator, code:string, compiler_settings:*const CompilerSettings) !string {

    if (compiler_settings.show_input_code == true) {
        debugPrint("Code: \n{s}\n", .{code});
    }
    //parse code
    const token_list:ArrayList(Token) = try parse_code_mod.parseToTokens(allocator, code, compiler_settings);

    defer debugging_mod.printTokens(token_list, compiler_settings);

	//build ASTs
    var ast_nodes:ArrayList(*ASTNode) = try ast_mod.buildASTs(allocator, token_list, code, compiler_settings);

    defer debugging_mod.printASTNodes(allocator, ast_nodes, compiler_settings);

    //analyse code
    const type_list:TypeList = try static_analysis_mod.analyseCode(allocator, &ast_nodes, code, compiler_settings);

    if (compiler_settings.show_symbol_table) {
        type_list.printAllTypes();
    }

    //convert code
    const converted_code:string = try convert_mod.convertCode(allocator, ast_nodes, code, compiler_settings, &type_list);

    return converted_code;
}

fn createCompileSettings() CompilerSettings {

    const debug_settings:DebugSettings = .{
        .section_bool = [41]bool{
            false, //Parsing_Strings,
            false, //Parsing_Separator,
            false, //Parsing_Char,
            false, //Parsing_Word,
            false, //Ast_Arrays, //5

            false, //Ast_Bools,
            false, //Ast_Enums,
            false, //Ast_Floats,
            false, //Ast_For,
            false, //Ast_Function, //10

            false, //Ast_If,
            false, //Ast_Integers,
            false, //Ast_Pointers,
            false, //Ast_Print,
            false, //Ast_Return,//15

            false, //Ast_Strings,
            false, //Ast_Structs,
            false, //Ast_Switch,
            false, //Ast_Utils,
            false, //Ast_Variables, //20

            false, //Ast_Main,
            false, //Analysis_Phase1_Globals,
            false, //Analysis_Phase1_Primitives,
            false, //Analysis_Phase1_Structs,
            false, //Analysis_Phase1_Enums, //25

            false, //Analysis_Phase1_Functions,
            false, //Analysis_Phase2_Scopes,
            true, //Analysis_Phase2_Declarations,
            false, //Analysis_Phase2_Expressions,
            false, //Analysis_Phase2_Conditions,//30

            false, //Analysis_Phase2_Identifiers,
            false, //Analysis_Phase2_Parameters,
            false, //Analysis_Phase2_FunctionCalls,
            false, //Converting_LLVM_Body,
            false, //Converting_LLVM_Convert,//35

            false, //Converting_LLVM_Declarations,
            false, //Converting_LLVM_Flatten,
            false, //Converting_LLVM_Functions,
            false, //Converting_LLVM_Return,
            false, //Converting_LLVM_Utils, //40

            false, //Converting_LLVM_Expressions
        },
    };

    return .{
        .language_target = LanguageTarget.LLVM,
        .separate_expressions = false,
        .show_input_code = true,
        .show_tokens = false,
        .show_ast_nodes = true,
        .output_to_file = false,
        .debug_complex_declarations = false,
        .show_symbol_table = true,
        .debug_settings = debug_settings,
    };
}

fn printOutput(allocator:Allocator, compiler_settings:*const CompilerSettings) void {
    
    const code:string = 
    \\
    \\fn int getValu() { return 1;}
    \\
    \\fn void main() {
    \\  int value = "Hello";
    \\}
    ;

    const converted_code:string = convertCode(allocator, code, compiler_settings) catch |err| {
        debugPrint("{}\n", .{err});
        return;
    };
    debugPrint("Generated_Code: \n{s}\n", .{converted_code});
}

fn outputToFile(allocator:Allocator, compiler_settings:*const CompilerSettings) !void {
    
    // Get args
    const args:[][:0]u8 = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    
    if (args.len < 3 or !std.mem.eql(u8, args[1], "run")) {
        std.debug.print("Usage: cm run <file.cm>\n", .{});
        return;
    }
    
    const source_file:[]u8 = args[2];
    
    // 1. Read source file
    const working_dir:std.fs.Dir = std.fs.cwd();
    const code:[]u8 = try working_dir.readFileAlloc(allocator, source_file, 1024 * 1024);
    defer allocator.free(code);
    
    // 2. Parse and convert (your existing code)
    const generated_go_code:string = try convertCode(allocator, code, compiler_settings);
    
    // 3. Create build directory
    const build_dir:string = ".cm_build";
    try working_dir.makePath(build_dir);
    
    // 4. Write main.go
    const go_file_path:[]u8 = try std.fs.path.join(allocator, &.{ build_dir, "main.go" });
    defer allocator.free(go_file_path);
    try working_dir.writeFile(.{ .sub_path = go_file_path, .data = generated_go_code });
    
    // 5. Write go.mod
    const go_mod_content:string = "module cmtemp\n\ngo 1.21\n";
    const go_mod_path:[]u8 = try std.fs.path.join(allocator, &.{ build_dir, "go.mod" });
    defer allocator.free(go_mod_path);
    try working_dir.writeFile(.{ .sub_path = go_mod_path, .data = go_mod_content });
    
    // 6. Run: go run main.go
    var child:Child = Child.init(&.{ "go", "run", "main.go" }, allocator);
    child.cwd = build_dir;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    
    _ = try child.spawnAndWait();
}

fn run(allocator:Allocator, compiler_settings:*const CompilerSettings) void {

    if (compiler_settings.output_to_file == false) {
        printOutput(allocator, compiler_settings);
        return;
    }

    outputToFile(allocator, compiler_settings) catch |err| {
        debugPrint("{}\n", .{err});
    };
}

pub fn main() void {

    enableWindowsAnsiColors();

    const page_allocator:Allocator = std.heap.page_allocator;
    var arena = ArenaAllocator.init(page_allocator);
    defer arena.deinit();

	const allocator:Allocator = arena.allocator();
	
	//runTests(arena_allocator);

    const compiler_settings:CompilerSettings = createCompileSettings();
    run(allocator, &compiler_settings);
}

fn runTests(allocator:Allocator) void {
    _ = allocator;
}





fn testChars() !void {

    const code:[]const u8 = code_sample_mod.SWITCH_1;

    const page_allocator:Allocator = std.heap.page_allocator;
    var arena = ArenaAllocator.init(page_allocator);
    defer arena.deinit();

    var arena_allocator:Allocator = arena.allocator();

    //parse code
    const token_list:ArrayList(Token) = parse_code_mod.parseToTokens(&arena_allocator, code) catch |err| {
        debugPrint("\tError {}\n", .{err});
        return;
    };
    var ast_nodes = try ArrayList(*ASTNode).initCapacity(arena_allocator, 0);
    var ast_data = ASTData {
        .ast_nodes = &ast_nodes,
        .token_list = token_list,
        .token_index = 0,
    }; //A struct to avoid having 5+ parameters
    ast_nodes.clearAndFree(arena_allocator);
    for (0..10) |index| {
        const token:Token = ast_data.token_list.items[index];
        ast_data.error_token = token;
        ast_data.error_detail = "example error";
        try debugging_mod.printAstError(&arena_allocator, ast_data, code);
    }
}
