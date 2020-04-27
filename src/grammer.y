/*
    This file is a part of Tiny-Shading-Language or TSL, an open-source cross
    platform programming shading language.

    Copyright (c) 2020-2020 by Jiayin Cao - All rights reserved.

    TSL is a free software written for educational purpose. Anyone can distribute
    or modify it under the the terms of the GNU General Public License Version 3 as
    published by the Free Software Foundation. However, there is NO warranty that
    all components are functional in a perfect manner. Without even the implied
    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License along with
    this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.html>.
 */

%{
/*
    --------------------------------------------------------------------
    WARNING:
            This file is automatically generated, do not modify.
    --------------------------------------------------------------------
*/
	#include <string>
	#include "include/tslversion.h"
	#include "compiler/ast.h"
	#include "compiler/compiler_impl.h"

	USE_TSL_NAMESPACE

	#define scanner tsl_compiler->getScanner()

	int yylex( union YYSTYPE *,struct YYLTYPE *,void * );
    void yyerror(struct YYLTYPE* loc, void *tsl_compiler, char const *str);
	int g_verbose = 0;	// somehow bool is not working here.
%}

/* definitions of tokens and types passed by FLEX */
%union {
    class AstNode 				*p;	/* pointers for the AST struct nodes */
	float						 f; /* floating point value cache. */
	int							 i; /* integer value or enum values. */
	const char					*s;	/* string values. */
	char						 c; /* single char. */
}

%locations
%define api.pure
%lex-param {void * scanner}
%parse-param {class Tsl_Namespace::TslCompiler_Impl * tsl_compiler}

%token <s> ID
%token <i> INT_NUM
%token <f> FLT_NUM
%token INC_OP			"++"
%token DEC_OP			"--"
%token SHADER_FUNC_ID
%token <i> TYPE_INT	    "int"
%token <i> TYPE_FLOAT	"float"
%token <i> TYPE_MATRIX  "matrix"
%token <i> TYPE_FLOAT3  "float3"
%token <i> TYPE_BOOL	"bool"
%token TYPE_VOID		"void"
%token EOL              ";"
%token L_CBRACKET       "{"
%token R_CBRACKET       "}"
%token L_RBRACKET       "("
%token R_RBRACKET       ")"
%token L_SBRACKET       "["
%token R_SBRACKET       "]"
%token OP_ADD           "+"
%token OP_MINUS         "-"
%token OP_MULT          "*"
%token OP_DIV           "/"
%token OP_MOD			"%"
%token OP_AND			"&"
%token OP_OR			"|"
%token OP_XOR			"^"
%token OP_LOGIC_AND     "&&"
%token OP_LOGIC_OR		"||"
%token OP_EQ			"=="
%token OP_NE			"!="
%token OP_GE			">="
%token OP_G				">"
%token OP_LE			"<="
%token OP_L				"<"
%token OP_SHL			"<<"
%token OP_SHR			">>"
%token OP_ADD_ASSIGN    "+="
%token OP_MINUS_ASSIGN  "-="
%token OP_MULT_ASSIGN   "*="
%token OP_DIV_ASSIGN    "/="
%token OP_MOD_ASSIGN    "%="
%token OP_ASSIGN        "="
%token OP_AND_ASSIGN	"&="
%token OP_OR_ASSIGN		"|="
%token OP_XOR_ASSIGN	"^="
%token OP_SHL_ASSIGN	"<<="
%token OP_SHR_ASSIGN	">>="
%token OP_NOT			"!"
%token OP_COMP			"~"
%token DOT				"."
%token COMMA            ","
%token COLON            ":"
%token METADATA_START   "<<<"
%token METADATA_END     ">>>"
%token RETURN		    "return"
%token QUESTION_MARK	"?"
%token IF				"if"
%token ELSE				"else"
%token FOR				"for"
%token WHILE			"while"
%token DO				"do"

%type <p> PROGRAM FUNCTION_ARGUMENT_DECL FUNCTION_ARGUMENT_DECLS SHADER_FUNCTION_ARGUMENT_DECLS VARIABLE_LVALUE ID_OR_FIELD FUNCTION_ARGUMENTS
%type <p> EXPRESSION_COMPOUND EXPRESSION_CONST EXPRESSION_BINARY EXPRESSION EXPRESSION_VARIABLE EXPRESSION_FUNCTION_CALL EXPRESSION_TERNARY EXPRESSION_COMPOUND_OPT EXPRESSION_SCOPED EXPRESSION_ASSIGN EXPRESSION_UNARY
%type <c> OP_UNARY

