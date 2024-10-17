%{
#include<bits/stdc++.h>
#include "s_table.cpp"
using namespace std;

int yylex(void);
int yyparse(void);
extern int line_count,error_count;
extern FILE *yyin;
ofstream logfile, errfile;
vector<SymbolInfo*> vars ,parameters,args;
int multi_declaration = 0, var_error = 1,startFunc = 0;
int no_of_label = 0;
string func_name = "";
SymbolTable st(7);

////////////////for ASSEMBLY CODES /////////////////////////
string asmVars = "", asmCode = "", asmFunc = "";
int temp1_use = 0, temp2_use = 0;
string newTemp;


void fileInit(){
	logfile.open("1705115_log.txt");
	errfile.open("1705115_error.txt");
}

void fileClose(){
	logfile.close();
	errfile.close();
}
void yyerror(char *s){
	logfile << "At line no: " << line_count + 1<<" " << s << endl;
	error_count++;
}

void prLine(){
	logfile << "At line no: " << line_count + 1 <<" ";
}
string changeDot(string s);
void printError(string type){
	error_count++;
    logfile << "Error at line no "<<line_count + 1 <<" : "<<type<<endl<<endl;
    errfile << "Error at line no "<<line_count + 1 <<" : "<<type<<endl<<endl;
}
void insertFunc(string s, string state, string type){
	func_name = s;
	startFunc = 1;
	SymbolInfo *sym = st.lookUpCurr(s);
	int ch = 1;
	if(sym != NULL){
		if(sym->getState() != "defined" && sym->getState() != "declared"){
			printError("Multiple declaration of "+s); ///////////semantic error//////////////////
			ch = 0;
		}
		else if(sym->getState() == "defined"){
			printError(s + " is previously defined."); ///////////semantic error//////////////////
			multi_declaration = 1;
			return;
		}
		else if(state == "declared"){
			printError("Multiple declaration of "+s); ///////////semantic error//////////////////
			multi_declaration = 1;
			return;
		}
		if(ch){
			if(type.compare(sym->getID_type()) != 0){
				printError("Return type mismatch with function declaration in function "+s);
			}
			if(parameters.size() != sym->params.size()){
				printError("Total number of arguments mismatch with declaration in function "+s); ///////////semantic error//////////////////
			}
			else{cout<<s<<" addddd"<<endl;
				for(int i = 0; i < parameters.size(); i++){cout<<parameters.size()<<endl;
					//cout<<i<<" "<<parameters[i]->getName()<<endl;
					cout<<parameters[i]->getName()<<endl;
					sym->params[i]->setName(parameters[i]->getName());
					if(parameters[i]->getID_type() != sym->params[i]->getID_type()){
						printError(s + " parameter does not match with previous declaration."); ///////////semantic error//////////////////
					}
					cout<<i<<endl;
				}
			}
			
			st.Insert(sym);	//inserting function in global scope
			//////previously decalred, and now defining a function;/////////////////
			st.enterScope();//cout<<s<<"3"<<endl;
			for(int i = 0; i < parameters.size(); i++){
				parameters[i]->varName = parameters[i]->getName() += changeDot(st.curr_id());
				asmVars += "\t" + parameters[i]->varName + " DW ?\n";
				sym->params[i]->varName = parameters[i]->varName;
				if(st.lookUpCurr(parameters[i]->getName()) == NULL) st.Insert(parameters[i]);
				else{
					printError("Multiple declaration of " + parameters[i]->getName() +" in parameter");
				}
			}
			sym->setState("defined");
			//cout<<sym->getName()<<"090"<<sym->getState()<<endl;
			sym->setID_type(type);
			return;
		}
	}
	else sym = new SymbolInfo(s,"ID");
	sym->setID_type(type);
	sym->setState(state);
	for(int i = 0; i < parameters.size(); i++){
		sym->params.push_back(parameters[i]);
	}
	
	st.Insert(sym);	//inserting function in global scope
	
	if(state == "defined"){ 
		st.enterScope();
		for(int i = 0; i < parameters.size(); i++){
			parameters[i]->varName = parameters[i]->getName() += changeDot(st.curr_id());
			asmVars += "\t"+parameters[i]->varName + " DW ?\n";
			sym->params[i]->varName = parameters[i]->varName;
			if(st.lookUpCurr(parameters[i]->getName()) == NULL) st.Insert(parameters[i]);
			else{
				printError("Multiple declaration o " + parameters[i]->getName() +" in parameter");
			}
		}
	}
}
void scopeStart(){
	if(startFunc == 1){
		startFunc = 0;
	}
	else st.enterScope();
}
SymbolInfo* prCode(string name, string type){
	SymbolInfo *sym = new SymbolInfo(name,type);
	logfile << name << endl << endl;
	return sym;
}

string changeDot(string s){
	for(int i = 0; i < s.length(); i++){
		if(s[i] == '.') s[i] = '_';
	}
	return s;
}

void copy_inc_ops(SymbolInfo *s1, SymbolInfo *s2){
	for(int i = 0; i < s2->inc_ops.size(); i++) s1->inc_ops.push_back(s2->inc_ops[i]);
}
%}
%union {
	SymbolInfo *symbol;
}
%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON COMMENT STRING PRINTLN
%token <symbol> CONST_INT CONST_FLOAT CONST_CHAR ID ADDOP MULOP RELOP LOGICOP
%type <symbol> program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
start : program{
		prLine(); logfile << "start : program" << endl << endl;
		st.printAllScope(logfile);

		///////////////////////assembly code print////////////////////////////////////
		ofstream asmfile;
		asmfile.open("code.asm");

		///macro for printing string 
		asmfile << "PRINTS MACRO P\nPUSHA" << endl;
    	asmfile << "LEA DX,P" << endl;
    	asmfile <<  "MOV AH,9" << endl;
    	asmfile << "INT 21H\nPOPA" << endl;
		asmfile << "ENDM" << endl;



		asmfile << ".MODEL SMALL" << endl <<  endl;
		asmfile << ".STACK 100H" << endl << endl;
		asmfile << ".DATA" << endl;
		asmfile << "\tCR EQU 0DH" << endl;
   		asmfile << "\tLF EQU 0AH" << endl; 
		asmfile <<asmVars<< endl;
		asmfile <<"\t X dw ? " <<endl;
		asmfile << "BR DB CR,LF, \'$\' " << endl;
		asmfile << "RET_VAR DW ?" << endl;
		asmfile << ".CODE" << endl;



		asmfile << $1->asmCode <<endl;

		//////built print number function ///////////
		asmfile << "PRINT_NUMBER PROC" << endl;
    	asmfile << "\tPUSHA"<< endl;
    	asmfile << "\tMOV DX,\';\'" << endl;
    	asmfile << "\tPUSH DX"<< endl;
		asmfile << "CMP X, 0" << endl;
		asmfile	<< "JGE LLP"<<endl;
		asmfile << "MOV AH, 2"<<endl;
		asmfile << "MOV DL,\'-\'" << endl;
		asmfile	<< "INT 21H" << endl;
		asmfile	<< "NEG X" << endl;
    	asmfile << "\tLLP:" << endl;
    	asmfile << "\tMOV DX,0" << endl;
    	asmfile << "\tMOV AX,X" << endl;
    	asmfile << "\tMOV BX,10" <<endl;
    	asmfile << "\tDIV BX" <<  endl;
    	asmfile << "\tMOV X,AX" << endl;  
    	asmfile << "\tADD DX,30H" << endl; 
    	asmfile << "\tPUSH DX" << endl;
    	asmfile << "\tCMP X,0" << endl;
	    asmfile << "\tJE STACK_ITERATE"<< endl;
    	asmfile << "\tJMP LLP" << endl;
    	asmfile << "\tSTACK_ITERATE:" << endl;
    	asmfile << "\tPOP BX" << endl;
    	asmfile << "\tCMP BX,\';\'" << endl;
    	asmfile << "\tJE PRINT_END" << endl;
    	asmfile << "\tMOV AH,2" << endl;
    	asmfile << "\tMOV DL,BL" << endl;
    	asmfile << "\tINT 21H" << endl;
    	asmfile << "\tJMP STACK_ITERATE" << endl;
    	asmfile << "\tPRINT_END:" << endl;
    	asmfile << "\tPOPA" << endl;
    	asmfile << "\tRET" << endl;
	 	asmfile << "PRINT_NUMBER ENDP" << endl;
		asmfile << asmFunc << endl;

		asmfile << "END MAIN" << endl;




		asmfile.close();
	}
      ;
