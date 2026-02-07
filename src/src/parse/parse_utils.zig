


const enums_mod = @import("../core/enums.zig");
const constants_mod = @import("../core/language_constants.zig");
const printing_mod = @import("../core/printing.zig");
const TokenType = enums_mod.TokenType;
const twoSlicesAreTheSame = printing_mod.twoSlicesAreTheSame;

pub fn getTokenType(input:[]const u8) TokenType {
    // Keywords
    if (twoSlicesAreTheSame(input, constants_mod.FN)) return TokenType.Fn;
    if (twoSlicesAreTheSame(input, constants_mod.IF)) return TokenType.If;
    if (twoSlicesAreTheSame(input, constants_mod.ELSE)) return TokenType.Else;
    if (twoSlicesAreTheSame(input, constants_mod.FOR)) return TokenType.For;
    if (twoSlicesAreTheSame(input, constants_mod.WHILE)) return TokenType.While;
    if (twoSlicesAreTheSame(input, constants_mod.RETURN)) return TokenType.Return;
    if (twoSlicesAreTheSame(input, constants_mod.BREAK)) return TokenType.Break;
    if (twoSlicesAreTheSame(input, constants_mod.CONTINUE)) return TokenType.Continue;
    if (twoSlicesAreTheSame(input, constants_mod.PRINT)) return TokenType.Print;
    if (twoSlicesAreTheSame(input, constants_mod.PRINTLN)) return TokenType.Println;
    if (twoSlicesAreTheSame(input, constants_mod.TRUE)) return TokenType.True;
    if (twoSlicesAreTheSame(input, constants_mod.FALSE)) return TokenType.False;
    if (twoSlicesAreTheSame(input, constants_mod.IN)) return TokenType.In;
    if (twoSlicesAreTheSame(input, constants_mod.DEFER)) return TokenType.Defer;
    if (twoSlicesAreTheSame(input, constants_mod.NEW)) return TokenType.New;

    // Types
    if (twoSlicesAreTheSame(input, constants_mod.U8)) return TokenType.u8;
    if (twoSlicesAreTheSame(input, constants_mod.I8)) return TokenType.i8;
    if (twoSlicesAreTheSame(input, constants_mod.I32)) return TokenType.i32;
    if (twoSlicesAreTheSame(input, constants_mod.F32)) return TokenType.f32;
    if (twoSlicesAreTheSame(input, constants_mod.F64)) return TokenType.f64;
    if (twoSlicesAreTheSame(input, constants_mod.I64)) return TokenType.i64;
    if (twoSlicesAreTheSame(input, constants_mod.U64)) return TokenType.u64;
    if (twoSlicesAreTheSame(input, constants_mod.STRING)) return TokenType.String;
    if (twoSlicesAreTheSame(input, constants_mod.BOOL)) return TokenType.Bool;
    if (twoSlicesAreTheSame(input, constants_mod.CHAR)) return TokenType.Char;
    if (twoSlicesAreTheSame(input, constants_mod.VOID)) return TokenType.Void;
    if (twoSlicesAreTheSame(input, constants_mod.CONST)) return TokenType.Const;
    if (twoSlicesAreTheSame(input, constants_mod.INT)) return TokenType.i32;
    if (twoSlicesAreTheSame(input, constants_mod.USIZE)) return TokenType.Usize;
    if (twoSlicesAreTheSame(input, constants_mod.STRUCT)) return TokenType.Struct;

    // Operators
    if (twoSlicesAreTheSame(input, constants_mod.PLUS_PLUS)) return TokenType.PlusPlus;
    if (twoSlicesAreTheSame(input, constants_mod.PLUS)) return TokenType.Plus;
    if (twoSlicesAreTheSame(input, constants_mod.MINUS)) return TokenType.Minus;
    if (twoSlicesAreTheSame(input, constants_mod.MULTIPLY)) return TokenType.Multiply;
    if (twoSlicesAreTheSame(input, constants_mod.DIVIDE)) return TokenType.Divide;
    if (twoSlicesAreTheSame(input, constants_mod.EQUALS)) return TokenType.Equals;
    if (twoSlicesAreTheSame(input, constants_mod.PLUS_EQUALS)) return TokenType.PlusEquals;
    if (twoSlicesAreTheSame(input, constants_mod.MINUS_EQUALS)) return TokenType.MinusEquals;
    if (twoSlicesAreTheSame(input, constants_mod.MULTIPLY_EQUALS)) return TokenType.MultiplyEquals;
    if (twoSlicesAreTheSame(input, constants_mod.DIVIDE_EQUALS)) return TokenType.DivideEquals;
    if (twoSlicesAreTheSame(input, constants_mod.GREATER_THAN)) return TokenType.GreaterThan;
    if (twoSlicesAreTheSame(input, constants_mod.LESS_THAN)) return TokenType.LessThan;
    if (twoSlicesAreTheSame(input, constants_mod.EQUALS_EQUALS)) return TokenType.EqualsEquals;
    if (twoSlicesAreTheSame(input, constants_mod.GREATER_THAN_EQUALS)) return TokenType.GreaterThanEquals;
    if (twoSlicesAreTheSame(input, constants_mod.LESS_THAN_EQUALS)) return TokenType.LessThanEquals;
    if (twoSlicesAreTheSame(input, constants_mod.MODULUS)) return TokenType.Modulus;
    if (twoSlicesAreTheSame(input, constants_mod.NOT_EQUALS)) return TokenType.NotEquals;
    if (twoSlicesAreTheSame(input, constants_mod.AND)) return TokenType.And;
    if (twoSlicesAreTheSame(input, constants_mod.AND_AND)) return TokenType.AndAnd;
    if (twoSlicesAreTheSame(input, constants_mod.OR)) return TokenType.Or;
    if (twoSlicesAreTheSame(input, constants_mod.OR_OR)) return TokenType.OrOr;
    if (twoSlicesAreTheSame(input, constants_mod.MODULUS_EQUALS)) return TokenType.ModulusEquals;

    if (twoSlicesAreTheSame(input, constants_mod.COMMENT)) return TokenType.Comment;
    if (twoSlicesAreTheSame(input, constants_mod.DELETE)) return TokenType.Delete;

    // Parentheses and Brackets
    if (twoSlicesAreTheSame(input, constants_mod.LEFT_PARENTHESIS)) return TokenType.LeftParenthesis;
    if (twoSlicesAreTheSame(input, constants_mod.RIGHT_PARENTHESIS)) return TokenType.RightParenthesis;
    if (twoSlicesAreTheSame(input, constants_mod.LEFT_BRACE)) return TokenType.LeftBrace;
    if (twoSlicesAreTheSame(input, constants_mod.RIGHT_BRACE)) return TokenType.RightBrace;
    if (twoSlicesAreTheSame(input, constants_mod.LEFT_SQUARE_BRACKET)) return TokenType.LeftSquareBracket;
    if (twoSlicesAreTheSame(input, constants_mod.RIGHT_SQUARE_BRACKET)) return TokenType.RightSquareBracket;

    if (twoSlicesAreTheSame(input, constants_mod.SEMICOLON)) return TokenType.Semicolon;
    if (twoSlicesAreTheSame(input, constants_mod.COMMA)) return TokenType.Comma;
    if (twoSlicesAreTheSame(input, constants_mod.FULL_STOP)) return TokenType.FullStop;

    if (twoSlicesAreTheSame(input, constants_mod.COLON)) return TokenType.Colon;
    if (twoSlicesAreTheSame(input, constants_mod.CASE)) return TokenType.Case;
    if (twoSlicesAreTheSame(input, constants_mod.DEFAULT)) return TokenType.Default;
    if (twoSlicesAreTheSame(input, constants_mod.SWITCH)) return TokenType.Switch;
    if (twoSlicesAreTheSame(input, constants_mod.ENUM)) return TokenType.Enum;
    if (twoSlicesAreTheSame(input, constants_mod.PRINTF)) return TokenType.Printf;

    // Number literals
    if (isInteger(input)) return TokenType.IntegerValue;
    if (isDecimal(input)) return TokenType.DecimalValue;

    // String or Char value
    if (printing_mod.contains(input, '"')) return TokenType.StringValue;
    if (printing_mod.contains(input, '\'')) return TokenType.CharValue;

    return TokenType.Identifier;
}

