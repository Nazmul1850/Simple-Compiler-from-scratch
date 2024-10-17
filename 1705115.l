%option noyywrap

%x STRING_STATE
%x STRING_CONT
%x SINGLE_COMMENT
%x NEXT_LINE
%x MULTI_COMMENT
%x CHAR_ERROR

%{
#include<iostream>
#include"s_table.cpp"
#include "y.tab.h"
using namespace std;

int error_count = 0;
int line_count = 0;
int comment_line;
extern ofstream logfile,errfile;
string s;

void tokenPrint1(string token){
    //tokenfile <<"<" <<token <<"> ";
}
void tokenPrint2(string token, string lexeme){
    //tokenfile << "<"<<token<<", "<<lexeme<<"> ";
}
void logPrint(string token, string lexeme){
	logfile<<"Line no "<<line_count+1 << " : Token <"<<token <<"> Lexeme "<< lexeme <<" found"<<endl;
	logfile << endl;
}
void stringPrint(string s,int line){
    string t = "";
    int pt = 0;
    for(int i = 0; i < s.length(); i++){
	if(s[i] == '\\'){
	    if(s[i+1] == '\n') {i++; continue;}
	    if(s[i+1] == 'b'){t += '\b';}
	    else if(s[i+1] == 't') {t += '\t';}
	    else if(s[i+1] == 'n') {t += '\n';}
	    else if(s[i+1] == 'f') {t += '\f';}
	    else if(s[i+1] == 'r') {t += '\r';}
	    else if(s[i+1] == '"') {t += '"';}
	    else if(s[i+1] == '\'') {t += '\'';}
	    else if(s[i+1] == '\\') {t += '\\';}
	    else if(s[i+1] == 'a') {t += '\a';}
	    else if(s[i+1] == 'v') {t += '\v';}
	    else if(s[i+1] == '0') {t += '\0';}
	    else t += s[i+1];
	    i++;
	}
	else t += s[i];
    }
    logfile<<"Line no "<<line << " : Token < STRING> Lexeme "<< s <<" found ----> <STRING, "<<t<<">" <<endl<<endl;
    tokenPrint2("STRING",t);
}
void charPrint(string s){
   string t = "";
   if(s.compare("'\\b'") == 0){t += '\b';}
   else if(s.compare("'\\t'")== 0) {t += '\t';}
   else if(s.compare("'\\n'") == 0) {t += '\n';}
   else if(s.compare("'\\f'") == 0) {t += '\f';}
   else if(s.compare("'\\r'") == 0) {t += '\r';}
   else if(s.compare("'\\\''") == 0) {t += '\'';}
   else if(s.compare("\'\\\'") == 0) {t += '\\';}
   else if(s.compare("'\\a'") == 0) {t += '\a';}
   else if(s.compare("'\\v'") == 0) {t += '\v';}
   else if(s.compare("'\\0'") == 0) {t += '\0';}
   cout << t << endl;
   logfile<<"Line no "<<line_count+1 << " : Token <CONST_CHAR> Lexeme "<< s <<" found ----> <CONST_CHAR, "<<t<<">" <<endl;
   logfile << endl;
   tokenPrint2("CONST_CHAR",t);
}
void printError(string type,int line = line_count + 1){
    logfile << "Error at line no "<<line <<" : "<<type<<endl<<endl;
    errfile << "Error at line no "<<line <<" : "<<type<<endl<<endl;
}
%}

Letter [a-zA-z]
digit [0-9]

%%
"if" 		{return IF;}
"else" 	{return ELSE;}
"for" 		{return FOR;}
"while" 	{return WHILE;}
"do" 		{return DO;}
"break" 	{return BREAK;}
"int" 		{return INT;}
"char" 	{return CHAR;}
"float" 	{return FLOAT;}
"double" 	{return DOUBLE;}
"void" 	{return VOID;}
"return" 	{return RETURN;}
"switch" 	{return SWITCH;}
"case" 	{return CASE;}
"default" 	{return DEFAULT;}
"continue" 	{return CONTINUE;}
"println" 	{return PRINTLN;}
[+-] 		{
		SymbolInfo *sym = new SymbolInfo(yytext,"ADDOP");
		yylval.symbol = sym;
		return ADDOP;
		}
[*/%] 		{
		SymbolInfo *sym = new SymbolInfo(yytext,"MULOP");
		yylval.symbol = sym;
		return MULOP;
		}
\+\+ 		{return INCOP;}
\-\- 		{return DECOP;}
\<|\<\=|\>|\>\=|\=\=|\!\= {
		SymbolInfo *sym = new SymbolInfo(yytext,"RELOP");
		yylval.symbol = sym;
		return RELOP;
		}
