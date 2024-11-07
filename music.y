%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <windows.h>
#include <mmsystem.h>

#pragma comment(lib, "winmm.lib")

void yyerror(const char *s);
int yylex();
int is_valid_chord(const char *note, const char *type);
void play_sound(const char *note, const char *type);

// Scale definitions
const char *major_scale[] = {"C", "D", "E", "F", "G", "A", "B"};
const char *minor_scale[] = {"C", "D", "Eb", "F", "G", "Ab", "Bb"};

// Renamed from Chord to MusicChord to avoid conflict
typedef struct {
    char note[3];
    char type[5];
} MusicChord;
%}

%union {
    char note[3];
    char chord_type[5];
}

%token <note> NOTE
%token <chord_type> CHORD_TYPE

%%

// Updated grammar to allow continuous chords
chord_sequence: chord
             | chord_sequence chord
             ;

chord: NOTE CHORD_TYPE {
    if (!is_valid_chord($1, $2)) {
        yyerror("Invalid chord in the scale");
    } else {
        play_sound($1, $2);
    }
}
;

%%

int is_valid_chord(const char *note, const char *type) {
    // Check if the note is in the current scale
    const char **current_scale = major_scale; // Default to major scale
    int scale_size = 7;

    for (int i = 0; i < scale_size; i++) {
        if (strcmp(note, current_scale[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

void play_sound(const char *note, const char *type) {
    char filename[256];
    snprintf(filename, sizeof(filename), "sounds/%s%s.wav", note, type);

    // Play the WAV file using Windows multimedia
    if (PlaySound(filename, NULL, SND_FILENAME | SND_SYNC) == 0) {
        printf("Error playing sound file: %s\n", filename);
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    printf("Music Box Compiler\n");
    printf("Enter chords (e.g., C maj, D min):\n");

    yyparse();
    return 0;
}

int yywrap() {
    return 1;
}
