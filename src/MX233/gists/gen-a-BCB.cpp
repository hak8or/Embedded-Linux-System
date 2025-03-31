// This file will create the 512 byte BCB config block that must be located
//   at the last block of the SD card when booting from SD with BCB.
//   This is for STMP378x or i.MX233 BCB boot creation.
//   You can use dd in Linux to wriet this one out to the SD card.

#include <stdio.h>

// NEVER CHANGE ANY OF THE FOLLOWING:
#define CONFIG_BLOCK_SIGNATURE 0x00112233 // This MUST be bcb_config[0] 
#define CONFIG_BLOCK_VERSION   0x1        // This must be bcb_config[1]
#define BOOTIMAGE_TAG          0x50       // This is the boot image tag ROM looks
                                          //  to decide where to start booting.
#define NUM_DRIVES             0x4        // not really used by the ROM.

// The following defines may need to be changed.

// Image Start Block
// Change this number to the starting sector of the boot image.
#define IMAGE_START_BLOCK 2048 // 2048th sector

FILE *f1;

void main(void)
{
  unsigned int i, dat = CONFIG_BLOCK_SIGNATURE, NUM_WORDS_WRITTEN;
   f1 = fopen ("bcb_512.cfg", "wt");

   fwrite(&dat, sizeof(dat), 1, f1); // 1st byte is signature.
   
   dat = CONFIG_BLOCK_VERSION;
   fwrite(&dat, sizeof(dat), 1, f1); // 2nd byte is version.
   
   dat = NUM_DRIVES;
   fwrite(&dat, sizeof(dat), 1, f1);

   // Go ahead and write another couple  dummy words, ROM won't use anyways...
   fwrite(&dat, sizeof(dat), 1, f1);
   fwrite(&dat, sizeof(dat), 1, f1);

   // Now write the sector where the actual boot image will be.
   dat = IMAGE_START_BLOCK;
   fwrite(&dat, sizeof(dat), 1, f1);

   // Now we can write the boot tag ROM will be looking for.
   dat = BOOTIMAGE_TAG;
   fwrite(&dat, sizeof(dat), 1, f1);
   fwrite(&dat, sizeof(dat), 1, f1);
   fwrite(&dat, sizeof(dat), 1, f1);
   fwrite(&dat, sizeof(dat), 1, f1);

   dat = 0xDEADBEEF;
   fwrite(&dat, sizeof(dat), 1, f1);

   NUM_WORDS_WRITTEN = 11; // number of times called fwrite.
   
   // Need to make the .cfg file 512 bytes long, so...
   for(i=0; i < ((512/4) - NUM_WORDS_WRITTEN); i++){
	   fwrite(&i, sizeof(i), 1, f1);
   }

   fclose (f1);
}

/*
Contents of BCD written to SD card in the last partition/sector.
00000000  33 22 11 00 01 00 00 00  04 00 00 00 04 00 00 00  |3"..............|
00000010  04 00 00 00 00 08 00 00  50 00 00 00 50 00 00 00  |........P...P...|
00000020  50 00 00 00 50 00 00 00  ef be ad de 00 00 00 00  |P...P...........|
00000030  01 00 00 00 02 00 00 00  03 00 00 00 04 00 00 00  |................|
00000040  05 00 00 00 06 00 00 00  07 00 00 00 08 00 00 00  |................|
00000050  09 00 00 00 0a 00 00 00  0b 00 00 00 0c 00 00 00  |................|
00000060  0d 00 00 00 0e 00 00 00  0f 00 00 00 10 00 00 00  |................|
00000070  11 00 00 00 12 00 00 00  13 00 00 00 14 00 00 00  |................|
00000080  15 00 00 00 16 00 00 00  17 00 00 00 18 00 00 00  |................|
00000090  19 00 00 00 1a 00 00 00  1b 00 00 00 1c 00 00 00  |................|
000000a0  1d 00 00 00 1e 00 00 00  1f 00 00 00 20 00 00 00  |............ ...|
000000b0  21 00 00 00 22 00 00 00  23 00 00 00 24 00 00 00  |!..."...#...$...|
000000c0  25 00 00 00 26 00 00 00  27 00 00 00 28 00 00 00  |%...&...'...(...|
000000d0  29 00 00 00 2a 00 00 00  2b 00 00 00 2c 00 00 00  |)...*...+...,...|
000000e0  2d 00 00 00 2e 00 00 00  2f 00 00 00 30 00 00 00  |-......./...0...|
000000f0  31 00 00 00 32 00 00 00  33 00 00 00 34 00 00 00  |1...2...3...4...|
00000100  35 00 00 00 36 00 00 00  37 00 00 00 38 00 00 00  |5...6...7...8...|
00000110  39 00 00 00 3a 00 00 00  3b 00 00 00 3c 00 00 00  |9...:...;...<...|
00000120  3d 00 00 00 3e 00 00 00  3f 00 00 00 40 00 00 00  |=...>...?...@...|
00000130  41 00 00 00 42 00 00 00  43 00 00 00 44 00 00 00  |A...B...C...D...|
00000140  45 00 00 00 46 00 00 00  47 00 00 00 48 00 00 00  |E...F...G...H...|
00000150  49 00 00 00 4a 00 00 00  4b 00 00 00 4c 00 00 00  |I...J...K...L...|
00000160  4d 00 00 00 4e 00 00 00  4f 00 00 00 50 00 00 00  |M...N...O...P...|
00000170  51 00 00 00 52 00 00 00  53 00 00 00 54 00 00 00  |Q...R...S...T...|
00000180  55 00 00 00 56 00 00 00  57 00 00 00 58 00 00 00  |U...V...W...X...|
00000190  59 00 00 00 5a 00 00 00  5b 00 00 00 5c 00 00 00  |Y...Z...[...\...|
000001a0  5d 00 00 00 5e 00 00 00  5f 00 00 00 60 00 00 00  |]...^..._...`...|
000001b0  61 00 00 00 62 00 00 00  63 00 00 00 64 00 00 00  |a...b...c...d...|
000001c0  65 00 00 00 66 00 00 00  67 00 00 00 68 00 00 00  |e...f...g...h...|
000001d0  69 00 00 00 6a 00 00 00  6b 00 00 00 6c 00 00 00  |i...j...k...l...|
000001e0  6d 00 00 00 6e 00 00 00  6f 00 00 00 70 00 00 00  |m...n...o...p...|
000001f0  71 00 00 00 72 00 00 00  73 00 00 00 74 00 00 00  |q...r...s...t...|
*/
