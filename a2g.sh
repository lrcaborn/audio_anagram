#!/bin/bash

SOX=/usr/local/bin/sox
SOXI=/usr/local/bin/soxi
STARTING_DIR=`pwd`
INPUT_DIR_TEMPLATE="$STARTING_DIR/_input"
OUTPUT_DIR_TEMPLATE="/tmp/a2g/_output"

# DEFAULT_SEGMENT_LENGTH is how long each segment is that will be stitched together later.
# INCREMENT is how far ahead to jump to pull the next segment.
# These don't have to be equal. There will be some repetition, but this is creativity.
# You're allowed to break whatever rules you imagine there to be.

# splitting by samples
DEFAULT_SEGMENT_LENGTH=15000
INCREMENT=15000

# splitting by seconds
#DEFAULT_SEGMENT_LENGTH=0.4
#INCREMENT=0.25

# Create a subdirectory for specifying the location of the input files and for holding the output files.
SUB_DIR=quinnmusic
#SUB_DIR=reagan_speeches
#SUB_DIR=freesound
INPUT_DIR=$INPUT_DIR_TEMPLATE/$SUB_DIR
OUTPUT_DIR=$OUTPUT_DIR_TEMPLATE/$SUB_DIR

# Can't do anything if the input directory doesn't exist.
if [ ! -d "$INPUT_DIR" ]
then
	echo "Input directory ("$INPUT_DIR") does not exist."
	exit
fi

# We need to make sure that we're working with a clean output directory.
# First delete it, then recreate it.
if [ -d $OUTPUT_DIR ]
then
	rm -rf $OUTPUT_DIR
fi
mkdir -p "$OUTPUT_DIR"


# For now, I'm just working with one file.
# In time, this will be wrapped in a loop and we won't manually be setting the filename.
#FILENAME="spe_1983_0308_reagan.mp3"
FILENAME="Vivaldi - Spring from Four Seasons.mp3"
#FILENAME="263815__copyc4t__white-noise-down-sweep.flac"

# Add in a bit to pull the extension for possible reuse later.

INPUT_FILE=$INPUT_DIR/$FILENAME

LENGTH=`$SOXI -s "$INPUT_FILE"`


COUNTER=0
while [ $COUNTER -le $LENGTH ]
do
	COUNTER=`expr $COUNTER + $INCREMENT`
	SEGMENT_FILENAME=`uuidgen`.wav
	OUTPUT_FILE=$OUTPUT_DIR/$SEGMENT_FILENAME
	REMAINING_LENGTH=`expr $LENGTH - $COUNTER`

	echo -n "$COUNTER / $LENGTH, $REMAINING_LENGTH remaining, "

	if [ $REMAINING_LENGTH -ge $DEFAULT_SEGMENT_LENGTH ]
	then
		echo "using default segment"
		$SOX "$INPUT_FILE" $OUTPUT_FILE trim "$COUNTER"s "$DEFAULT_SEGMENT_LENGTH"s
	else
		echo "using remaining length ($REMAINING_LENGTH)"
		$SOX "$INPUT_FILE" $OUTPUT_FILE trim "$COUNTER"s "$REMAINING_LENGTH"s
		break
	fi

done


# just merge them together with no crossfade
$SOX "$OUTPUT_DIR"/* "$OUTPUT_DIR"/_merged.wav

# or concatenate them with some crossfading to soften out the attacks at the start of each file.
# TODO: play with the # of samples in the crossfade. optimize based on DEFAULT_SEGMENT_LENGTH and INCREMENT
$SOX --combine concatenate "$OUTPUT_DIR"/* "$OUTPUT_DIR"/_spliced.wav splice -q 10000s,5000s

#find "$OUTPUT_DIR" -name '*' -print0 | xargs -0

echo done.