%nonassoc IF_THEN
%nonassoc ELSE

%left ","
%right "=" "+=" "-=" "*=" "/=" "%=" "<<=" ">>=" "&=" "|=" "^="
%right "?" ":"
%left "||"
%left "&&"
%left "|"
%left "^"
%left "&"
%left "==" "!="
%left ">" ">=" "<" "<=" 
%left "<<" ">>"
%left "+" "-"
%left "*" "/" "%"
%right UMINUS_PREC "!" "~"
%left "++" "--"
%left "(" ")"
%left "[" "]"
%left "<<<" ">>>"

/* the start token */
%start PROGRAM

%%
// A programm has a bunch of global statement.
PROGRAM:
	// empty shader
	{
        $$ = nullptr;
	}
	|
	GLOBAL_STATEMENTS {
	};

// One or multiple of blobal statements
GLOBAL_STATEMENTS:
	GLOBAL_STATEMENT{
	}
	|
	GLOBAL_STATEMENT GLOBAL_STATEMENTS {
	};

// Global statement could be one of the followings
//  - Global variable decleration.
//  - Global function definition.
//  - Global data structure definition.
//  - Shader function definition.
GLOBAL_STATEMENT:
	STATEMENT_VARIABLES_DECLARATIONS{
	}
	|
    SHADER_DEF {
    }
	|
	FUNCTION_DEF {
	};

// Shader is the only unit that can be exposed in the group.
SHADER_DEF:
	SHADER_FUNC_ID ID "(" SHADER_FUNCTION_ARGUMENT_DECLS ")" FUNCTION_BODY {
		AstNode_Shader *p = new AstNode_Shader($2);
		tsl_compiler->pushRootAst(p);
	};

SHADER_FUNCTION_ARGUMENT_DECLS:
	/* empty */
	{
		$$ = nullptr;
	}
	|
	SHADER_FUNCTION_ARGUMENT_DECL{
	}
	|
	SHADER_FUNCTION_ARGUMENT_DECL "," SHADER_FUNCTION_ARGUMENT_DECLS {
	};

SHADER_FUNCTION_ARGUMENT_DECL:
	FUNCTION_ARGUMENT_DECL ARGUMENT_METADATA {
	};

ARGUMENT_METADATA:
	// no meta data
	{}
	|
	"<<<" ">>>"{
	};

// Standard function definition
FUNCTION_DEF:
	TYPE ID "(" FUNCTION_ARGUMENT_DECLS ")" FUNCTION_BODY {
		const AstNode* variables = $4;
		AstNode* root = new AstNode_Function($2, AstNode::castType<AstNode_VariableRef>(variables));
		tsl_compiler->pushRootAst(root);
	};

FUNCTION_ARGUMENT_DECLS:
	/* empty */
	{
		$$ = nullptr;
	}
	|
	FUNCTION_ARGUMENT_DECL
	{
		$$ = $1;
	}
	|
	FUNCTION_ARGUMENT_DECL "," FUNCTION_ARGUMENT_DECLS{
		AstNode* node_arg = $1;
		AstNode* node_args = $3;
		$$ = node_arg->append( node_args );
	};

FUNCTION_ARGUMENT_DECL:
	TYPE ID {
		AstNode_VariableRef* node = new AstNode_VariableRef($2);
		$$ = node;
	}
	|
	TYPE ID "=" EXPRESSION {
		AstNode_VariableRef* node = new AstNode_VariableRef($2);
		$$ = node;
	};

FUNCTION_BODY:
	"{" STATEMENTS "}" {
	};

STATEMENTS:
	STATEMENT STATEMENTS {}
	|
	/* empty */ {};

STATEMENT:
	STATEMENT_SCOPED{
	}
	|
	STATEMENT_RETURN{
	}
	|
	STATEMENT_VARIABLES_DECLARATIONS {
	}
	|
	STATEMENT_CONDITIONAL {
	}
	|
	STATEMENT_LOOP {
	}
	|
	STATEMENT_COMPOUND_EXPRESSION {
	};

STATEMENT_SCOPED:
	"{" 
		{ /* push a new scope here */ }
	STATEMENTS "}"
		{ /* pop the scope from here */ }
	;

STATEMENT_RETURN:
	"return" STATEMENT_EXPRESSION_OPT ";"
	{
	};