= 		{return ASSIGNOP;}
&&|\|\| 	{
		SymbolInfo *sym = new SymbolInfo(yytext,"LOGICOP");
		yylval.symbol = sym;
		return LOGICOP;
		}
! 		{return NOT;}
\( 		{return LPAREN;}
\) 		{return RPAREN;}
\{ 		{return LCURL;}
\} 		{return RCURL;}
\[ 		{return LTHIRD;}
\] 		{return RTHIRD;}
, 		{return COMMA;}
; 		{return SEMICOLON;}
[0-9][0-9]* 	{
		SymbolInfo *sym = new SymbolInfo(yytext,"CONST_INT");
		yylval.symbol = sym;
		return CONST_INT;					
		}
{digit}+(\.{digit}*)?(E(-)?{digit}+)? {
		SymbolInfo *sym = new SymbolInfo(yytext,"CONST_FLOAT");
		yylval.symbol = sym;
		return CONST_FLOAT;
		}
'(\\[nt\\afrbv0\'])' {
		SymbolInfo *sym = new SymbolInfo(yytext,"CONST_CHAR");
		yylval.symbol = sym;
		return CONST_CHAR;
		}
'[^\n\\]' 	{
		SymbolInfo *sym = new SymbolInfo(yytext,"CONST_CHAR");
		yylval.symbol = sym;
		return CONST_CHAR;
		}
[a-zA-Z_]+[a-zA-Z0-9_]* {
		SymbolInfo *sym = new SymbolInfo(yytext,"ID");
		yylval.symbol = sym;
		return ID;	
		}
(\") {BEGIN STRING_STATE;comment_line = line_count+1; s = ""; s += yytext;}
<STRING_STATE>(\\) {s += yytext; BEGIN STRING_CONT;}
<STRING_CONT>[\n] {s += yytext; line_count++; BEGIN STRING_STATE;}
<STRING_CONT>[^\n] {s += yytext; BEGIN STRING_STATE;}
<STRING_STATE>[\n] {line_count++;error_count++; printError("Unterminated String "+s,line_count); BEGIN INITIAL;}
<STRING_STATE>(\\\") {s += yytext;}
<STRING_STATE>(\") {s += yytext; stringPrint(s,comment_line); BEGIN INITIAL;}
<STRING_STATE>(.) {s += yytext;}
\/\/ {s = "//"; logfile<<"Line no "<<line_count+1 << " : Token <COMMENT> Lexeme "; BEGIN SINGLE_COMMENT;}
<SINGLE_COMMENT>[\n] {line_count++; logfile << s <<" found"<<endl; BEGIN INITIAL;}
<SINGLE_COMMENT>\\ {s += yytext; BEGIN NEXT_LINE;}
<NEXT_LINE>[\n] {line_count++; s += yytext; BEGIN SINGLE_COMMENT;}
<NEXT_LINE>[^\n] {s += yytext; BEGIN SINGLE_COMMENT;}
<SINGLE_COMMENT>[^\n] {s += yytext;}
\/\* {s = "/*"; comment_line = line_count + 1; BEGIN MULTI_COMMENT;}
<MULTI_COMMENT><<EOF>> {error_count++; logfile << "Error at line no "<<comment_line <<" : "<<"Unterminated comment " << s<<" found"<<endl<<endl; return 0;}
<MULTI_COMMENT>\*\/ {s += "*/"; logfile<<"Line no "<<comment_line << " : Token <COMMENT> Lexeme " << s <<endl; BEGIN INITIAL;}
<MULTI_COMMENT>[\n] {line_count++; s += yytext;}
<MULTI_COMMENT>[^\n] {s += yytext;}
[-]?{digit}+([.]{digit}+)+ {s = "Too many decimal points "; s+=yytext; error_count++; printError(s);}
[-]?{digit}+(\.{digit}+)?[E]{digit}+[.]{digit}+ {s = "Ill formed numebr "; s += yytext; error_count++; printError(s);}
{digit}+[a-zA-Z_]* {s = "Invalid prefix on ID or invalid suffix on Number "; error_count++; printError(s + yytext);}
\'\' {error_count++; printError("Empty character constant error \'\'");}
\'[^\n][^\n]+' {error_count++; s = yytext; printError("Multi character constant error"+s); BEGIN INITIAL;}
\' {s = "\'"; error_count++; BEGIN CHAR_ERROR;}
<CHAR_ERROR>[\n] {line_count++; printError("Unterminated character"+s);  BEGIN INITIAL;}
<CHAR_ERROR>[^\n] {s += yytext;}

[\n] {line_count++;} //newline
[ \t\v]+ {}//white space

<<EOF>> { return 0;}
. {error_count++; s = yytext;printError("Unrecognized character "+s);}
%%


