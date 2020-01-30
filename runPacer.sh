#!/bin/bash

# ------
#
# Create an array with all files in current directory and loop through them. 
# If file is mp3 then continue to next file
# Convert to mp3 if opus or ogg file format. Then convert to mono if file is 
# stereo, synthesis a 180 BPM metronome beat made of a 500 Hz carrier sinusoid 
# modulated in amplitude by a 3 Hz square wave, merge the sound file and 
# metronome beat, remove unnecessary files and add id3v2 tag to ease selection
#
# run as:
# 
# ./runPacer.sh
#
# ------

myfiles=(*.*)
counter=1
for iFile in "${myfiles[@]}"; do
	echo ${iFile}
	if (( `expr "${iFile}" : '.*\.mp3'` > 0 )); then
		echo "skipping " "${iFile}";
		continue
	fi
	if (( `expr "${iFile}" : '.*\.ogg'` > 0 )); then 
		echo "convert ogg to mp3";
		fileName="${iFile%.ogg}.mp3";
		sox "${iFile}" "$fileName";
	fi
	if (( `expr "${iFile}" : '.*\.opus'` > 0 )); then 
		echo "convert opus to mp3";
		fileName="${iFile%.opus}.mp3";
		opusdec --force-wav "${iFile}" - | sox - "$fileName"
	fi
	echo ${iFile:0:`expr "$iFile" : '.*\.'`}"mp3"
	sox "$fileName" "file1.mp3" remix 1
	sox -n -r `soxi -r file1.mp3` "output.mp3" synth `soxi -d file1.mp3` sine 500 vol 0.5 synth `soxi -d file1.mp3` square amod 3
	newFile=${fileName%.mp3}_beat.mp3
	sox -m "file1.mp3" "output.mp3" "$newFile"
	rm "$fileName";
	rm "output.mp3";
	rm "file1.mp3";
	id3v2 --TALB "Running cadence" "$newFile";
	id3v2 --TRCK $counter $newFile;
	let counter=counter+1
# 	echo "${iFile}" 
	echo "done"
done