STATEMENT_EXPRESSION_OPT:
	EXPRESSION_COMPOUND {
	}
	|
	/* empty */ {
	};

STATEMENT_VARIABLES_DECLARATIONS:
	TYPE VARIABLE_DECLARATIONS ";" {
	};

VARIABLE_DECLARATIONS:
	VARIABLE_DECLARATION {
	}
	|
	VARIABLE_DECLARATION "," VARIABLE_DECLARATIONS {
	};

VARIABLE_DECLARATION:
	ID {
	}
	|
	ID "=" EXPRESSION {
	};

STATEMENT_CONDITIONAL:
	"if" "(" EXPRESSION_COMPOUND ")" STATEMENT %prec IF_THEN {
	}
	|
	"if" "(" EXPRESSION_COMPOUND ")" STATEMENT "else" STATEMENT {
	};
	
STATEMENT_LOOP:
	"while" "(" EXPRESSION_COMPOUND ")" STATEMENT{
	}
	|
	"do" STATEMENT "while" "(" EXPRESSION_COMPOUND ")" ";"{
	}
	|
	"for" "(" FOR_INIT_STATEMENT EXPRESSION_COMPOUND_OPT ";" EXPRESSION_COMPOUND_OPT ")" STATEMENT {
	};
	
FOR_INIT_STATEMENT:
	";"{
	}
	|
	EXPRESSION_COMPOUND ";"{
	}
	|
	STATEMENT_VARIABLES_DECLARATIONS {
	};
	
STATEMENT_COMPOUND_EXPRESSION:
	EXPRESSION_COMPOUND ";" {
	}

EXPRESSION_COMPOUND_OPT:
	/* empty */ 
	{
		$$ = nullptr;
	}
	|
	EXPRESSION_COMPOUND;

EXPRESSION_COMPOUND:
	EXPRESSION
	| 
	EXPRESSION "," EXPRESSION_COMPOUND {
		AstNode* exp = $1;
		AstNode* extra_exp = $3;
		$$ = exp->append( extra_exp );
	};

// Exrpession always carries a value so that it can be used as input for anything needs a value,
// like if condition, function parameter, etc.
EXPRESSION:
	EXPRESSION_UNARY
	|
	EXPRESSION_BINARY
	|
	EXPRESSION_TERNARY
	|
	EXPRESSION_ASSIGN
	|
	EXPRESSION_FUNCTION_CALL
	|
	EXPRESSION_CONST
	|
	EXPRESSION_SCOPED
	|
	EXPRESSION_TYPECAST {
	}
	|
	EXPRESSION_VARIABLE {
	};

EXPRESSION_UNARY:
	OP_UNARY EXPRESSION %prec UMINUS_PREC {
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($2);
		switch( $1 ){
			case '+':
				$$ = new AstNode_Unary_Pos(exp);	// it is still necessary to wrap something here to prevent this value from being a lvalue later.
				break;
			case '-':
				$$ = new AstNode_Unary_Neg(exp);
				break;
			case '!':
				$$ = new AstNode_Unary_Not(exp);
				break;
			case '~':
				$$ = new AstNode_Unary_Compl(exp);
				break;
			default:
				$$ = nullptr;
		}
	};
	
OP_UNARY:
	"-" {
		$$ = '-';
	}
	|
	"+" {
		$$ = '+';
	}
	|
	"!" {
		$$ = '!';
	}
	|
	"~" {
		$$ = '~';
	};

EXPRESSION_BINARY:
	EXPRESSION "&&" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_And( left , right );
	}
	|
	EXPRESSION "||" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Or( left , right );
	}
	|
	EXPRESSION "&" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Bit_And( left , right );
	}
	|
	EXPRESSION "|" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Bit_Or( left , right );
	}
	|
	EXPRESSION "^" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Bit_Xor( left , right );
	}
	|
	EXPRESSION "==" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Eq( left , right );
	}
	|
	EXPRESSION "!=" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Ne( left , right );
	}
	|
	EXPRESSION ">" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_G( left , right );
	}
	|
	EXPRESSION "<" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_L( left , right );
	}
	|
	EXPRESSION ">=" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Ge( left , right );
	}
	|
	EXPRESSION "<=" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Le( left , right );
	}
	|
	EXPRESSION "<<" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Shl( left , right );
	}
	|
	EXPRESSION ">>" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Shr( left , right );
	}
	|
	EXPRESSION "+" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Add( left , right );
	}
	|
	EXPRESSION "-" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Minus( left , right );
	}
	|
	EXPRESSION "*" EXPRESSION {
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Multi( left , right );
	}
	|
	EXPRESSION "/" EXPRESSION{
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Div( left , right );
	}
	|
	EXPRESSION "%" EXPRESSION{
		AstNode_Expression* left = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* right = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_Binary_Mod( left , right );
	};

