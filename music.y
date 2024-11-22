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
void play_sound_stretched(const char *note, const char *type, float duration);

// Scale definitions
const char *major_scale[] = {"C", "D", "E", "F", "G", "A", "B"};
const char *minor_scale[] = {"C", "D", "Eb", "F", "G", "Ab", "Bb"};

typedef struct {
    char note[3];
    char type[5];
    float duration;
} MusicChord;
%}

%union {
    char note[3];
    char chord_type[5];
    float duration;
}

%token <note> NOTE
%token <chord_type> CHORD_TYPE
%token <duration> DURATION

%%

chord_sequence: chord_item
              | chord_sequence chord_item
              ;

chord_item: NOTE CHORD_TYPE DURATION {
    if (!is_valid_chord($1, $2)) {
        yyerror("Invalid chord in the scale");
    } else {
        play_sound_stretched($1, $2, $3);
    }
}
;

%%

// WAV file header structure
#pragma pack(push, 1)
typedef struct {
    char riff_header[4];
    int wav_size;
    char wave_header[4];
    char fmt_header[4];
    int fmt_chunk_size;
    short audio_format;
    short num_channels;
    int sample_rate;
    int byte_rate;
    short sample_alignment;
    short bit_depth;
    char data_header[4];
    int data_bytes;
} WavHeader;
#pragma pack(pop)

void play_sound_stretched(const char *note, const char *type, float duration) {
    char filename[256];
    snprintf(filename, sizeof(filename), "sounds/%s%s.wav", note, type);
    
    FILE *file = fopen(filename, "rb");
    if (!file) {
        printf("Error opening file: %s\n", filename);
        return;
    }

    // Read WAV header
    WavHeader header;
    fread(&header, sizeof(WavHeader), 1, file);

    // Calculate original duration
    float original_duration = (float)header.data_bytes / header.byte_rate;
    float stretch_ratio = duration / original_duration;

    // Create temporary filename for stretched audio
    char temp_filename[256];
    snprintf(temp_filename, sizeof(temp_filename), "temp_%s%s_%.2f.wav", note, type, duration);

    // Use SoX for time stretching (requires sox to be installed)
    char command[512];
    snprintf(command, sizeof(command), 
             "sox \"%s\" \"%s\" tempo %f",
             filename, temp_filename, 1.0/stretch_ratio);
    
    system(command);

    // Play the stretched file
    if (PlaySound(temp_filename, NULL, SND_FILENAME | SND_SYNC) == 0) {
        printf("Error playing stretched sound file\n");
    }

    // Clean up temporary file
    remove(temp_filename);
    fclose(file);
}

int is_valid_chord(const char *note, const char *type) {
    const char **current_scale = major_scale;
    int scale_size = 7;

    for (int i = 0; i < scale_size; i++) {
        if (strcmp(note, current_scale[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    printf("Music Box Compiler with Time Stretching\n");
    printf("Enter chords with duration (e.g., C maj 2.5, D min 1.0):\n");
    printf("Format: NOTE TYPE DURATION\n");

    yyparse();
    return 0;
}

int yywrap() {
    return 1;
}
