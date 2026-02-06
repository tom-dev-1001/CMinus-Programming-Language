C- Language Project — Compiler & Language Design Experiment

C- is an experimental programming language and compiler project built to explore how modern programming languages are designed and implemented from scratch.
The goal of this project is not to create a production-ready language, but to:

-Learn the full compiler pipeline in practice
-Build a real language implementation
-Teach others through a YouTube tutorial series
-Showcase compiler engineering and systems programming skills

This project demonstrates the complete workflow of language creation, from source code parsing to executable generation.

Key Features
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

Compiler Pipeline

The project implements a complete compiler frontend and multiple backends:

Tokenizer / Lexer

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

Parser → Abstract Syntax Tree (AST) generation

Type resolution & type checking

AST type tagging

Intermediate code representation

Multi-target code generation





<img width="917" height="524" alt="image" src="https://github.com/user-attachments/assets/6e0d0f15-9cd2-4f67-8518-0fff1ebdf24c" />

<img width="666" height="614" alt="image" src="https://github.com/user-attachments/assets/000883a5-1652-4bc8-9990-08337beae331" />

<img width="1529" height="704" alt="image" src="https://github.com/user-attachments/assets/a1a700f4-e0ae-475f-8f55-a0ffc6598753" />
