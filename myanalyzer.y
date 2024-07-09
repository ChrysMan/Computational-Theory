%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "cgen.h"
	
	extern int yylex(void);
	extern int line_num;
	extern int atoi (const char *a);
	int var_value;
	char* deff;
	char* ctor_vars;
	char* str_names;
	char* comp_name;
	int comp_flag;

%}
%union 
{
	char* str;
}

%token <str> IDENTIFIER
%token <str> INTEGER
%token <str> REAL_NUM
%token <str> CONSTANT_STRINGS

//KEYWORD DEFINITION
%token KW_VOID
%token KW_INTEGER
%token KW_SCALAR
%token KW_STR
%token KW_BOOLEAN
%token KW_TRUE
%token KW_FALSE
%token KW_CONST
%token KW_IF
%token KW_ELSE
%token KW_ENDIF
%token KW_FOR
%token KW_IN
%token KW_ENDFOR
%token KW_WHILE
%token KW_ENDWHILE
%token KW_BREAK
%token KW_CONTINUE
%token KW_NOT
%token KW_AND
%token KW_OR
%token KW_DEF
%token KW_ENDDEF
%token KW_MAIN
%token KW_RETURN
%token KW_COMP
%token KW_ENDCOMP
%token KW_OF

%token OP_EQUAL
%token OP_NOTEQUAL
%token OP_LESS_EQUAL
%token OP_GREATER_EQUAL
%token OP_PLUS_ASSIGN
%token OP_MINUS_ASSIGN
%token OP_MUL_ASSIGN
%token OP_BACKSLASH_ASSIGN
%token OP_MODULO_ASSIGN
%token OP_ASSIGN
%token OP_COLON_ASSIGN
%token OP_POW

%right OP_ASSIGN OP_PLUS_ASSIGN OP_MINUS_ASSIGN OP_MUL_ASSIGN OP_BACKSLASH_ASSIGN OP_MODULO_ASSIGN OP_COLON_ASSIGN
%left KW_OR
%left KW_AND
%right KW_NOT
%left '<' '>' OP_LESS_EQUAL OP_GREATER_EQUAL
%left '*' '/' '%'
%right '+' '-'
%right OP_POW
%left '.' '(' ')' '[' ']'

%type <str> prologue
%type <str> declarations
%type <str> assign
%type <str> assign_op
%type <str> statement
%type <str> expr
%type <str> logical_expr
%type <str> arithmetic_expr
%type <str> complex_expr
%type <str> var_types
%type <str> decl_var_sameLine
%type <str> var_ident
%type <str> diff_ident
%type <str> decl_one_comp
%type <str> comp_expr
%type <str> access_comp
%type <str> many_access_comp
%type <str> decl_comp_functions
%type <str> comp_func_arguments
%type <str> comp_func_arguments_line
%type <str> assign_comp_var
%type <str> decl_comp_var_sameLine
%type <str> decl_var
%type <str> decl_var_comp
%type <str> decl_comp_vars
%type <str> decl_comp_var
%type <str> decl_const_var_sameLine
%type <str> decl_const_var
%type <str> decl_function
%type <str> func_command_block
%type <str> statements_command_block
%type <str> return_type
%type <str> var_argument
%type <str> func_arguments
%type <str> call_function
%type <str> call_function2
%type <str> call_function_args
%type <str> if_statement
%type <str> while_statement
%type <str> for_statement

%type <str> program

%start program	
%%	
	program:
// Case where there are declararions before main
		prologue KW_DEF KW_MAIN '(' ')' ':' func_command_block KW_ENDDEF ';'	{	
		str_names = calloc(100,sizeof(char));
		comp_name = calloc(50,sizeof(char));
		comp_flag = 0;
		
		$$ == template("%s", $1);
		
		if(yyerror_count==0){		//Checking for errors
			FILE* cfile = fopen("C_file.c","w");
			fputs(c_prologue,cfile);	// include kappalib.h 
			fprintf(cfile, "%s\n void main(){\n%s\n}",$1,$7);
			fclose(cfile);}
		free(str_names);
	}
