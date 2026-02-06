**C- Language Project — Compiler & Language Design Experiment**

C- is an experimental programming language and compiler project built to explore and demonstrate how modern programming languages are designed and implemented from first principles.  

The goal of this project is not to create a production-ready language, but to:

- Learn the full compiler pipeline in practice  
- Build a real language implementation  
- Teach others through a YouTube tutorial series  
- Showcase compiler engineering and systems programming skills  

This project demonstrates the complete workflow of language creation, from source code parsing to executable generation.

## Technical Highlights

- Written in Zig with full manual memory management
- Recursive descent parser
- Complete AST + type resolution system
- Manual LLVM IR code generation (no LLVM API)
- Multi-target backend architecture (Go, C, LLVM IR)

**Key Features**  
Language Design

- C-like syntax with modernized constructs
- fn keyword for function definitions
- Explicit, readable syntax
- Designed for simplicity and clarity

Example:
```C
fn int add(int a, int b) {
    return a + b;
}
fn void main() {
    int result = add(10, 10);
    println("Result: ", result);
}
```
Fully implemented in the Zig programming language:  

```Zig

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

```


**Compiler Pipeline**

The project implements a complete compiler frontend and multiple backends:

**Tokenizer / Lexer**

Parses input code:  
```C
fn void main() {
    int value = 1;
        
    if (value > 1) {
        println("Value is higher than one")
    } else if (value < 1) {
        println("Value is less than one")
    } else {
        println("Value is one")
    }
}
```
into Tokens:  
<img width="773" height="713" alt="image" src="https://github.com/user-attachments/assets/7b0dd25c-ca3d-475b-95c3-84d5e36607ea" />

**Abstract Syntax Tree (AST) generation**
  
Formats tokens into ASTs:  
<img width="917" height="524" alt="image" src="https://github.com/user-attachments/assets/6e0d0f15-9cd2-4f67-8518-0fff1ebdf24c" />

**Type resolution & type checking**

Creates all unique variable types  
Tracks declared symbols and scope 

AST type tagging:  
<img width="666" height="614" alt="image" src="https://github.com/user-attachments/assets/000883a5-1652-4bc8-9990-08337beae331" />  

**Code generation:**

Multi-target code generation  
LLVM IR Generation:  
<img width="1529" height="704" alt="image" src="https://github.com/user-attachments/assets/a1a700f4-e0ae-475f-8f55-a0ffc6598753" />

**Code Generation Targets**

Currently supported / in progress:

Target Status:
- C - Work in progress
- Go - ✅ Full pipeline — builds and runs executable
- LLVM IR - Work in progress

**Detailed error messages:**

When missing a semicolon:  
<img width="742" height="321" alt="image" src="https://github.com/user-attachments/assets/b23500d4-0065-4c9e-9f95-c43927c1bfe1" />



**Project Goals**

- Build a real compiler pipeline from scratch
- Provide educational material for language design
- Serve as a strong portfolio project demonstrating:
    - Systems programming
    - Compiler engineering
    - Language implementation

**Disclaimer**

C- is an educational and experimental project.
It is not intended for production use.

**YouTube Series**

This project is accompanied by a tutorial series covering:

- Tokenization
- Parsing
- AST construction
- Type checking
- Code generation
- Multi-target compilation

