%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "music.tab.h"

extern int yylex();
void yyerror(const char *s);
%}

%%
[A-G][#b]?                   { strcpy(yylval.note, yytext); return NOTE; }
"maj"|"min"|"7"|"dim"        { strcpy(yylval.chord_type, yytext); return CHORD_TYPE; }
[0-9]+(\.[0-9]+)?           { yylval.duration = atof(yytext); return DURATION; }
[ \t\n]                      ; /* Skip whitespace */
.                           { printf("Invalid character: %s\n", yytext); }
%%