// Case where aren't declarations before main
	|	KW_DEF KW_MAIN	'(' ')' ':' func_command_block KW_ENDDEF ';'	      
	{	str_names = calloc(100,sizeof(char));	
		comp_name = calloc(50,sizeof(char));
		comp_flag = 0;
		if(yyerror_count==0){		//Checking for errors
			FILE* cfile = fopen("C_file.c","w");
			fputs(c_prologue,cfile);	// include kappalib.h
			fprintf(cfile, "void main(){\n%s\n}",$6);
			fclose(cfile);}
		free(str_names);
	}
	;
	declarations:
		decl_one_comp                 {$$=template("%s",$1);}   
	|   	decl_const_var                {$$=template("%s",$1);}
	|   	decl_var                      {$$=template("%s",$1);}
	|   	decl_function                 {$$=template("%s",$1);}
	;
	
	prologue:
	   	prologue declarations 		{$$=template("%s\n%s\n",$1,$2);}
	| 	declarations			{$$=template("%s\n",$1);}   
	;
	
	assign_op:
		OP_PLUS_ASSIGN		{$$=template("+=");}
	|	OP_MINUS_ASSIGN	{$$=template("-=");}
	|	OP_MUL_ASSIGN		{$$=template("*=");}
	|	OP_BACKSLASH_ASSIGN	{$$=template("/=");}
	|	OP_MODULO_ASSIGN	{$$=template("%=");}
	;
	
	
	assign:
		IDENTIFIER OP_ASSIGN expr ';'			{$$=template("%s = %s;", $1,$3);}
	|	IDENTIFIER assign_op expr ';'			{$$=template("%s %s %s;", $1,$2,$3);}
	|	IDENTIFIER '[' expr ']' OP_ASSIGN expr ';'	{$$=template("%s[%s] = %s;", $1,$3,$6); }	
	|	IDENTIFIER '[' expr ']' assign_op expr ';'	{$$=template("%s[%s] %s %s;", $1,$3,$5,$6); }	
	|	IDENTIFIER '['']' OP_ASSIGN expr ';'		{$$=template("%s[] = %s;", $1,$5); }
	|	IDENTIFIER '['']' assign_op expr ';'		{$$=template("%s[] %s %s;", $1,$4,$5); }
	|	IDENTIFIER OP_COLON_ASSIGN '[' expr KW_FOR IDENTIFIER ':' expr ']' ':' var_types ';'
	{$$=template("%s* %s=(%s*)malloc(%s*sizeof(%s));\nfor(int %s=0; %s<%s; ++%s){\n%s[%s]=%s;}",$11,$1,$11,$8,$11,$6,$6,$8,$6,$1,$6,$6);}
	|	IDENTIFIER OP_COLON_ASSIGN '[' expr KW_FOR IDENTIFIER ':' var_types KW_IN IDENTIFIER KW_OF expr ']' ':' var_types ';'
	{ char str[strlen($4)+1], substr[strlen($6)+1], replace[2*strlen($10)+5];
	char* output = malloc(70);
	
	sprintf(str, "%s", $4);
	sprintf(substr, "%s", $6);
	sprintf(replace,"%s[%s_i]", $10,$10);
	char* token = strtok(str,substr);

	sprintf(output,"%s",""); //initialise so we can compare
	
	while(token!=NULL){
		sprintf(output,"%s%s%s", output,replace,token);
		token = strtok(NULL,substr);
	}

	$$ = template("%s* %s = (%s*)malloc(%s* sizeof(%s));\nfor (int %s_i=0; %s_i < %s; ++%s_i){\n%s[%s_i] = %s;\n}", $15, $1, $15, $12, $15, $10, $10, $12, $10, $1, $10, output);
	}
	;
	
	expr:
		logical_expr 	{$$=template("%s",$1);}
	;
	
	complex_expr:
		INTEGER				{$$=template("%s",$1);}
	|	REAL_NUM				{$$=template("%s",$1);}
	|	CONSTANT_STRINGS			{$$=template("%s",$1);}
	|	IDENTIFIER				{$$=template("%s",$1);}
	|	IDENTIFIER '[' expr ']'		{$$=template("%s[(%s)]",$1,$3); }
	|	IDENTIFIER '['']'		{$$=template("%s[]",$1); }
	|	KW_TRUE				{$$=template("1");}
	|	KW_FALSE				{$$=template("0");}
	|	call_function2				{$$=template("%s",$1);}
	|	'(' expr ')'				{$$=template("(%s)",$2);}
	|	comp_expr				{$$=template("%s",$1);} 
	;
	
	arithmetic_expr://------------arithmetic expr---------------------
		complex_expr				{$$=template("%s",$1);}
	|	arithmetic_expr OP_POW complex_expr	{$$=template("pow((double)%s,(double)%s)", $1, $3); }
	|	arithmetic_expr '/' complex_expr	{$$=template("%s / %s", $1, $3); }
	|	arithmetic_expr '*' complex_expr	{$$=template("%s * %s", $1, $3); }
	|	arithmetic_expr '%' complex_expr	{$$=template("((int)%s) % ((int)%s)", $1, $3); }
	|	arithmetic_expr '+' complex_expr	{$$=template("%s + %s", $1, $3); } 
	|	arithmetic_expr '-' complex_expr	{$$=template("%s - %s", $1, $3); }
	|	'+' arithmetic_expr			{$$=template("+%s",$2);} 
	|	'-' arithmetic_expr			{$$=template("-%s",$2);} 
	;
	
	logical_expr:	//-------------logical expr------------------------
		arithmetic_expr				{$$=template("%s",$1);}
	|	logical_expr OP_LESS_EQUAL arithmetic_expr	{$$=template("%s <= %s",$1,$3);}
	|	logical_expr OP_GREATER_EQUAL arithmetic_expr	{$$=template("%s >= %s",$1,$3);}
	|	logical_expr '<' arithmetic_expr		{$$=template("%s < %s",$1,$3);}
	|	logical_expr '>' arithmetic_expr		{$$=template("%s > %s",$1,$3);}
	|	logical_expr OP_EQUAL arithmetic_expr		{$$=template("%s == %s",$1,$3);}
	|	logical_expr OP_NOTEQUAL arithmetic_expr	{$$=template("%s != %s",$1,$3);}
	|	KW_NOT arithmetic_expr				{$$=template("!%s",$2);}
	|	logical_expr KW_AND arithmetic_expr		{$$=template("%s && %s",$1,$3);}
	|	logical_expr KW_OR arithmetic_expr		{$$=template("%s || %s",$1,$3);}
	
	;	
	//=================================variables declaration==========================================================
	var_types:
		KW_INTEGER		{$$=template("int");}
	|	KW_SCALAR		{$$=template("double");}
	|	KW_STR			{$$=template("StringType");}
	|	KW_BOOLEAN		{$$=template("int");}
	| 	'[' ']' KW_INTEGER	{$$=template("int*");}
	| 	'[' ']' KW_SCALAR      {$$=template("double*");}
	| 	'[' ']' KW_STR    	{$$=template("StringType");}
	| 	'[' ']' KW_BOOLEAN     {$$=template("int*");}
	;
	
	var_ident:
		IDENTIFIER '[' expr ']' OP_ASSIGN expr	{$$=template("%s[%s]=%s", $1,$3,$6);}
	|	IDENTIFIER '['']' OP_ASSIGN expr		{$$=template("%s*[]=%s", $1,$5);}
	|	IDENTIFIER OP_ASSIGN expr			{$$=template("%s = %s", $1,$3);}
	|	IDENTIFIER '[' expr ']' 			{$$=template("%s[%s]", $1,$3);}
	|	IDENTIFIER '[' ']' 				{$$=template("%s*[]", $1);}
	|	IDENTIFIER 					{$$=template("%s", $1);}
	;
	
	
	//variables' declaration on the same line
	decl_var_comp:
		decl_var_sameLine ':' IDENTIFIER ';'	
		{char* var_token = strtok(comp_name," ");
		char* ptr=NULL;
		while (var_token!=NULL){
			if (ptr == NULL){
				ptr = template("%s=ctor_%s",var_token,$3);
			}else{
				ptr = template("%s, %s=ctor_%s",ptr,var_token,$3);
			}
			var_token = strtok(NULL," ");
		}
		$$=template("%s %s;\n", $3,ptr);
		free(comp_name);
		}
	;
	
	decl_var:
		decl_var_sameLine ':' var_types';'	{$$=template("%s %s;\n", $3,$1);}
	;
	
	decl_var_sameLine:
		decl_var_sameLine ',' var_ident	
		{comp_name = template("%s %s",comp_name,$3);
		$$=template("%s, %s", $1,$3);}
	|	var_ident				
		{comp_name = calloc(50,sizeof(char));
		comp_name = template("%s",$1);
		$$=template("%s", $1);}
	;
	
	//----------------------------------------Comp variables-------------------------------------
	diff_ident:
		IDENTIFIER 				{$$=template("%s ", $1);}
	|	IDENTIFIER '['']' 			{$$=template("%s[] ", $1); }	
	|	IDENTIFIER '[' expr ']' 		{$$=template("%s[%s] ", $1,$3); }	
	;
	
	comp_expr:
		'#' diff_ident 		{$$=template("self->%s", $2);}
	|	access_comp			{$$=template("%s", $1);}
	;
	
	access_comp:
		'#' diff_ident '.' IDENTIFIER '(' call_function_args ')'	{$$=template("self->%s.%s(&self->%s,%s)", $2,$4,$2,$6);}
	|	'#' diff_ident '.' IDENTIFIER '(' ')' 			{$$=template("self->%s.%s(&self->%s)", $2,$4,$2);}
	|	'#' diff_ident '.' many_access_comp				{$$=template("self->%s.%s", $2,$4);}
	|	diff_ident '.' IDENTIFIER '(' call_function_args ')'		{$$=template("%s.%s(&%s,%s)", $1,$3,$1,$5);}
	|	diff_ident '.' IDENTIFIER '(' ')' 				{$$=template("%s.%s(&%s)", $1,$3,$1);}
	|	diff_ident '.' many_access_comp				{$$=template("%s.%s", $1,$3);}
	;
	
	many_access_comp:
		'#' diff_ident							{$$=template("%s", $2);}
	|	many_access_comp'.''#' diff_ident				{$$=template("%s.%s", $1,$4);}
	|	diff_ident							{$$=template("%s", $1);}
	|	many_access_comp'.' diff_ident				{$$=template("%s.%s", $1,$3);}
	|	many_access_comp'.'IDENTIFIER '('')' 				{$$=template("%s.%s() ", $1,$3); }	
	|	many_access_comp'.'IDENTIFIER '(' call_function_args ')'	 {$$=template("%s.%s(%s)] ", $1,$3,$5); }
	;
		
	assign_comp_var:
		comp_expr ';'				{$$=template("%s;", $1);}
	|	comp_expr OP_ASSIGN expr ';'		{$$=template("%s= %s;", $1,$3);}
	|	comp_expr assign_op expr ';'		{$$=template("%s %s %s;", $1,$2,$3);}
	;	
	
	comp_func_arguments:
		%empty					{$$=template("SELF ");}
	|	comp_func_arguments_line		{$$=template("SELF, %s", $1);}
	;
	
	comp_func_arguments_line:	
		var_argument ',' comp_func_arguments_line	{$$=template("%s, %s", $1,$3);}
	|	var_argument					{$$=template("%s", $1);}
	;		
	
	decl_comp_functions:
		decl_comp_functions KW_DEF IDENTIFIER '(' comp_func_arguments ')' return_type ':' func_command_block KW_ENDDEF ';' 	
		{//creating the definitions of functions
		char* out = template( "\n%s %s(%s){\n%s\n}\n", $7,$3,$5,$9);
		deff = template("%s%s", deff,out);
		
		//creating the variables of const ctor_nameOfStr
		char* one_ctor_var = template(", .%s=%s", $3, $3);
		ctor_vars = template("%s%s", ctor_vars, one_ctor_var);
	
		$$=template("\n%s\n %s (*%s) (%s);\n",$1,$7,$3,$5);} 
	|	KW_DEF IDENTIFIER '(' comp_func_arguments ')' return_type ':' func_command_block KW_ENDDEF ';'				
		{//creating the definitions of functions
		deff = calloc(500,sizeof(char));
		char* out = template( "\n%s %s (%s){\n%s\n}\n", $6,$2,$4,$8);
		deff = template("%s", out);
		
		//creating the variables of const ctor_nameOfStr
		ctor_vars = calloc(70,sizeof(char));
		char* one_ctor_var = template(" .%s=%s", $2, $2);
		ctor_vars = template("%s", one_ctor_var);
		
		$$=template("%s (*%s) (%s);\n",$6,$2,$4);} 
	;	
	
	//comp variables' declaration on the same line
	decl_comp_var_sameLine:
		decl_comp_var_sameLine ',' '#' var_ident 	{$$=template("%s, %s", $1,$4);}
	|	'#' var_ident					{$$=template("%s", $2);}
	;
	
	decl_comp_var:
		decl_comp_var_sameLine ':' var_types ';'	{$$=template("%s %s;", $3,$1);}
	|	decl_comp_var_sameLine ':' IDENTIFIER ';'	{$$=template("%s %s;", $3,$1);}
	;
	
	//Multiple comp variables' declarations
	decl_comp_vars:
		decl_comp_var decl_comp_vars	{$$=template("%s\n%s", $1,$2);}
	|	decl_comp_var			{$$=template("%s", $1);}
	;
	
	//one comp declaration
	decl_one_comp:
		KW_COMP IDENTIFIER ':' decl_comp_vars decl_comp_functions KW_ENDCOMP ';'	
		{//Storing the name of the struct
		
		if(str_names == NULL){
			str_names = template("%s", $2);
		}else{
			str_names = template("%s %s", str_names, $2);
		}
		char* strCopy = template("%s",str_names);
		
		//Checking for objects of other structs in variables
		char* var_saveptr = NULL;
		char* names_saveptr = NULL ;
		char* one_var_saveptr =NULL ;
		char* var_token = NULL;
		char* vars = template("%s ",$4); 
		char* names_token = strtok_r(strCopy," ", &names_saveptr);
		

		while (names_token!=NULL){
			var_token = NULL;
			char* varCopy = template("%s",vars);
			var_token = strtok_r(varCopy, ";", &var_saveptr);
			
			while (var_token!=NULL){		
				one_var_saveptr = NULL;

				char* one_var_token = strtok_r(var_token, ", ", &one_var_saveptr); //seperating the type of var
				//Deleting the \n char after tokenization so i can compare
				char* one_varCopy = template("%s", one_var_token);
				char* copy = strtok(var_token,"\n");
				if(strcmp(names_token,copy)==0){
					char* ctor = template("ctor_%s", copy);

					//Seperated the type, continue to var
					one_var_token = strtok_r(NULL,", ",&one_var_saveptr);			
					while(one_var_token!=NULL){
						one_varCopy = strdup(one_var_token);
						char* found_array = strtok(one_varCopy, "[]");
						found_array = strtok(NULL,"[]");
						if(found_array!=NULL){
							char* len=calloc(strlen(found_array),sizeof(char));
							len = template("%s%s",len,found_array);
							char* cat = template(", .%s={[0 ... %s-1]=%s}", strtok(one_var_token,"["),len,ctor);
							ctor_vars = template("%s%s", ctor_vars,cat);					
							free(len);
						}else if(found_array==NULL){
							char* cat = template(", .%s=%s", one_var_token,ctor);
							ctor_vars = template("%s%s", ctor_vars,cat);					
						}
						one_var_token = strtok_r(NULL,", ",&one_var_saveptr);
					}
				}
			var_token = strtok_r(NULL, ";", &var_saveptr);
			}
		names_token = strtok_r(NULL," ", &names_saveptr);
		}
		$$=template("#define SELF struct %s *self \ntypedef struct %s{\n%s \n%s\n}%s; \n%s\n\nconst %s ctor_%s = {%s };\n#undef SELF\n",$2,$2,$4,$5,$2,deff,$2,$2,ctor_vars);
		if(deff!=NULL && ctor_vars!=NULL){
			free(deff);
			free(ctor_vars);
		}
		}
	|	KW_COMP IDENTIFIER ':' decl_comp_vars KW_ENDCOMP ';'				
		{//Storing the name of the struct
		
		if(str_names == NULL){
			str_names = template("%s", $2);
		}else{
			str_names = template("%s %s", str_names, $2);
		}
		char* strCopy = template("%s",str_names);
		
		//Checking for objects of other structs in variables
		char* var_saveptr = NULL;
		char* names_saveptr = NULL ;
		char* one_var_saveptr =NULL ;
		char* var_token = NULL;
		char* vars = template("%s ",$4); 
		char* names_token = strtok_r(strCopy," ", &names_saveptr);
		ctor_vars = "";
		
		while (names_token!=NULL){
			var_token = NULL;
			char* varCopy = template("%s",vars);
			var_token = strtok_r(varCopy, ";", &var_saveptr);
			
			while (var_token!=NULL){		
				one_var_saveptr = NULL;

				char* one_var_token = strtok_r(var_token, ", ", &one_var_saveptr); //seperating the type of var
				//Deleting the \n char after tokenization so i can compare
				char* one_varCopy = template("%s", one_var_token);
				char* copy = strtok(var_token,"\n");
				if(strcmp(names_token, copy)==0){
					char* ctor = template("ctor_%s", copy);

					//Seperated the type, continue to var
					one_var_token = strtok_r(NULL,", ",&one_var_saveptr);			
					while(one_var_token!=NULL){
						one_varCopy = strdup(one_var_token);
						char* found_array = strtok(one_varCopy, "[]");
						found_array = strtok(NULL,"[]");
						char* cat = NULL;
						if(found_array!=NULL){
							char* len=calloc(strlen(found_array),sizeof(char));
							len = template("%s%s",len,found_array);
							if(ctor_vars == ""){ 
								cat = template(" .%s={[0 ... %s-1]=%s}", strtok(one_var_token,"["),len,ctor);
								free(len);
							}else{
								cat = template(", .%s={[0 ... %s-1]=%s}", strtok(one_var_token,"["),len,ctor);
								free(len);
							}
							ctor_vars = template("%s%s", ctor_vars,cat);					
							
						}else if(found_array==NULL){
							if(ctor_vars == ""){
								cat = template(" .%s=%s", one_var_token,ctor);
							}else{
								cat = template(", .%s=%s", one_var_token,ctor);
							}
							ctor_vars = template("%s%s", ctor_vars,cat);					
						}
						one_var_token = strtok_r(NULL,", ",&one_var_saveptr);
					}
				}
			var_token = strtok_r(NULL, ";", &var_saveptr);
			}
		names_token = strtok_r(NULL," ", &names_saveptr);
		}
		$$=template("#define SELF struct %s *self \ntypedef struct %s{\n%s \n} %s;\n\nconst %s ctor_%s = {%s};\n#undef SELF\n",$2,$2,$4,$2,$2,$2,ctor_vars);
		if(ctor_vars != NULL){
			free(ctor_vars);
		}
		}
	|	KW_COMP IDENTIFIER ':' decl_comp_functions KW_ENDCOMP ';'			
		{//Storing the name of the struct
		char* name = template("%s ",$2);
		if(str_names == NULL){
			str_names = template("%s", name);
		}else{
			str_names = template("%s %s", str_names, name);
		}
		
		$$=template("#define SELF struct %s *self \ntypedef struct %s{\n%s}%s; \n%s\n\nconst %s ctor_%s = {%s};\n#undef SELF\n",$2,$2,$4,$2,deff,$2,$2,ctor_vars);
		if(deff!=NULL && ctor_vars!=NULL){
			free(deff);
			free(ctor_vars);
		}
		}
	;
	
	//----------------------------------------Const variables-------------------------------------
	//Const variables' declaration on the same line
	decl_const_var:
		KW_CONST decl_const_var_sameLine ':' var_types ';'	{$$=template("const %s %s;\n", $4,$2);}
	;
	
	decl_const_var_sameLine:
		decl_const_var_sameLine ',' var_ident 		{$$=template("%s, %s", $1,$3);}
	|	var_ident						{$$=$1;}
	;
		
	//=================================Functions declaration==========================================================
	
	// Call function statement
	call_function :
		IDENTIFIER '(' call_function_args ')' ';'	{$$ = template("%s(%s);",$1,$3);}
	|	IDENTIFIER '('')' ';'				{$$ = template("%s();",$1);}
	;
	
	call_function2:
		IDENTIFIER '(' call_function_args ')'	{$$ = template("%s(%s)",$1,$3);}
	|	IDENTIFIER '('')'			{$$ = template("%s()",$1);}
	;

	call_function_args :
		call_function_args ',' expr 	{$$ = template("%s, %s",$1,$3);}
	|	expr 				{$$ = $1;}
	;

	//Declare one function
	decl_function:
		KW_DEF IDENTIFIER '(' func_arguments ')' return_type ':' func_command_block KW_ENDDEF ';'	{$$=template("%s %s(%s) {\n%s\n}",$6,$2,$4,$8);} 
	;
		
	var_argument:
		IDENTIFIER '[' INTEGER ']' ':' var_types	{$$=template("%s %s[%s]", $6,$1,$3);}
	|	IDENTIFIER '[' ']' ':' var_types		{$$=template("%s *%s", $5,$1);}
	|	IDENTIFIER ':' var_types			{$$=template("%s %s", $3,$1);}
	|	IDENTIFIER '[' INTEGER ']' ':' IDENTIFIER	{$$=template("%s %s[%s]", $6,$1,$3);}
	|	IDENTIFIER '[' ']' ':' IDENTIFIER		{$$=template("%s *%s", $5,$1);}
	|	IDENTIFIER ':' IDENTIFIER			{$$=template("%s %s", $3,$1);}
	;
	
	return_type:
		%empty			    	{$$=template("void");}//no return type
	|	'-''>' KW_VOID			{$$=template("void");}
	|	'-''>' KW_INTEGER          	{$$=template("int");}
	|   	'-''>' KW_SCALAR           	{$$=template("double");}
	|  	'-''>' KW_STR              	{$$=template("StringType");}
	|	'-''>' KW_BOOLEAN         	{$$=template("int");} //returns 0 or 1
	|	'-''>' IDENTIFIER		{$$=template("%s", $3);}
	;
	
	func_arguments:
		%empty					{$$=template("");}
	|	var_argument ',' func_arguments	{$$=template("%s, %s", $1,$3);}
	|	var_argument				{$$=template("%s", $1);}
	;
	
	func_command_block:
		%empty				{$$=template(" ");}
	|	statements_command_block 	{$$=template("%s",$1);}	
	;
		
	
	//=================================Statements===========================================================
	
	statement:
		assign_comp_var	{$$=template("%s\n",$1);}
	|	assign			{$$=template("%s\n",$1);}
	|	decl_var_comp		{$$=template("%s",$1);}
	|	decl_var		{$$=template("%s",$1);}	
	|	decl_const_var		{$$=template("%s",$1);}
	|	call_function		{$$=template("%s",$1);}
	|	if_statement		{$$=template("%s",$1);}
	|	while_statement	{$$=template("%s",$1);}
	|	for_statement		{$$=template("%s",$1);}
	|	KW_BREAK ';'		{$$=template("break;");}
	|	KW_CONTINUE ';'	{$$=template("continue;");}
	|	KW_RETURN ';'		{$$=template("return;");}
	|	KW_RETURN expr ';'	{$$=template("return %s;", $2);}
	;
	
	statements_command_block:
		statements_command_block statement  	{$$ = template("%s\n%s", $1,$2);} 	
	|	statement				{$$ = template("%s",$1);}
	;
	
	if_statement:
		KW_IF '(' expr ')' ':' statements_command_block KW_ELSE ':' statements_command_block KW_ENDIF ';'	{$$ = template("if(%s){\n%s\n}\n else{\n%s\n}\n",$3,$6,$9);}
	|	KW_IF '(' expr ')' ':' statements_command_block KW_ENDIF ';'						{$$ = template("if(%s){\n%s\n}\n",$3,$6);}
	;
	
	for_statement:
		KW_FOR IDENTIFIER KW_IN '[' expr ':' expr ':' expr ']' ':' statements_command_block KW_ENDFOR ';'	
	{var_value = atoi($9); 
	if(var_value>0) {$$ = template("for(int %s = %s; %s < %s; %s+=%s){\n%s\n}\n",$2,$5,$2,$7,$2,$9,$12);}	
	else if(var_value == -1){ $$ =template("for(int %s = %s; %s < %s; %s--){\n%s\n}\n",$2,$5,$2,$7,$2,$12);}
	else{$$ = template("for(int %s=%s; %s<%s; %s-=%s){\n%s\n}\n",$2,$5,$2,$7,$2,$9+1,$12);}}	
	|	KW_FOR IDENTIFIER KW_IN '[' expr ':' expr ']' ':'statements_command_block KW_ENDFOR ';'
		{$$ = template("for(int %s = %s; %s < %s; %s++){\n%s\n}\n",$2,$5,$2,$7,$2,$10);}
	;
	
			
	while_statement:
		 KW_WHILE '(' expr ')' ':' statements_command_block KW_ENDWHILE ';'       {$$ = template("while(%s){\n%s}\n",$3,$6);}
	;	
%%
int main() {
		if ( yyparse() == 0 )
			printf("Your program is syntactically correct!\n");
		else
			printf("Error!\n");
	}