program : program unit{
		prLine(); logfile << "program : program unit" << endl << endl;
		$$ = prCode($1->getName() + "\n" + $2->getName(), "program");

		$$->asmCode += $1->asmCode + $2->asmCode;
	  }
	| unit{
		prLine(); logfile << "program : unit" << endl << endl;
		$$ = prCode($1->getName(),"program");

		$$->asmCode += $1->asmCode;
	}
	;
	
unit : var_declaration{
		prLine(); logfile << "unit : var_declaration" << endl << endl;
		$$ = prCode($1->getName(),"unit");
		
		//inserting variables in global scope
		for(int i = 0; i < vars.size(); i++){
			st.Insert(vars[i]);
		}
		vars.clear();
	 }
     | func_declaration{
     		prLine(); logfile << "unit : func_declaration" << endl << endl;
     		$$ = prCode($1->getName(),"unit");
     	}
     | func_definition{
     		prLine(); logfile << "unit : func_definition" << endl << endl;
     		$$ = prCode($1->getName(),"unit");

			$$->asmCode += $1->asmCode;
     	}
     ;

func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON{
		    	prLine(); logfile << "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl <<endl;
		    	$$ = prCode($1->getName()+" "+$2->getName()+"("+$4->getName()+");\n","func_declaration");
		    	
		    	insertFunc($2->getName(),"declared",$1->getName());
		    	parameters.clear();
		 }
		 | type_specifier ID LPAREN RPAREN SEMICOLON{
		 	prLine(); logfile << "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl << endl;
		 	$$ = prCode($1->getName()+" "+$2->getName()+"();\n","func_declaration");
		 	
		 	insertFunc($2->getName(),"declared",$1->getName());
		 }
		 ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN {insertFunc($2->getName(),"defined",$1->getName());} compound_statement{
			prLine(); logfile << "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl << endl;
			$$ = prCode($1->getName()+" "+$2->getName()+"("+$4->getName()+")"+$7->getName(),"func_definition");
			
			////////////////////////////////////////cheking if function is declared is before ///////////////////////////////////////////////////////
			parameters.clear();

			asmFunc += $2->getName() + " PROC\n";
			asmFunc += "PUSHA\n";
			asmFunc += $7->asmCode+"\n";
			asmFunc += "LABEL_"+func_name+":\n";
			asmFunc += "POPA\nRET\n";
			asmFunc += $2->getName() + " ENDP\n";
		}
		| type_specifier ID LPAREN RPAREN {insertFunc($2->getName(),"defined",$1->getName());} compound_statement{
			prLine(); logfile << "func_definition : type_specifier ID LPAREN RPAREN compound_statement" << endl << endl;
			$$ = prCode($1->getName()+" "+$2->getName()+"()"+$6->getName(),"func_definition");
			

			if($2->getName() == "main"){
				$$->asmCode += "MAIN PROC\nMOV AX,@DATA\nMOV DS,AX\n";
				$$->asmCode += $6->asmCode;
				$$->asmCode += "LABEL_"+func_name+":\n";
				$$->asmCode += "MOV AH,4CH\nINT 21H\nMAIN ENDP";
			}
			else{
				asmFunc += $2->getName() + " PROC\n";
				asmFunc += "PUSHA\n";
				asmFunc += $6->asmCode+"\n";
				asmFunc += "LABEL_"+func_name+":\n";
				asmFunc += "POPA\nRET\n";
				asmFunc += $2->getName() + " ENDP\n";

			}
			
		}
		;
		