// Ternary operation support
EXPRESSION_TERNARY:
	EXPRESSION "?" EXPRESSION ":" EXPRESSION {
		AstNode_Expression* cond = AstNode::castType<AstNode_Expression>($1);
		AstNode_Expression* true_expr = AstNode::castType<AstNode_Expression>($3);
		AstNode_Expression* false_expr = AstNode::castType<AstNode_Expression>($5);
		$$ = new AstNode_Ternary( cond , true_expr , false_expr );
	};

// Assign an expression to a reference
EXPRESSION_ASSIGN:
	VARIABLE_LVALUE "=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode* p = $3;
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_Eq( var , exp );
	}
	|
	VARIABLE_LVALUE "+=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_AddEq( var , exp );
	}
	|
	VARIABLE_LVALUE "-=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_MinusEq( var , exp );
	}
	|
	VARIABLE_LVALUE "*=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_MultiEq( var , exp );
	}
	|
	VARIABLE_LVALUE "/=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_DivEq( var , exp );
	}
	|
	VARIABLE_LVALUE "%=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_ModEq( var , exp );
	}
	|
	VARIABLE_LVALUE "&=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_AndEq( var , exp );
	}
	|
	VARIABLE_LVALUE "|=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_OrEq( var , exp );
	}
	|
	VARIABLE_LVALUE "^=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_XorEq( var , exp );
	}
	|
	VARIABLE_LVALUE "<<=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_ShlEq( var , exp );
	}
	|
	VARIABLE_LVALUE ">>=" EXPRESSION {
		AstNode_Lvalue* var = AstNode::castType<AstNode_Lvalue>($1);
		AstNode_Expression* exp = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_ExpAssign_ShrEq( var , exp );
	};

// Function call, this is only non-shader function. TSL doesn't allow calling shader function.
EXPRESSION_FUNCTION_CALL:
	ID "(" FUNCTION_ARGUMENTS ")" {
		AstNode_Expression* args = AstNode::castType<AstNode_Expression>($3);
		$$ = new AstNode_FunctionCall( $1 , args );
	};

// None-shader function arguments
FUNCTION_ARGUMENTS:
	{
		$$ = nullptr;
	}
	|
	EXPRESSION
	|
	FUNCTION_ARGUMENTS "," EXPRESSION {
		AstNode* node_arg = $1;
		AstNode* node_args = $3;
		$$ = node_arg->append( node_args );
	};


// Const literal
EXPRESSION_CONST:
	INT_NUM {
		$$ = new AstNode_Literal_Int( $1 );
	}
	|
	FLT_NUM {
		$$ = new AstNode_Literal_Flt( $1 );
	};

// Scopped expression
EXPRESSION_SCOPED:
	"(" EXPRESSION_COMPOUND ")" {
		$$ = $2;
	};

// This is for type casting
EXPRESSION_TYPECAST:
	"(" TYPE ")" EXPRESSION {
	};

EXPRESSION_VARIABLE:
	VARIABLE_LVALUE{
		
	}
	|
	VARIABLE_LVALUE REC_OR_DEC {
	}
	|
	REC_OR_DEC VARIABLE_LVALUE {
	};

REC_OR_DEC:
	"++" {
	}
	|
	"--" {
	};

// No up to two dimensional array supported for now.
VARIABLE_LVALUE:
	ID_OR_FIELD 
	|
	ID_OR_FIELD "[" EXPRESSION "]" {
	};

ID_OR_FIELD:
	ID{
		$$ = new AstNode_VariableRef($1);
	}
	|
	VARIABLE_LVALUE "." ID {
	};

TYPE:
	"int" {
	}
	|
	"float" {
	}
	|
	"matrix" {
	}
	|
	"float3" {
	}
	|
	"bool" {
	}
	|
	"void" {
	};
%%

void yyerror(struct YYLTYPE* loc, void* x, char const * str){
	if(!g_verbose)
		return;

	// line number is incorrect for now
	printf( "line(%d, %d), error: %s\n", loc->first_line, loc->first_column, str);
}

void makeVerbose(int verbose){
	 g_verbose = verbose;
}