pub fn isOperator(char:u8) bool {

    const LENGTH:usize = constants_mod.OPERATORS.len;
    for (0..LENGTH) |i| {

        if (char == constants_mod.OPERATORS[i]) {
            return true;
        }
    }
    return false;
}

pub fn isSeparator(char:u8) bool {

    const LENGTH:usize = constants_mod.SEPERATORS.len;
    for (0..LENGTH) |i| {

        if (char == constants_mod.SEPERATORS[i]) {
            return true;
        }
    }
    return false;
}

pub fn isInteger(input:[]const u8) bool {
    const LENGTH:usize = input.len;

    for (0..LENGTH) |i| {
        
        const char:u8 = input[i];
        if (input[i] == '-') {
            if (i != 0 ) {
                return false;
            }
            continue;
        }   
        if (isDigit(char) == false) {
            return false;
        }
    }
    return true;
}

pub fn isDecimal(input:[]const u8) bool {
    const LENGTH:usize = input.len;

    for (0..LENGTH) |i| {
        
        const char:u8 = input[i];
        if (input[i] == '-') {
            if (i != 0 ) {
                return false;
            }
            continue;
        }   
        if (input[i] == '.') {
            continue;
        }
        if (isDigit(char) == false) {
            return false;
        }
    }
    return true;
}

pub fn isLetterOrDigit(char: u8) bool {
    switch (char) {
        'a'...'z', 'A'...'Z', '0'...'9' => return true,
        else => return false,
    }
}

pub fn isDigit(char: u8) bool {
    switch (char) {
        '0'...'9' => return true,
        else => return false,
    }
}