parameter_list : parameter_list COMMA type_specifier ID{
				prLine(); logfile << "parameter_list : parameter_list COMMA type_specifier ID" << endl << endl;	
				$$ = prCode($1->getName()+","+$3->getName()+" "+$4->getName(),"parameter_list");
				
				SymbolInfo *sym = new SymbolInfo($4->getName(),"ID");
				sym->setID_type($3->getName());
	       		parameters.push_back(sym);
		   }
	       | parameter_list COMMA type_specifier{
	       		prLine(); logfile << "parameter_list : parameter_list COMMA type_specifier" << endl << endl;
	       		$$ = prCode($1->getName()+","+$3->getName(),"parameter_list");	
	       		
	       		SymbolInfo *sym = new SymbolInfo("dummy","ID");
				sym->setID_type($3->getName());
				parameters.push_back(sym);
	       }
	       | type_specifier ID{
	       		prLine(); logfile << "type_specifier ID" << endl << endl;
	       		$$ = prCode($1->getName()+" "+$2->getName(),"parameter_list");
	       		
	       		SymbolInfo *sym = new SymbolInfo($2->getName(),"ID");
	       		sym->setID_type($1->getName());
	       		parameters.push_back(sym);
	       }
	       | type_specifier{
	       		prLine(); logfile << "parameter_list : type_specifier" << endl << endl;
	       		$$ = prCode($1->getName(),"parameter_list");	
	       		
	       		SymbolInfo *sym = new SymbolInfo("dummy","ID");
	       		sym->setID_type($1->getName());
	       		parameters.push_back(sym);
	       }
	       ;
	       
compound_statement : LCURL{scopeStart();} statements RCURL{
		    	prLine(); logfile << "compound_statement : LCURL statements RCURL" << endl << endl;
		    	$$ = prCode("{\n"+$3->getName()+"\n}","compound_statement");
		    	
		    	if(multi_declaration == 0){
					st.exitScope(logfile);
				}
				else multi_declaration = 0;

				$$->asmCode +=$3->asmCode;
		    }
		    | LCURL RCURL{
		    	prLine(); logfile << "compound_statement : LCURL RCURL" << endl << endl;
		    	$$ = prCode("{\n}","compound_statement");
		    }
		    ;
		    
var_declaration : type_specifier declaration_list SEMICOLON{
			
			prLine(); logfile << "var_declaration : type_specifier declaration_list SEMICOLON" << endl << endl;
		  	$$ = prCode($1->getName() + " " + $2->getName() + ";","var_declaration");
		  	
		  	if($1->getName() == "void"){
		  		printError("Invaild Delcartion. Type can not be void.");
		  	}
		  	else{
			  	////////////////////////////////////////////////////////setting ID types(int,float) to the variables//////////////////////////////////////////////////
			  	for(int i = 0; i < vars.size(); i++){
			  		vars[i]->setID_type($1->getName());
			  	}
		  	}
		 }
		 ;

type_specifier : INT{
			prLine(); logfile << "type_specifier : INT" << endl << endl;
			$$ = prCode("int","type_specifier");

		}
		| FLOAT{
			prLine(); logfile << "type_specifier : FLOAT" << endl <<endl;
			$$ = prCode("float","type_specifier");

		}
		| VOID{
			prLine(); logfile << "type_specifier : VOID" << endl << endl;
			$$ = prCode("void","type_specifier");
		}
		;

declaration_list : declaration_list COMMA ID{
		  	prLine(); logfile << "declaration_list : declaration_list COMMA ID" << endl << endl;
		  	$$ = prCode($1->getName()+","+$3->getName(),"declaration_list");
		  	
		  	////////////////////////////////////////////////////////checking previous declaration////////////////////////////////////////////////////////////////
		  	if(st.lookUpCurr($3->getName()) != NULL){
		  		printError("Multiple declaration of "+$3->getName());
		  	}
		  	else{
			  	SymbolInfo* sym = new SymbolInfo($3->getName(),"ID");
			  	vars.push_back(sym);
				sym->varName = $3->getName() + changeDot(st.curr_id());
				asmVars += "\t"+sym->varName +" DW \?\n";
			 }
		  }
		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD{
		  	prLine(); logfile << "declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl << endl;
		  	$$ = prCode($1->getName()+","+$3->getName()+"["+$5->getName()+"]","declaration_list");
		  	
		  	////////////////////////////////////////////////////////checking previous declaration////////////////////////////////////////////////////////////////
		  	if(st.lookUpCurr($3->getName()) != NULL){
		  		printError("Multiple declaration of "+$3->getName());
		  	}
		  	else{
			  	SymbolInfo* sym = new SymbolInfo($3->getName(),"ID");
			  	sym->setSize(stoi($5->getName()));
				sym->varName = $3->getName() + changeDot(st.curr_id());
			  	vars.push_back(sym);
			 }

			 asmVars += "\t"+$3->getName() + changeDot(st.curr_id()) +" DW "+$5->getName()+" DUP(0)\n";
		  }
		  | ID{
		  	prLine(); logfile << "declaration_list : ID" << endl << endl;
		  	$$ = prCode($1->getName(),"declaration_list");
		  	
		  	////////////////////////////////////////////////////////checking previous declaration////////////////////////////////////////////////////////////////
		  	if(st.lookUpCurr($1->getName()) != NULL){
		  		printError("Multiple declaration of "+$1->getName());
		  	}
		  	else{
			  	SymbolInfo* sym = new SymbolInfo($1->getName(),"ID");
				sym->varName = $1->getName() + changeDot(st.curr_id());
			  	vars.push_back(sym);
			}
			
			asmVars += "\t"+$1->getName() + changeDot(st.curr_id()) +" DW \?\n";

		  }
		  | ID LTHIRD CONST_INT RTHIRD{
		  	prLine(); logfile << "declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl << endl;
		  	$$ = prCode($1->getName()+"["+$3->getName()+"]","declaration_list");
		  	
		  	
		  	
		  	////////////////////////////////////////////////////////checking previous declaration////////////////////////////////////////////////////////////////
		  	if(st.lookUpCurr($1->getName()) != NULL){
		  		printError("Multiple declaration of "+$1->getName());
		  	}
		  	else{
			  	SymbolInfo* sym = new SymbolInfo($1->getName(),"ID");
			  	sym->setSize(stoi($3->getName()));
				sym->varName = $1->getName() + changeDot(st.curr_id());
			  	vars.push_back(sym);
			}

			asmVars += "\t"+$1->getName() + changeDot(st.curr_id()) +" DW "+$3->getName()+" DUP(0)\n";
		  }
		  ;
		  
