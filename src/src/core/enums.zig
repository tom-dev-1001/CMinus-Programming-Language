
pub const TokenType = enum {
    Fn,
    IntegerValue, 
    DecimalValue, 
    CharValue, 
    StringValue,  
    i8,
    u8,
    i16,
    u16,
    Int,
    i32,
    u32,
    i64,
    u64,
    f32,
    f64,
    Usize,
    String,
    Bool,
    Char,
    Void,
    If,
    Else,
    For,
    While,
    Minus,
    Plus,
    PlusPlus,
    Divide,
    Multiply,
    Equals,
    Identifier,
    Return,
    Break,
    Continue,
    Print,
    Println,
    Printf,
    LeftParenthesis,
    RightParenthesis,
    LeftBrace,
    RightBrace,
    LeftSquareBracket,
    RightSquareBracket,
    Semicolon,
    True,
    False,
    Comment,
    EndComment,
    Comma,
    FullStop,
    PlusEquals,
    MinusEquals,
    MultiplyEquals,
    DivideEquals,
    GreaterThan,
    LessThan,
    EqualsEquals,
    GreaterThanEquals,
    LessThanEquals,
    VariableInSimpleForLoop,
    Defer,
    New,
    Delete,
    In,
    Const,
    Modulus,
    ModulusEquals,
    NotEquals,
    And,
    AndAnd,
    Or,
    OrOr,
    IntegerVarType,
    Case,
    Default,
    Colon,
    Switch,
    Struct,
    Enum,
    NA, //invalid type
};

pub const ASTNodeType = enum {
    Invalid,
    Comment,

    //Keywords
    Return,
    Break,
    Continue,
    Print,
    Println,
    PrintF,

    //Literals
    IntegerLiteral,
    FloatLiteral,
    StringLiteral,
    CharLiteral,
    BoolLiteral,

    //__Operators__
    Minus,
    Reference,
    DereferenceAssignment,

    //__Bodies__
    FunctionBody,
    ForBody,
    ElseBody,
    IfBody,
    WhileBody,

    //__declarations__
    ArrayDeclaration,
    PointerDeclaration,
    FunctionDeclaration,
    Declaration,

    //__Functions__
    FunctionCall,

    //arrays
    ArrayGroup, //for multidimensional arrays
    ArrayElement,
    ArrayAccess,
    ArrayIndexReassignment,
    Array,

    //__Expressions__
    PrintExpression,
    BinaryExpression,
    ReturnExpression,
    BoolExpression,
    BoolComparison,

    //__Vartypes__
    VarType,
    Pointer,
    ReturnType,
    Const,
    Parameter,
    Parameters,

    //__Struct__
    StructDeclaration,
    StructMember,
    StructMembers,
    StructMemberAccess,
    StructMemberAssignment,

    //__enum__
    EnumDeclaration,
    EnumMember,
    EnumMembers,

    //__Block things__
    IfStatement,
    WhileLoop,
    ForLoop,
    ForCondition,
    Else,
    SwitchStatement,
    SwitchCondition,
    SwitchBody,
    SwitchCase,
    SwitchDefault,
    CaseBlock,

    //__General__
    Identifier,
    FullStop,
    Assignment,
};

pub const LoopResult = enum {
    None,
    Continue,
    Break,
    ReturnNull,
};

pub const LanguageTarget = enum {
    LLVM,
    Go,
    C,
};

pub const SwitchPhase = enum {
    Case,
    Body,
};

pub const StructMemberPhase = enum {
    Type,
    Name,
    Semicolon,
};

pub const TypeTag = enum {
    None,
    Void,
    Int32,
    Int64,
    F32,
    F64,
    Bool,
    Char,
    String,

    Pointer,
    Array,
    Struct,
    Enum,
    Function,
};

pub const SymbolTag = enum {
    None,
    GlobalVar,
    LocalVar,
    Parameter,
    Function,
    Struct,
    Enum,
    Literal,
};

pub const OperatorType = enum {
    Plus,
    PlusEquals,
    Minus,
    MinusEquals,
    Multiply,
    MultiplyEquals,
    Divide,
    DivideEquals,
    And,
    AndEquals,
    Or,
    OrEquals,
    NotEquals,
    GreaterThan,
    GreaterThanEquals,
    LessThan,
    LessThanEquals,
    EqualsEquals,
};

pub const CodeSection = enum {
    Parsing_Strings,
    Parsing_Separator,
    Parsing_Char,
    Parsing_Word,
    Ast_Arrays, //5

    Ast_Bools,
    Ast_Enums,
    Ast_Floats,
    Ast_For,
    Ast_Function, //10

    Ast_If,
    Ast_Integers,
    Ast_Pointers,
    Ast_Print,
    Ast_Return,//15

    Ast_Strings,
    Ast_Structs,
    Ast_Switch,
    Ast_Utils,
    Ast_Variables, //20

    Ast_Main,
    Analysis_Phase1_Globals,
    Analysis_Phase1_Primitives,
    Analysis_Phase1_Structs,
    Analysis_Phase1_Enums, //25

    Analysis_Phase1_Functions,
    Analysis_Phase2_Scopes,
    Analysis_Phase2_Declarations,
    Analysis_Phase2_Expressions,
    Analysis_Phase2_Conditions,//30

    Analysis_Phase2_Identifiers,
    Analysis_Phase2_Parameters,
    Analysis_Phase2_FunctionCalls,
    Converting_LLVM_Body,
    Converting_LLVM_Convert,//35

    Converting_LLVM_Declarations,
    Converting_LLVM_Flatten,
    Converting_LLVM_Functions,
    Converting_LLVM_Return,
    Converting_LLVM_Utils, //40

    Converting_LLVM_Expressions,
};

//struct ReturnAST
//
//ValueNode value

//struct DeclarationAST
//
//VarType type
//