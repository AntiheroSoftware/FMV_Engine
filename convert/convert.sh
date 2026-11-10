#!/bin/bash

# convert 16:9 -> 4:3 (crop)
# ffmpeg -i input.mp4 -vf "crop=ih*4/3:ih,scale=256:192" -c:v libx264 -crf 23 -c:a aac output_256x192.mp4

#MOVIE_TO_CONVERT="/project/movies/big_buck_bunny_480p_h264.mov"
MOVIE_TO_CONVERT="/project/movies/Dragons_lair_intro.mp4"
#MOVIE_TO_CONVERT="/project/movies/T2_Truck_chase.mp4"
MSU_FILE="/project/convert/msu1-fmv.msu"
TMP_PATH="/project/convert/tmp"
CONVERTED_PATH="/project/convert/converted"

dump_word_filesize() {
	local filesize=$1
	# TODO check that size is not bigger than $FFFF
	echo -en $( printf '\\x%x' "$((filesize & 0xff))" "$((filesize >> 8 & 0xff))" )'' >> $MSU_FILE
}

dump_data_from_file() {
	local file_full_path=$1
	cat $file_full_path >> $MSU_FILE
}

rm -f $MSU_FILE
mkdir -p $TMP_PATH
mkdir -p $CONVERTED_PATH
ffmpeg -i $MOVIE_TO_CONVERT -vf "yadif,crop=ih*4/3:ih,fps=24000/1001,scale=256:192" $TMP_PATH/frame%06d.png

FILES="$TMP_PATH/frame*.png"
for f in $FILES
do
  echo "Processing $f file..."
  filename="$(basename ${f})"
  basename="${filename%.*}"

  echo "Converting & Quantitize image to tiles and palettes (and quantified image) ..."
  superfamiconv convert \
	-i ${f} \
	-p $CONVERTED_PATH/${basename}_quant.pal \
	-t $CONVERTED_PATH/${basename}_quant.chr \
  --img $CONVERTED_PATH/${basename}_quant.png \
	-W 8 -H 8 -B 4 \
  -C 16 -N 8 -Z 000000 -Q --dither off 

  # Force palette to be 256 bytes (pal should always be 256 bytes)
  truncate -s 256 $CONVERTED_PATH/${basename}_quant.pal

  # Convert the map appart because it's buggy with convert
  echo "Converting image to map ..."
  superfamiconv map \
	-i $CONVERTED_PATH/${basename}_quant.png \
	-p $CONVERTED_PATH/${basename}_quant.pal \
	-t $CONVERTED_PATH/${basename}_quant.chr \
	-d $CONVERTED_PATH/${basename}_quant.map \
	-W 8 -H 8 -B 4 --map-width 32 --map-height 24

  pal_filesize=$(wc -c < $CONVERTED_PATH/${basename}_quant.pal)
  map_filesize=$(wc -c < $CONVERTED_PATH/${basename}_quant.map)
  tile_filesize=$(wc -c < $CONVERTED_PATH/${basename}_quant.chr)

  echo "Writing size data for tiles, map and palettes ..."
  dump_word_filesize $tile_filesize
  
  echo "Writing tile data [$tile_filesize/$(printf "0x%04X"  $tile_filesize )] ..."
  dump_data_from_file $CONVERTED_PATH/${basename}_quant.chr

  echo "Writing map data [$map_filesize/$(printf "0x%04X"  $map_filesize )] ..."
  dump_data_from_file $CONVERTED_PATH/${basename}_quant.map

  echo "Writing palette data [$pal_filesize/$(printf "0x%04X"  $pal_filesize )] ..."
  dump_data_from_file $CONVERTED_PATH/${basename}_quant.pal

  # Clean tmp file
  rm $CONVERTED_PATH/${basename}_quant.*
  rm ${f}

done

echo "Writing size 0 to end the video."
dump_word_filesize 0

rm -rf $TMP_PATH
rm -rf $CONVERTED_PATH

# hexdump $MSU_FILE | head 

