#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <windows.h>

#define MAX_CHORD_LENGTH 3
#define MAX_SEQUENCE_LENGTH 100
#define NUM_SCALES 7

// Structure to represent a chord
typedef struct {
    char root;
    int duration;
    int is_minor;
} MusicChord; // Renamed from Chord to MusicChord

// Structure to represent a musical scale
typedef struct {
    char name[20];
    char chords[7];
    int has_minor[7];
} Scale;

// Global scales definition
Scale scales[NUM_SCALES] = {
    {"C Major", {'C', 'D', 'E', 'F', 'G', 'A', 'B'}, {0, 1, 1, 0, 0, 1, 1}},
    {"G Major", {'G', 'A', 'B', 'C', 'D', 'E', 'F'}, {0, 1, 1, 0, 0, 1, 1}},
    // Add more scales as needed
};

MusicChord parse_chord(const char* chord_str); // Updated return type
int validate_chord_in_scale(MusicChord chord, Scale scale); // Updated parameter type
void play_chord(MusicChord chord); // Updated parameter type
Scale* detect_scale(MusicChord* sequence, int length); // Updated parameter type
void suggest_replacement(MusicChord chord, Scale scale); // Updated parameter type

// Parse a chord string into a MusicChord structure
MusicChord parse_chord(const char* chord_str) {
    MusicChord chord;
    chord.root = chord_str[0];
    chord.is_minor = (chord_str[1] == 'm');
    
    if (chord.is_minor && strlen(chord_str) > 2) {
        chord.duration = atoi(&chord_str[2]);
    } else if (!chord.is_minor && strlen(chord_str) > 1) {
        chord.duration = atoi(&chord_str[1]);
    } else {
        chord.duration = 1; 
    }
    
    return chord;
}

// Check if a chord belongs to a scale
int validate_chord_in_scale(MusicChord chord, Scale scale) {
    for (int i = 0; i < 7; i++) {
        if (scale.chords[i] == chord.root) {
            if (chord.is_minor == scale.has_minor[i]) {
                return 1;
            }
        }
    }
    return 0;
}

// Play the chord sound using system audio
void play_chord(MusicChord chord) {
    char sound_file[100];
    sprintf(sound_file, "sounds/%c%s.wav", 
            chord.root, 
            chord.is_minor ? "m" : "");

    // Use PlaySound to play the sound
    PlaySound(sound_file, NULL, SND_FILENAME | SND_ASYNC); // Play asynchronously
    printf("Playing chord %c%s for %d seconds\n", 
           chord.root, 
           chord.is_minor ? "m" : "", 
           chord.duration);
    
    Sleep(chord.duration * 1000); // Simulate playing for the specified duration
}
// Detect the most likely scale for a sequence of chords
Scale* detect_scale(MusicChord* sequence, int length) {
    int max_matches = 0;
    Scale* best_scale = NULL;
    
    for (int i = 0; i < NUM_SCALES; i++) {
        int matches = 0;
        for (int j = 0; j < length; j++) {
            if (validate_chord_in_scale(sequence[j], scales[i])) {
                matches++;
            }
        }
        if (matches > max_matches) {
            max_matches = matches;
            best_scale = &scales[i];
        }
    }
    
    return best_scale;
}

// Suggest replacement for invalid chord
void suggest_replacement(MusicChord chord, Scale scale) {
    printf("Chord %c%s is not in the scale %s\n", 
           chord.root, 
           chord.is_minor ? "m" : "", 
           scale.name);
    
    printf("Suggested replacements:\n");
    for (int i = 0; i < 7; i++) {
        if (scale.has_minor[i] == chord.is_minor) {
            printf("- %c%s\n", scale.chords[i], chord.is_minor ? "m" : "");
        }
    }
}

int main() {
    char input[1000];
    MusicChord sequence[MAX_SEQUENCE_LENGTH]; // Updated variable type
    int sequence_length = 0;
    
    printf("Enter chord sequence (space-separated, e.g., 'C Em G7 Am'):\n");
    fgets(input, sizeof(input), stdin);
    
    // Parse input into chord sequence
    char* token = strtok(input, " \n");
    while (token != NULL && sequence_length < MAX_SEQUENCE_LENGTH) {
        sequence[sequence_length++] = parse_chord(token);
        token = strtok(NULL, " \n");
    }
    
    // Detect scale
    Scale* detected_scale = detect_scale(sequence, sequence_length);
    if (detected_scale == NULL) {
        printf("Could not detect a consistent scale.\n");
        return 1;
    }
    
    printf("Detected scale: %s\n", detected_scale->name);
    
    // Validate and play sequence
    int valid = 1;
    for (int i = 0; i < sequence_length; i++) {
        if (!validate_chord_in_scale(sequence[i], *detected_scale)) {
            valid = 0;
            suggest_replacement(sequence[i], *detected_scale);
        }
    }
    
    if (valid) {
        printf("Compilation successful! Playing sequence...\n");
        for (int i = 0; i < sequence_length; i++) {
            play_chord(sequence[i]);
        }
    } else {
        printf("Compilation failed due to scale violations.\n");
    }
    
    return 0;
}