statements : statement{
	   	prLine(); logfile << "statements : statement" << endl << endl;
	   	$$ = prCode($1->getName(),"statements");


		$$->asmCode += $1->asmCode;
	}
	| statements statement{
	   	prLine(); logfile << "statements : statements statement" << endl << endl;
	   	$$ = prCode($1->getName()+"\n"+$2->getName(),"statements");

		$$->asmCode += $1->asmCode + $2->asmCode;
    }
    ;
	   
statement : var_declaration{
	  	prLine(); logfile << "statement : var_declaration" << endl << endl;
	  	$$ = prCode($1->getName(),"statement");
	  	
	  	//inserting variables in current scope
	  	for(int i = 0; i < vars.size(); i++){
			st.Insert(vars[i]);
		}
		vars.clear();
	  	
	  }
	  | expression_statement{
	  	prLine(); logfile << "statement : expression_statement" << endl << endl;
	  	$$ = prCode($1->getName(),"statement");

		$$->asmCode += $1->asmCode;
	  }
	  | compound_statement{
	  	prLine(); logfile << "statement : compound_statement" << endl <<endl;
	  	$$ = prCode($1->getName(),"statement");

		$$->asmCode += $1->asmCode;
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement{
	  	prLine(); logfile << "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl << endl;
	  	$$ = prCode("for("+$3->getName()+" "+$4->getName()+" "+$5->getName()+")"+$7->getName(),"statement");

		$$->asmCode += "; ------------------for("+$3->getName()+" "+$4->getName()+" "+$5->getName()+")"+"------------------------\n";
		$$->asmCode += $3->asmCode;
		no_of_label++;
		$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
		if(!$4->isEmpty){
			$$->asmCode += $4->asmCode;
			$$->asmCode += "POP AX\n";
			$$->asmCode += "CMP AX, 0\n";
			$$->asmCode += "JE LABEL"+to_string(no_of_label+1)+"\n";
		}
		$$->asmCode += $7->asmCode + $5->asmCode;
		for(int i = 0; i < $5->inc_ops.size(); i++){
			$$->asmCode += $5->inc_ops[i].second +" "+ $5->inc_ops[i].first+"\n";
		}
		$$->asmCode += "JMP LABEL"+to_string(no_of_label)+"\n";
		no_of_label++;
		$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";


	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE{
	  	prLine(); logfile << "statement : IF LPAREN expression RPAREN statement" << endl << endl;
	  	$$ = prCode("if("+$3->getName()+")"+$5->getName(),"statement");

		no_of_label++;
		$$->asmCode += $3->asmCode;
		for(int i = 0; i < $3->inc_ops.size(); i++){
			$$->asmCode += $3->inc_ops[i].second +" "+ $3->inc_ops[i].first+"\n";
		}
		$$->asmCode += "POP AX\nCMP AX, 0\n";
		$$->asmCode += "JE LABEL"+to_string(no_of_label)+"\n";
		$$->asmCode += $5->asmCode;
		$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
	  	
	  }
	| IF LPAREN expression RPAREN statement ELSE statement{
	  	prLine(); logfile << "statement : IF LPAREN expression RPAREN statement ELSE statement" << endl << endl;
	  	$$ = prCode("if("+$3->getName()+")"+$5->getName()+"\nelse"+$7->getName(),"statement");
		$$->asmCode += "\; ---------------------if("+$3->getName()+")---------------------\n";
		no_of_label++;
		$$->asmCode += $3->asmCode;
		for(int i = 0; i < $3->inc_ops.size(); i++){
			$$->asmCode += $3->inc_ops[i].second +" "+ $3->inc_ops[i].first+"\n";
		}
		$$->asmCode += "POP AX\nCMP AX, 0\n";
		$$->asmCode += "JE LABEL"+to_string(no_of_label)+"\n";
		$$->asmCode += $5->asmCode;
		$$->asmCode += "JMP LABEL"+to_string(no_of_label+1)+"\n";
		$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
		$$->asmCode += $7->asmCode;
		no_of_label++;
		$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
	}
	| WHILE LPAREN expression RPAREN statement{
	  	prLine(); logfile << "statement : WHILE LPAREN expression RPAREN statement" << endl << endl;
	  	$$ = prCode("while("+$3->getName()+")"+$5->getName(),"statement");
		
		
		$$->asmCode += "; -------------- while("+$3->getName()+")----------------\n";
		
		no_of_label++;
		$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
		$$->asmCode += $3->asmCode;
		for(int i = 0; i < $3->inc_ops.size(); i++){
			$$->asmCode += $3->inc_ops[i].second +" "+ $3->inc_ops[i].first+"\n";
		}
		$$->asmCode += "POP AX\n";
		$$->asmCode += "CMP AX, 0\n";
		$$->asmCode += "JE LABEL"+to_string(no_of_label+1)+"\n";
		$$->asmCode += $5->asmCode;
		$$->asmCode += "JMP LABEL"+to_string(no_of_label)+"\n";
		no_of_label++;
		$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
		
	  	
	  }
	| PRINTLN LPAREN ID RPAREN SEMICOLON{
	  	prLine(); logfile << "statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl << endl;
	  	$$ = prCode("printf("+$3->getName()+");","statement");
	  	
	  	SymbolInfo *sym = st.lookUp($3->getName());
	  	if(sym == NULL){
	  		printError("Undeclared variable "+$3->getName());
	  	}

		$$->asmCode += "\;------------------------- prinln("+$3->getName()+")---------------------------\n";
		$$->asmCode += "MOV AX, "+sym->varName+"\n";
		$$->asmCode += "MOV X, AX\nCALL PRINT_NUMBER\nPRINTS BR\n";
		
	}
	  | RETURN expression SEMICOLON{
	  	prLine(); logfile << "statement : RETURN expression SEMICOLON" << endl << endl;
	  	$$ = prCode("return "+$2->getName()+";","statement");

		$$->asmCode += "; ----------------return "+$2->getName()+"---------------\n";
		$$->asmCode += $2->asmCode;
		$$->asmCode += "POP CX\nMOV RET_VAR,CX\n";
		$$->asmCode += "JMP LABEL_"+func_name+"\n";

		for(int i = 0; i < $2->inc_ops.size(); i++){
			$$->asmCode += $2->inc_ops[i].second +" "+ $2->inc_ops[i].first+"\n";
		}
	  }
	  ;
	  
expression_statement : SEMICOLON{
		      	prLine(); logfile << "expression_statement : SEMICOLON" << endl << endl;
		      	$$ = prCode(";","expression_statement");
				$$->isEmpty = 1;
		    }
		    | expression SEMICOLON{
		      	prLine(); logfile << "expression_statement : expression SEMICOLON" << endl << endl;
		      	$$ = prCode($1->getName()+";","expression_statement");

				$$->asmCode += "; -----------------------"+$1->getName()+"------------------\n";
				$$->asmCode += $1->asmCode;	
				$$->isEmpty = 0;
				//$$->asmCode += "POP AX\n";

				for(int i = 0; i < $1->inc_ops.size(); i++){
					$$->asmCode += $1->inc_ops[i].second +" "+ $1->inc_ops[i].first+"\n";
				}
		    }
		    ;
		     
variable : ID{
	 	prLine(); logfile << "variable : ID" << endl << endl;
	 	prCode($1->getName(),"variable");
	 	//cout<<line_count+1<<" "<<$1->getName()<<" "<<$1->getSize()<<endl;
	 	//////////////////////////////////////////////////////////////checking if variable is declared before///////////////////////////////////////////////////////
	 	SymbolInfo *sym = st.lookUp($1->getName());
	 	if(sym == NULL){
	 		printError("Undeclared variable "+$1->getName() );
	 	}
	 	else if(sym->getSize() != 0){
	 		printError($1->getName() +" is an array. Must provide an index.");
	 	}
	 	else if(sym->getID_type() == "delcared" || sym->getState() == "defined"){
	 		printError("Invalid Function call.");
	 	}
	 	else{
	 		var_error = 0;
	 		$$ = new SymbolInfo(sym);
	 	}
	 }
	 | ID LTHIRD expression RTHIRD{
	 	prLine(); logfile << "variable : ID LTHIRD expression RTHIRD" << endl << endl;
	 	$$ = prCode($1->getName()+"["+$3->getName()+"]","variable");
	 	
	 	//////////////////////////////////////////////////////////////checking if variable is declared before///////////////////////////////////////////////////////
	 	SymbolInfo *sym = st.lookUp($1->getName());
	 	if(sym == NULL){
	 		printError("Undeclared variable "+$1->getName() );
	 	}
	 	else if(sym->getSize() == 0){
	 		printError($1->getName() +" is not an array");
	 	}
	 	else{	
	 		if($3->getID_type() != "int"){
		 		printError("Array index must be int."); ////////////////////////////////////////////////// checking if array index is int
		 	}
	 		var_error = 0;
	 		$$->setID_type(sym->getID_type());
	 	}

		$$->varName = sym->varName;
		//cout << $1->getName() << " "<<$1->getSize() << endl;
		$$->setSize(sym->getSize());
		$$->asmCode += $3->asmCode;

		copy_inc_ops($$,$3);
	 }
	 ;
	 
expression : logic_expression{
	   	prLine(); logfile << "expression : logic_expression" << endl << endl;
	   	$$ = prCode($1->getName(),"expression");
	   	$$->setID_type($1->getID_type());

		$$->asmCode += $1->asmCode;
		copy_inc_ops($$,$1);
	}
	| variable ASSIGNOP logic_expression{
	   	prLine(); logfile << "expression : variable ASSIGNOP logic_expression" << endl << endl;
	   	$$ = prCode($1->getName()+"="+$3->getName(),"expression");
	   	if(var_error == 0){
		   	if($1->getID_type() == "void"){
		   		printError("Values can not be assigned to void types.");
		   	}
		   	else if($3->getID_type() == "void"){
		   		printError("Void function used in expression.");
		   	}
		   	else if($1->getID_type() == "int" && $3->getID_type() != "int"){
		   		//cout<<line_count+1<<" "<<$1->getName()<<" "<<$1->getID_type()<<" "<<$3->getName()<<" "<<$3->getID_type()<<endl;
		   		printError("Type Mismatch.");
		   	}
		   	var_error = 1;

			$$->asmCode += $1->asmCode + $3->asmCode;
			$$->asmCode += "POP CX\n";
			//cout << $1->getName() <<" "<<$1->getSize() << endl;
			if($1->getSize() == 0) $$->asmCode += "MOV "+$1->varName+", CX\n";
			else{
				$$->asmCode += "POP AX\n";
				$$->asmCode += "MOV BX, 2\n";
				$$->asmCode += "MUL BX\n";
				$$->asmCode += "MOV SI, AX\n";
				$$->asmCode += "MOV "+$1->varName+"[SI], CX\n";
			}
	   	}
		copy_inc_ops($$,$1);
		copy_inc_ops($$,$3);
	}
	;
	   
logic_expression : rel_expression{
		  	prLine(); logfile << "logic_expression : rel_expression" << endl << endl;
		  	$$ = prCode($1->getName(),"logic_expression");
		  	$$->setID_type($1->getID_type());

			$$->asmCode += $1->asmCode;
			copy_inc_ops($$,$1);
		 }
		| rel_expression LOGICOP rel_expression{
		  	prLine(); logfile << "logic_expression : rel_expression LOGICOP rel_expression" << endl << endl;
		  	$$ = prCode($1->getName()+$2->getName()+$3->getName(),"logic_expression");
		  	$$->setID_type("int");

			
			
			$$->asmCode += $1->asmCode + $3->asmCode;
			$$->asmCode += "POP BX\nPOP AX\n";

			if($2->getName() == "&&"){
				$$->asmCode += "CMP AX, 0\n";
				no_of_label++;
				$$->asmCode += "JE LABEL"+to_string(no_of_label)+"\n";
				$$->asmCode += "CMP BX, 0\n";
				$$->asmCode += "JE LABEL"+to_string(no_of_label)+"\n";
				$$->asmCode += "MOV AX, 1\n";
				$$->asmCode += "JMP LABEL"+to_string(no_of_label + 1)+"\n";
				$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
				$$->asmCode += "MOV AX, 0\n";
				no_of_label++;
				$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
			}
			else if($2->getName() == "||"){
				$$->asmCode += "OR AX, BX\n";
			}
			no_of_label++;
			$$->asmCode += "CMP AX, 0\n";
			$$->asmCode += "JNE LABEL"+to_string(no_of_label)+"\n";
			$$->asmCode += "PUSH AX\n";
			$$->asmCode += "JMP LABEL"+to_string(no_of_label+1)+"\n";
			$$->asmCode += "LABEL" + to_string(no_of_label)+":\n";
			$$->asmCode += "MOV AX, 1\nPUSH AX\n";
			no_of_label++;
			$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";

			copy_inc_ops($$,$1);
			copy_inc_ops($$,$3);
		 }
		 ;
		 
rel_expression : simple_expression{
		  	prLine(); logfile << "rel_expression : simple_expression" << endl << endl;
		  	$$ = prCode($1->getName(),"rel_expression");
		  	$$->setID_type($1->getID_type());

			$$->asmCode += $1->asmCode;
			copy_inc_ops($$,$1);
		}
		| simple_expression RELOP simple_expression{
		  	prLine(); logfile << "rel_expression : simple_expression RELOP simple_expression" << endl << endl;
		  	$$ = prCode($1->getName()+$2->getName()+$3->getName(),"rel_expression");
		  	if($1->getID_type() == "void" || $3->getID_type() == "void"){
			  	printError("Operands for "+$2->getName()+" operator can not be void");
			}
		  	$$->setID_type("int");
			
			$$->asmCode += $1->asmCode + $3->asmCode;
			$$->asmCode += "POP BX\n";
			$$->asmCode += "POP AX\n";
			$$->asmCode += "CMP AX, BX\n";

			no_of_label++;
			if($2->getName() == "<"){
				$$->asmCode += "JL LABEL"+to_string(no_of_label)+"\n";
			}
			else if($2->getName() == "<="){
				$$->asmCode += "JLE LABEL"+to_string(no_of_label)+"\n";
			}
			else if($2->getName() == ">"){
				$$->asmCode += "JG LABEL"+to_string(no_of_label)+"\n";
			}
			else if($2->getName() == ">="){
				$$->asmCode += "JGE LABEL"+to_string(no_of_label)+"\n";
			}
			else if($2->getName() == "=="){
				$$->asmCode += "JE LABEL"+to_string(no_of_label)+"\n";
			}
			else if($2->getName() == "!="){
				$$->asmCode += "JNE LABEL"+to_string(no_of_label)+"\n";
			}
			$$->asmCode += "MOV AX, 0\n";
			$$->asmCode += "JMP LABEL"+to_string(no_of_label+1)+"\n";
			$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
			$$->asmCode += "MOV AX, 1\n";
			no_of_label++;
			$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
			$$->asmCode += "PUSH AX\n";

			copy_inc_ops($$,$1);
			copy_inc_ops($$,$3);

		}
		;
		
simple_expression : term{
		  	prLine(); logfile << "simple_expression : term" << endl << endl;
		  	$$ = prCode($1->getName(),"simple_expression");
		  	$$->setID_type($1->getID_type());

			$$->asmCode += $1->asmCode;
			copy_inc_ops($$,$1);
		}
		| simple_expression ADDOP term{
		  	prLine(); logfile << "simple_expression : simple_expression ADDOP term" << endl << endl;
		  	$$ = prCode($1->getName()+$2->getName()+$3->getName(),"simple_expression");
		  	if($1->getID_type() == "void" || $3->getID_type() == "void"){
			  	printError("Operands for "+$2->getName()+" operator can not be void");
			}
			else if($1->getID_type() == "float" || $3->getID_type() == "float") $$->setID_type("float");
     		else $$->setID_type("int");

			$$->asmCode += $1->asmCode + $3->asmCode;
			$$->asmCode += "POP BX\n";
			$$->asmCode += "POP AX\n";
			if($2->getName() == "+") $$->asmCode += "ADD AX, BX\n";
			else $$->asmCode += "SUB AX, BX\n";
			$$->asmCode += "PUSH AX\n";

			copy_inc_ops($$,$1);
			copy_inc_ops($$,$3);
		}
		   ;
		   
term : unary_expression{
     		prLine(); logfile << "term : unary_expression" << endl << endl;
     		$$ = prCode($1->getName(),"term");
     		$$->setID_type($1->getID_type());

			$$->asmCode += $1->asmCode;
			copy_inc_ops($$,$1);
     		
    }
    | term MULOP unary_expression{
     	prLine(); logfile << "term : term MULOP unary_expression" << endl <<endl;
    	$$ = prCode($1->getName()+$2->getName()+$3->getName(),"term");
 		if($1->getID_type() == "void" || $3->getID_type() == "void"){
	 		printError("Operands for "+$2->getName()+" operator can not be void");
		}
    		else if($2->getName() == "%"){
 			$$->setID_type("int");
    		if(!($1->getID_type() == "int" && $3->getID_type() == "int")){
    			printError("Operands for modulus operator must be int.");
    		}
    		else if($3->getName() == "0"){
    			printError("Modulus by Zero");
     		}
     	}
     	else{
     		if($1->getID_type() == "float" || $3->getID_type() == "float") $$->setID_type("float");
     		else $$->setID_type("int");
     	}
		
		$$->asmCode += $1->asmCode + $3->asmCode;
		$$->asmCode += "POP BX\n";
		$$->asmCode += "POP AX\n";
		if($2->getName() == "*"){
			$$->asmCode += "MUL BX\n";
			$$->asmCode += "PUSH AX\n";
		}
		else if($2->getName() == "/"){
			$$->asmCode += "DIV BX\n";
			$$->asmCode += "PUSH AX\n";
		}
		else{
			$$->asmCode += "DIV BX\n";
			$$->asmCode += "PUSH DX\n";
		}

		copy_inc_ops($$,$1);
		copy_inc_ops($$,$3);
    }
    ;
     
unary_expression : ADDOP unary_expression{
		  	prLine(); logfile << "unary_expression : ADDOP unary_expression" << endl << endl;
		  	$$ = prCode($1->getName()+$2->getName(),"unary_expression");
		  	if($2->getID_type() == "void"){
		  		printError("Operands for NOT operator can not be void");
		  	}
		  	else $$->setID_type($2->getID_type());
			
			$$->asmCode += $2->asmCode;
			if($1->getName() == "-"){
				$$->asmCode += "POP AX\nNEG AX\nPUSH AX\n";
			}
			copy_inc_ops($$,$2);

		  }
		| NOT unary_expression{
		  	prLine(); logfile << "unary_expression : NOT unary_expression" << endl << endl;
		  	$$ = prCode("!"+$2->getName(),"unary_expression");
		  	/////////////////////////////////////// checking error for void /////////////////////////////////////////
		  	
		  	if($2->getID_type() == "void"){
		  		printError("Operands for NOT operator can not be void");
		  	}
		  	else $$->setID_type($2->getID_type());

			$$->asmCode += $2->asmCode;
			$$->asmCode += "POP AX\n";
			$$->asmCode += "CMP AX, 0\n"; no_of_label++;
			$$->asmCode += "JE LABEL"+to_string(no_of_label)+"\n";
			$$->asmCode += "MOV AX, 0\n";
			$$->asmCode += "JMP LABEL"+to_string(no_of_label+1)+"\n";
			$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
			$$->asmCode += "MOV AX, 1\n"; no_of_label++;
			$$->asmCode += "LABEL"+to_string(no_of_label)+":\n";
			$$->asmCode += "PUSH AX\n";

			copy_inc_ops($$,$2);
		  }
		 | factor{
		  	prLine(); logfile << "unary_expression : factor" << endl<< endl;
		  	$$ = prCode($1->getName(),"unary_expression");
		  	$$->setID_type($1->getID_type());
			$$->asmCode += $1->asmCode;
			copy_inc_ops($$,$1);
		  }
		 ;
		 
factor : variable{
		prLine(); logfile << "factor : variable" << endl << endl;
		$$ = prCode($1->getName(),"factor");
		$$->setID_type($1->getID_type());

		$$->asmCode += $1->asmCode;
		if($1->getSize() == 0) $$->asmCode += "PUSH "+$1->varName+"\n";
		else{
			$$->asmCode += "POP AX\n";
			$$->asmCode += "MOV BX, 2\n";
			$$->asmCode += "MUL BX\n";
			$$->asmCode += "MOV SI, AX\n";
			$$->asmCode += "PUSH "+$1->varName+"[SI]\n";
		}
	}
       | ID LPAREN argument_list RPAREN{
		prLine(); logfile << "factor : ID LPAREN argument_list RPAREN" << endl << endl;
		$$ = prCode($1->getName()+"("+$3->getName()+")","factor");
		
		SymbolInfo *sym = st.lookUp($1->getName());
		if(sym == NULL){
			printError($1->getName()+" function not defined.");
		}
		else if(sym->getState() != "defined"){
			printError($1->getName()+" function not defined.");
		}
		else{
			int i = 0;
			if($3->args.size() < sym->params.size()){
				printError("Too few arguments in function call "+$1->getName());
			}
			else if($3->args.size() > sym->params.size()){
				printError("Too many arguments in function call "+$1->getName());
			}
			else{
				for(i = 0; i < $3->args.size(); i++){
					if(sym->params[i]->getID_type() != $3->args[i]->getID_type()){
						printError(to_string(i+1)+"th argument should be "+sym->params[i]->getID_type()+" in function "+$1->getName());
						break;
					}
				}	
			}
			$$->setID_type(sym->getID_type());
		}

		$$->asmCode += $3->asmCode;
		for(int i = $3->args.size()-1; i >= 0; i--){
			$$->asmCode += "POP AX\n";
			$$->asmCode += "MOV "+sym->params[i]->varName+", AX\n";
		}
		$$->asmCode += "CALL "+sym->getName()+"\n";
		if(sym->getID_type() == "int"){
			$$->asmCode += "MOV CX,RET_VAR\n";
			$$->asmCode += "PUSH CX\n";
		}
		//args.clear();
	}
    | LPAREN expression RPAREN{
		prLine(); logfile << "factor : LPAREN expression RPAREN" << endl << endl;
		$$ = prCode("("+$2->getName()+")","factor");
		$$->setID_type($2->getID_type());
		$$->asmCode += $2->asmCode;
	}
    | CONST_INT{
		prLine(); logfile << "factor : CONST_INT" << endl << endl;
		$$ = prCode($1->getName(),"factor");
		$$->setID_type("int");

		$$->asmCode += "MOV AX, "+$1->getName()+"\n";
		$$->asmCode += "PUSH AX\n";

	}
    | CONST_FLOAT{
		prLine(); logfile << "factor : CONST_FLOAT" << endl << endl;
		$$ = prCode($1->getName(),"factor");
		$$->setID_type("float");
	}
    | variable INCOP{
		prLine(); logfile << "factor : variable INCOP" << endl << endl;
		$$ = prCode($1->getName()+"++","factor");
		if(var_error == 0){
			$$->setID_type($1->getID_type());
			var_error = 1;
		}
		else {
			$$->setID_type("int");
		}

		$$->asmCode += $1->asmCode;
		if($1->getSize() == 0){
			//$$->asmCode += "INC "+$1->varName+"\n";
			$$->asmCode += "PUSH "+$1->varName+"\n";
		}
		else{
			$$->asmCode += "POP AX\n";
			$$->asmCode += "MOV BX, 2\n";
			$$->asmCode += "MUL BX\n";
			$$->asmCode +="MOV SI, AX\n";
			//$$->asmCode += "INC "+$1->varName+"[SI]\n";
			$$->asmCode += "PUSH "+$1->varName+"[SI]\n";
		}
		$$->inc_ops.push_back({$1->varName,"INC"});
	}
       | variable DECOP{
		prLine(); logfile << "factor : variable DECOP" << endl <<endl;
		$$ = prCode($1->getName()+"--","factor");
		if(var_error == 0){
			$$->setID_type($1->getID_type());
			var_error = 1;
		}
		else {
			$$->setID_type("int");
		}

		$$->asmCode += $1->asmCode;
		if($1->getSize() == 0){
			//$$->asmCode += "DEC "+$1->varName+"\n";
			$$->asmCode += "PUSH "+$1->varName+"\n";
		}
		else{
			$$->asmCode += "POP AX\n";
			$$->asmCode += "MOV BX, 2\n";
			$$->asmCode += "MUL BX\n";
			$$->asmCode +="MOV SI, SX\n";
			//$$->asmCode += "DEC "+$1->varName+"+[SI]\n";
			$$->asmCode += "PUSH "+$1->varName+"+[SI]\n";
		}
		$$->inc_ops.push_back({$1->varName,"DEC"});
	}
       ;

argument_list : arguments{
	      		prLine(); logfile << "argument_list : arguments" << endl << endl;
	      		$$ = prCode($1->getName(),"argument_list");
				for(int i = 0; i < $1->args.size(); i++) $$->args.push_back($1->args[i]);

				$$->asmCode += $1->asmCode;
	      }
	      | {
	      		prLine(); logfile << "argument_list : " << endl<< endl;
	      		$$ = prCode("","argument_list");
	      }
	      ;
	      
arguments : arguments COMMA logic_expression{
	  	prLine(); logfile << "arguments : arguments COMMA logic_expression" << endl << endl;
	  	$$ = prCode($1->getName()+","+$3->getName(),"arguments");
	  	SymbolInfo* sym = new SymbolInfo($3);
		for(int i = 0; i < $1->args.size(); i++) $$->args.push_back($1->args[i]);
	  	$$->args.push_back(sym);
		
		$$->asmCode += $1->asmCode + $3->asmCode;
	  }
	  | logic_expression{
	  	prLine(); logfile << "arguments : logic_expression" << endl<< endl;
	  	$$ = prCode($1->getName(),"arguments");
	  	
	  	SymbolInfo* sym = new SymbolInfo($1);
	  	$$->args.push_back(sym);

		$$->asmCode += $1->asmCode;
	  }
	  ;
%%

int main(int argc, char *argv[]){
	/*if(argc != 2){
		cout << "please provide input file name"<<endl;
		return 0;
	}*/
	
	//FILE *file = fopen(argv[1],"r");
	FILE *file = fopen("input.c","r");
	if(file == NULL){
		cout << "ERROR!"<<endl;
		return 0;
	}
	fileInit();
	yyin = file;
	yyparse();
	logfile << "Total lines : "<< line_count<<" \nTotal errors : "<< error_count<< endl;
	fclose(yyin);
	fileClose();
	return 0;
}
