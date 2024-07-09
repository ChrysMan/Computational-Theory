%{
	#include <assert.h>
	#include <stdio.h>
   	#include <string.h>
   	#include "myanalyzer.tab.h"
   	#include "cgen.h"
   	
   	int line_num = 1;
%}

ID 			[a-zA-Z_][a-zA-Z0-9_]*

CONST_INT		"0"|[1-9][0-9]*
/*[+|-]?([0-9]+\.?|[0-9]*\.[0-9]+)*/
/*CONST_REAL		({CONST_INT}"."[0-9]*([eE][\+\-]?[1-9][0-9]*))?*/
DECIMAL		("0""."{CONST_INT})|({CONST_INT}("."{CONST_INT}?)?)
CONST_REAL		{DECIMAL}([eE][-+]?{CONST_INT})?
ESCAPE_CHARS		("\n"|\t|\r|\\|\")
SYMBOLS		[ -+/:_$%!#@&~^,.]*
/*CONST_STRINGS		\"({SYMBOLS}|{ESCAPE_CHARS}|[a-zA-Z0-9])*\" */
CONST_STRINGS 		\"[^'\n]*\"	
%%

"--"[^\n]*   		 /*Eat all line comments*/

void			{ printf("token KW_VOID: %s\n", yytext); return KW_VOID;}
integer		{ printf("token KW_INTEGER: %s\n", yytext); return KW_INTEGER;}
scalar			{ printf("token KW_SCALAR: %s\n", yytext); return KW_SCALAR;}
str			{ printf("token KW_STR: %s\n", yytext); return KW_STR;}
boolean		{ printf("token KW_BOOLEAN: %s\n", yytext); return KW_BOOLEAN;}
True			{ printf("token KW_TRUE: %s\n", yytext); return KW_TRUE;} 
False			{ printf("token KW_FALSE: %s\n", yytext); return KW_FALSE;}
const			{ printf("token KW_CONST: %s\n", yytext); return KW_CONST;}
if			{ printf("token KW_IF: %s\n", yytext); return KW_IF;}
else			{ printf("token KW_ELSE: %s\n", yytext); return KW_ELSE;}
endif			{ printf("token KW_ENDIF: %s\n", yytext); return KW_ENDIF;}
for			{ printf("token KW_FOR: %s\n", yytext); return KW_FOR;}
in			{ printf("token KW_IN: %s\n", yytext); return KW_IN;}
endfor			{ printf("token KW_ENDFOR: %s\n", yytext); return KW_ENDFOR;}
while			{ printf("token KW_WHILE: %s\n", yytext); return KW_WHILE;}
endwhile		{ printf("token KW_ENDWHILE: %s\n", yytext); return KW_ENDWHILE;} 
break			{ printf("token KW_BREAK: %s\n", yytext); return KW_BREAK;}
continue		{ printf("token KW_CONTINUE: %s\n", yytext); return KW_CONTINUE;}
not			{ printf("token KW_NOT: %s\n", yytext); return KW_NOT;}
and			{ printf("token KW_AND: %s\n", yytext); return KW_AND;}
or			{ printf("token KW_OR: %s\n", yytext); return KW_OR;}
def			{ printf("token KW_DEF: %s\n", yytext); return KW_DEF;}
enddef			{ printf("token KW_ENDDEF: %s\n", yytext); return KW_ENDDEF;} 
main			{ printf("token KW_MAIN: %s\n", yytext); return KW_MAIN;}
return			{ printf("token KW_RETURN: %s\n", yytext); return KW_RETURN;}
comp			{ printf("token KW_COMP: %s\n", yytext); return KW_COMP;}
endcomp		{ printf("token KW_ENDCOMP: %s\n", yytext); return KW_ENDCOMP;}
of			{ printf("token KW_OF: %s\n", yytext); return KW_OF;}

{ID}			{ yylval.str = strdup(yytext);printf("token IDENTIFIER: %s\n", yytext); return IDENTIFIER;}
{CONST_INT}		{ yylval.str = strdup(yytext);printf("token INT_NUM: %s\n", yytext); return INTEGER;}
{CONST_REAL}		{ yylval.str = strdup(yytext);printf("token REAL_NUM: %s\n", yytext); return REAL_NUM;}
{CONST_STRINGS}	{ yylval.str = strdup(yytext);printf("token CONSTANT_STRINGS: %s\n", yytext); return CONSTANT_STRINGS;}

"=="			{ printf("token OP_EQUAL: %s\n", yytext); return OP_EQUAL;} 
"!="			{ printf("token OP_NOTEQUAL: %s\n", yytext); return OP_NOTEQUAL;}
"<="			{ printf("token OP_LESS_EQUAL: %s\n", yytext); return OP_LESS_EQUAL;}
">="			{ printf("token OP_GREATER_EQUAL: %s\n", yytext); return OP_GREATER_EQUAL;}
"<"			{ printf("token OP_SMALLER: %s\n", yytext); return '<';} 
">"			{ printf("token OP_BIGGER: %s\n", yytext); return '>';}

"+="			{ printf("token OP_PLUS_ASSIGN: %s\n", yytext); return OP_PLUS_ASSIGN;}
"-="			{ printf("token OP_MINUS_ASSIGN: %s\n", yytext); return OP_MINUS_ASSIGN;}
"*="			{ printf("token OP_MUL_ASSIGN: %s\n", yytext); return OP_MUL_ASSIGN;}
"/="			{ printf("token OP_BACKSLASH_ASSIGN: %s\n", yytext); return OP_BACKSLASH_ASSIGN;}
"%="			{ printf("token OP_MODULO_ASSIGN: %s\n", yytext); return OP_MODULO_ASSIGN;}
":="			{ printf("token OP_COLON_ASSIGN: %s\n", yytext); return OP_COLON_ASSIGN;}

"="			{ printf("token OP_ASSIGN: %s\n", yytext); return OP_ASSIGN;}
"+"			{ printf("token OP_PLUS: %s\n", yytext); return '+';} 
"-"			{ printf("token OP_MINUS: %s\n", yytext); return '-';} 
"**"			{ printf("token OP_POW: %s\n", yytext); return OP_POW;} 
"*"			{ printf("token OP_MULT: %s\n", yytext); return '*';} 
"/"			{ printf("token OP_BACKSLASH: %s\n", yytext); return '/';} 
"%"			{ printf("token OP_MODULO: %s\n", yytext); return '%';} 
"#"			{printf("token OP_HASHTAG: %s\n", yytext); return '#';}

";"			{ printf("token DEL_SEMICOLON: %s\n", yytext); return ';';}
"("			{ printf("token DEL_LEFTPARENTHESIS: %s\n", yytext); return '(';}
")"			{ printf("token DEL_RIGHTPARENTHESIS: %s\n", yytext); return ')';}
","			{ printf("token DEL_COMMA: %s\n", yytext); return ',';}
"["			{ printf("token DEL_LEFTBRACKET: %s\n", yytext); return '[';}
"]"			{ printf("token DEL_RIGHTBRACKET: %s\n", yytext); return ']';}
":"			{ printf("token DEL_COLON: %s\n", yytext); return ':';}
"."			{ printf("token DEL_PERIOD: %s\n", yytext); return '.';}


[ \r\t]		/* skip whitespace */
\n			++line_num; /*skip line feed*/
 <<EOF>>		return EOF;
. 			{ yyerror("Lexical error in line %d: unrecognized literaL '%s'\n", line_num, yytext); }

%%



