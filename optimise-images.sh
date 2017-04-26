#! /bin/bash
########################################################################
# batch optimise images
# written by George Liu (eva2000) centminmod.com
# docs
# https://www.imagemagick.org/Usage/thumbnails/
# https://www.imagemagick.org/script/command-line-options.php#define
# https://www.imagemagick.org/Usage/files/#write
# https://www.imagemagick.org/Usage/api/#scripts
# http://www.imagemagick.org/Usage/files/#massive
# http://www.imagemagick.org/script/architecture.php
# 
# webp
# http://caniuse.com/#feat=webp
# https://developers.google.com/speed/webp/
# https://www.imagemagick.org/script/webp.php
#
# test images
# https://testimages.org/
########################################################################
VER='0.8'
DEBUG='y'

# max width and height
MAXRES='2048'

IMAGICK_RESIZE='y'
IMAGICK_JPEGHINT='y'
IMAGICK_QUALITY='82'
IMAGICK_WEBP='n'
IMAGICK_WEBPQUALITY='75'
IMAGICK_WEBPMETHOD='4'
IMAGICK_WEBPLOSSLESS='n'
IMAGICK_TMPDIR='/home/imagicktmp'
IMAGICK_JPGOPTS=' -filter Triangle -define filter:support=2 -define jpeg:fancy-upsampling=off -unsharp 0.25x0.08+8.3+0.045'
IMAGICK_PNGOPTS=' -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=2'
IMAGICK_WEBPOPTS=" -define webp:method=${IMAGICK_WEBPMETHOD} -define webp:lossless=false -quality ${IMAGICK_WEBPQUALITY}"

# strip meta-data
STRIP='y'

# additional image optimisations after imagemagick
# resizing
OPTIPNG='y'
JPEGOPTIM='y'
ZOPFLIPNG='n'

# Speed control
# default is -o2 set 2
OPTIPNG_COMPRESSION='2'

# profile option display fields for transparency color and background color
# disabled by default to speed up profile processing
PROFILE_EXTEND='n'

# comparison mode when enabled will when resizing and optimising images
# write to a separate optimised image within the same directory as the
# original images but with a suffix attached to the end of original image
# file name i.e. image.png vs image_optimal.png
COMPARE_MODE='n'
COMPARE_SUFFIX='_optimal'

# optionally create thumbnails in separate directory
# within image directory and thumbnail width x height
# and thumbnail image format default = .jpg
THUMBNAILS='n'
THUMBNAILS_QUALITY='72'
THUMBNAILS_WIDTH='150'
THUMBNAILS_HEIGHT='150'
THUMBNAILS_FORMAT='jpg'
THUMBNAILS_DIRNAME='thumbnails'

########################################################################
# DO NOT EDIT BELOW THIS POINT

if [ -f /proc/user_beancounters ]; then
    CPUS=$(cat "/proc/cpuinfo" | grep "processor"|wc -l)
else
    # speed up make
    CPUS=$(cat "/proc/cpuinfo" | grep "processor"|wc -l)
fi

if [[ "$CPUS" -ge ' 4' ]]; then
  IMAGICK_THREADLIMIT=$(($CPUS/2))
  export MAGICK_THREAD_LIMIT="$IMAGICK_THREADLIMIT"
fi

if [ ! -f /usr/bin/bc ]; then
  yum -q -y install bc
fi

if [ ! -f /usr/bin/optipng ]; then
  yum -q -y install optipng
fi

if [ ! -f /usr/bin/jpegoptim ]; then
  yum -q -y install jpegoptim
fi

if [[ "$ZOPFLIPNG" = [yY] && ! -f /usr/bin/zopflipng ]]; then
  mkdir -p /opt/zopfli
  cd /opt/zopfli
  git clone https://github.com/google/zopfli
  cd zopfli/
  make -s -j2
  make -s zopflipng
  make -s libzopfli
  \cp -f zopflipng /usr/bin/zopflipng
  OPTIPNG='n'
elif [[ "$ZOPFLIPNG" = [yY] && -f /usr/bin/zopflipng ]]; then
  OPTIPNG='n'
fi

if [[ "$STRIP" = [Yy] ]]; then
  STRIP_OPT=' -strip'
else
  STRIP_OPT=""
fi

if [[ "$IMAGICK_JPEGHINT" = [yY] ]]; then
  JPEGHINT_WIDTH=$(($MAXRES*2))
  JPEGHINT_HEIGHT=$(($MAXRES*2))
  JPEGHINT_OPT=" -define jpeg:size=${JPEGHINT_WIDTH}x${JPEGHINT_HEIGHT}"
else
  JPEGHINT_OPT=""
fi

if [[ "$IMAGICK_WEBP" = [yY] ]]; then
  FIND_WEBP=' -o -name "*.webp"'
else
  FIND_WEBP=""
fi

if [[ "$IMAGICK_WEBPLOSSLESS" = [yY] ]]; then
  IMAGICK_WEBPOPTS=" -define webp:method=${IMAGICK_WEBPMETHOD} -define webp:lossless=true"
fi

if [ ! -d "$IMAGICK_TMPDIR" ]; then
  mkdir -p "$IMAGICK_TMPDIR"
  chmod 1777 "$IMAGICK_TMPDIR"
elif [ -d "$IMAGICK_TMPDIR" ]; then
  chmod 1777 "$IMAGICK_TMPDIR"
fi

IMAGICK_VERSION=$(convert -version | head -n1 | awk '/^Version:/ {print $2,$3,$4,$5,$6}')
##########################################################################
# function

testfiles() {
  WORKDIR=$1
  cd "$WORKDIR"
  wget -cnv -O mobile1.jpg https://github.com/centminmod/optimise-images/raw/master/images/mobile1.jpg
  wget -cnv -O mobile2.jpg https://github.com/centminmod/optimise-images/raw/master/images/mobile2.jpg
  wget -cnv -O mobile3.jpg https://github.com/centminmod/optimise-images/raw/master/images/mobile3.jpg
  wget -cnv -O image1.jpg https://github.com/centminmod/optimise-images/raw/master/images/image1.jpg
  wget -cnv -O image2.jpg https://github.com/centminmod/optimise-images/raw/master/images/image2.jpg
  wget -cnv -O image3.jpg https://github.com/centminmod/optimise-images/raw/master/images/image3.jpg
  wget -cnv -O image4.jpg https://github.com/centminmod/optimise-images/raw/master/images/image4.jpg
  wget -cnv -O image6.jpg https://github.com/centminmod/optimise-images/raw/master/images/image6.jpg
  wget -cnv -O image7.jpg https://github.com/centminmod/optimise-images/raw/master/images/image7.jpg
  wget -cnv -O image7.jpg https://github.com/centminmod/optimise-images/raw/master/images/image7.jpg
  wget -cnv -O dslr_canon_eos_m6_1.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_canon_eos_m6_1.jpg
  wget -cnv -O dslr_canon_eos_m6_large1.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_canon_eos_m6_large1.jpg
  wget -cnv -O dslr_canon_eos_m6_large2.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_canon_eos_m6_large2.jpg
  wget -cnv -O dslr_canon_eos_77d_1.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_canon_eos_77d_1.jpg
  wget -cnv -O dslr_canon_eos_77d_2.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_canon_eos_77d_2.jpg
  wget -cnv -O dslr_hasselblad_x1d_1.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_hasselblad_x1d_1.jpg
  wget -cnv -O dslr_hasselblad_x1d_2.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_hasselblad_x1d_2.jpg
  wget -cnv -O dslr_leica_m10_1.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_leica_m10_1.jpg
  wget -cnv -O dslr_leica_m10_2.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_leica_m10_2.jpg
  wget -cnv -O dslr_nikon_d5_1.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_nikon_d5_1.jpg
  wget -cnv -O dslr_nikon_d5_2.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_nikon_d5_2.jpg
  wget -cnv -O dslr_nikon_d7200_1.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_nikon_d7200_1.jpg
  wget -cnv -O dslr_nikon_d7200_2.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_nikon_d7200_2.jpg
  wget -cnv -O dslr_sony_alpha_a99_ii_1.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_sony_alpha_a99_ii_1.jpg
  wget -cnv -O dslr_sony_alpha_a99_ii_2.jpg https://github.com/centminmod/optimise-images/raw/master/images/dslr_sony_alpha_a99_ii_2.jpg
  wget -cnv -O samsung_s7_mobile_1.jpg https://github.com/centminmod/optimise-images/raw/master/images/samsung_s7_mobile_1.jpg
  cp image4.jpg "im age5.jpg"
  wget -cnv -O webp-study-source-firebreathing.png https://github.com/centminmod/optimise-images/raw/master/images/webp-study-source-firebreathing.png
  wget -cnv -O webp-study-source-google-chart-tools.png https://github.com/centminmod/optimise-images/raw/master/images/webp-study-source-google-chart-tools.png
  wget -cnv -O pngimage1.png https://github.com/centminmod/optimise-images/raw/master/images/pngimage1.png
  wget -cnv -O pngimage2.png https://github.com/centminmod/optimise-images/raw/master/images/pngimage2.png
  wget -cnv -O pngimage3.png https://github.com/centminmod/optimise-images/raw/master/images/pngimage3.png
  wget -cnv -O pngimage4.png https://github.com/centminmod/optimise-images/raw/master/images/pngimage4.png
  wget -cnv -O screenshot1.png https://github.com/centminmod/optimise-images/raw/master/images/screenshot1.png
  wget -cnv -O lenna.png https://github.com/centminmod/optimise-images/raw/master/images/lenna.png
  wget -cnv -O png24-image1.png https://github.com/centminmod/optimise-images/raw/master/images/png24-image1.png
  wget -cnv -O png24-interlaced-image1.png https://github.com/centminmod/optimise-images/raw/master/images/png24-interlaced-image1.png
}

profiler() {
  starttime=$(TZ=UTC date +%s.%N)
  {
  WORKDIR=$1
  echo
  echo "-------------------------------------------------------------------------"
  echo "image profile"
  if [[ "$PROFILE_EXTEND" = [yY] ]]; then
    echo "image name : width : height : quality : transparency : image depth (bits) : size : user: group : transparency color : background color"
  else
    echo "image name : width : height : quality : transparency : image depth (bits) : size : user: group"
  fi
  echo "-------------------------------------------------------------------------"
  echo "images in $WORKDIR"
  echo "-------------------------------------------------------------------------"
  cd "$WORKDIR"
  if [[ "$IMAGICK_WEBP" = [yY] && "$(ls "$WORKDIR" | grep '.webp')" ]]; then
    find "$WORKDIR" -maxdepth 1 -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" | sort | while read i; do
    file=$(basename "${i}")
    echo -n "image : "$file" : ";
    echo -n "$(identify -format '%w : %h : %Q : %A : %z :' "$file") ";
    if [[ "$PROFILE_EXTEND" = [yY] ]]; then
      echo -n "$(stat -c "%s : %U : %G" "$file") : ";
      echo -n "$(identify -verbose "$file" | awk '/Transparent color/ {print $3}') : ";
      echo "$(identify -verbose "$file" | awk '/Background color: / {print $3}')";
    else
      echo "$(stat -c "%s : %U : %G" "$file")";
    fi
    done
  else
    find "$WORKDIR" -maxdepth 1 -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" | sort | while read i; do
    file=$(basename "${i}")
    echo -n "image : "$file" : ";
    echo -n "$(identify -format '%w : %h : %Q : %A : %z :' "$file") ";
    if [[ "$PROFILE_EXTEND" = [yY] ]]; then
      echo -n "$(stat -c "%s : %U : %G" "$file") : ";
      echo -n "$(identify -verbose "$file" | awk '/Transparent color/ {print $3}') : ";
      echo "$(identify -verbose "$file" | awk '/Background color: / {print $3}')";
    else
      echo "$(stat -c "%s : %U : %G" "$file")";
    fi
    done
  fi

  echo
  echo "-------------------------------------------------------------------------"
  echo "average image width, height, image quality and size"
  echo "-------------------------------------------------------------------------"
  find "$WORKDIR" -maxdepth 1 -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" | grep -v "$COMPARE_SUFFIX" | sort | while read i; do echo -n "image : "$i" : ";
   echo -n "$(identify -format '%w : %h : %Q : %A : %z :' "$i") ";
   echo "$(stat -c "%s : %U : %G" "$i")";
  done  | awk -F " : " '{c3 += $3; c4 += $4; c5 += $5; c8 += $8} END {printf "%.0f %.0f %.0f %.0f\n", c3/NR, c4/NR, c5/NR, c8/NR}'

  if [[ "$COMPARE_MODE" = [yY] ]]; then
    if [[ "$(ls "$WORKDIR" | grep "$COMPARE_SUFFIX")" ]]; then
      echo
      echo "-------------------------------------------------------------------------"
      echo "Optimised Images: average image width, height, image quality and size"
      echo "-------------------------------------------------------------------------"
      find "$WORKDIR" -maxdepth 1 -name "*${COMPARE_SUFFIX}.jpg" -o -name "*${COMPARE_SUFFIX}.png" -o -name "*${COMPARE_SUFFIX}.jpeg" | sort | while read i; do echo -n "image : "$i" : ";
      echo -n "$(identify -format '%w : %h : %Q : %A : %z :' "$i") ";
      echo "$(stat -c "%s : %U : %G" "$i")";
      done  | awk -F " : " '{c3 += $3; c4 += $4; c5 += $5; c8 += $8} END {printf "%.0f %.0f %.0f %.0f\n", c3/NR, c4/NR, c5/NR, c8/NR}'
    fi
  fi

  if [[ "$IMAGICK_WEBP" = [yY] ]]; then
    if [[ "$(ls "$WORKDIR" | grep '.webp')" ]]; then
      echo
      echo "-------------------------------------------------------------------------"
      echo "Optimised WebP Images: average image width, height, image quality and size"
      echo "-------------------------------------------------------------------------"
      find "$WORKDIR" -maxdepth 1 -name "*.webp" | sort | while read i; do echo -n "image : "$i" : ";
      echo -n "$(identify -format '%w : %h : %Q : %A : %z :' "$i") ";
      echo "$(stat -c "%s : %U : %G" "$i")";
      done  | awk -F " : " '{c3 += $3; c4 += $4; c5 += $5; c8 += $8} END {printf "%.0f %.0f %.0f %.0f\n", c3/NR, c4/NR, c5/NR, c8/NR}'
    fi
  fi

  echo
  echo "-------------------------------------------------------------------------"
  find "$WORKDIR" -maxdepth 1 -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" | grep -v "$COMPARE_SUFFIX" | sort | while read i; do echo -n "image : "$i" : ";
   echo -n "$(identify -format '%w : %h : %Q : %A : %z :' "$i") ";
   echo "$(stat -c "%s : %U : %G" "$i")";
  done  | awk -F " : " '{c8 += $8} END {print "Total Images Size: "c8,"Bytes",c8/1024,"KB"}'
  echo "-------------------------------------------------------------------------"

  if [[ "$COMPARE_MODE" = [yY] ]]; then
    if [[ "$(ls "$WORKDIR" | grep "$COMPARE_SUFFIX")" ]]; then
      echo
      echo "-------------------------------------------------------------------------"
      find "$WORKDIR" -maxdepth 1 -name "*${COMPARE_SUFFIX}.jpg" -o -name "*${COMPARE_SUFFIX}.png" -o -name "*${COMPARE_SUFFIX}.jpeg" | sort | while read i; do echo -n "image : "$i" : ";
      echo -n "$(identify -format '%w : %h : %Q : %A : %z :' "$i") ";
      echo "$(stat -c "%s : %U : %G" "$i")";
      done  | awk -F " : " '{c8 += $8} END {print "Total Optimised Images Size: "c8,"Bytes",c8/1024,"KB"}'
      echo "-------------------------------------------------------------------------"
    fi
  fi

  if [[ "$IMAGICK_WEBP" = [yY] ]]; then
    if [[ "$(ls "$WORKDIR" | grep '.webp')" ]]; then
      echo
      echo "-------------------------------------------------------------------------"
      find "$WORKDIR" -maxdepth 1 -name "*.webp" | sort | while read i; do echo -n "image : "$i" : ";
      echo -n "$(identify -format '%w : %h : %Q : %A : %z :' "$i") ";
      echo "$(stat -c "%s : %U : %G" "$i")";
      done  | awk -F " : " '{c8 += $8} END {print "Total Optimised WebP Images Size: "c8,"Bytes",c8/1024,"KB"}'
      echo "-------------------------------------------------------------------------"
    fi
  fi
  echo
  echo "-------------------------------------------------------------------------"
  echo "ImageMagick Resource Limits"
  echo "-------------------------------------------------------------------------"
  echo "Version: $IMAGICK_VERSION"
  identify -list resource
  echo "-------------------------------------------------------------------------"
  }
  endtime=$(TZ=UTC date +%s.%N)
  processtime=$(echo "scale=2;$endtime - $starttime"|bc)
  echo "Completion Time: $(printf "%0.2f\n" $processtime) seconds"
  echo "-------------------------------------------------------------------------"
}

optimiser() {
  starttime=$(TZ=UTC date +%s.%N)
  {
  WORKDIR=$1
  echo
  echo "-------------------------------------------------------------------------"
  echo "image optimisation start"
  echo "-------------------------------------------------------------------------"
  cd "$WORKDIR"
  if [[ "$THUMBNAILS" = [yY] ]]; then
    mkdir -p "$THUMBNAILS_DIRNAME"
  fi
  find "$WORKDIR" -maxdepth 1 -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" | sort | while read i; do 
    file=$(basename "${i}")
    extension="${file##*.}"
    filename="${file%.*}"
    if [[ "$COMPARE_MODE" = [yY] ]]; then
      fileout="${filename}${COMPARE_SUFFIX}.${extension}"
    else
      fileout="$file"
    fi
    echo "### $file ($extension) ###"
    IS_INTERLACED=$(identify -verbose "${file}" | awk '/Interlace/ {print $2}')
    IS_TRANSPARENT=$(identify -format "%A" "${file}")
    IS_TRANSPARENTCOLOR=$(identify -verbose "${file}" | awk '/Transparent color/ {print $3}')
    IS_BACKGROUNDCOLOR=$(identify -verbose "${file}" | awk '/Background color: / {print $3}')
    if [[ "$IS_INTERLACED" = 'None' ]]; then
      INTERLACE_OPT=' -interlace none'
    else
      INTERLACE_OPT=""
    fi
    if [[ "$extension" = 'jpg' && "$IMAGICK_RESIZE" = [yY] && "$JPEGOPTIM" = [yY] ]] || [[ "$extension" = 'jpeg' && "$IMAGICK_RESIZE" = [yY] && "$JPEGOPTIM" = [yY] ]]; then
      if [[ "$THUMBNAILS" = [yY] ]]; then
        echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${JPEGHINT_OPT}${IMAGICK_JPGOPTS}${INTERLACE_OPT}${STRIP_OPT} \
        -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
        "mpr:$filename" -thumbnail '150x150>' -unsharp 0x.5 "${THUMBNAILS_DIRNAME}/${filename}.${THUMBNAILS_FORMAT}""
        convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${JPEGHINT_OPT}${IMAGICK_JPGOPTS}${INTERLACE_OPT}${STRIP_OPT} \
        -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
        "mpr:$filename" -thumbnail '150x150>' -unsharp 0x.5 "${THUMBNAILS_DIRNAME}/${filename}.${THUMBNAILS_FORMAT}"
      else
        if [[ "$IMAGICK_WEBP" = [yY] ]]; then
          echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${JPEGHINT_OPT}${IMAGICK_JPGOPTS}${INTERLACE_OPT}${STRIP_OPT} \
          -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
          "mpr:$filename"${IMAGICK_WEBPOPTS} -resize ${MAXRES}x${MAXRES}\> "${filename}.webp""
          convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${JPEGHINT_OPT}${IMAGICK_JPGOPTS}${INTERLACE_OPT}${STRIP_OPT} \
          -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
          "mpr:$filename"${IMAGICK_WEBPOPTS} -resize ${MAXRES}x${MAXRES}\> "${filename}.webp"
        else
          echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${JPEGHINT_OPT}${IMAGICK_JPGOPTS}${INTERLACE_OPT}${STRIP_OPT} -resize ${MAXRES}x${MAXRES}\> "${fileout}""
          convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${JPEGHINT_OPT}${IMAGICK_JPGOPTS}${INTERLACE_OPT}${STRIP_OPT} -resize ${MAXRES}x${MAXRES}\> "${fileout}"
        fi
      fi
    elif [[ "$extension" = 'png' && "$IMAGICK_RESIZE" = [yY] ]]; then
      if [[ "$THUMBNAILS" = [yY] ]]; then
        echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT}${IMAGICK_PNGOPTS} \
        -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
        "mpr:$filename" -thumbnail '150x150>' -unsharp 0x.5 "${THUMBNAILS_DIRNAME}/${filename}.${THUMBNAILS_FORMAT}""
        convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT}${IMAGICK_PNGOPTS} \
        -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
        "mpr:$filename" -thumbnail '150x150>' -unsharp 0x.5 "${THUMBNAILS_DIRNAME}/${filename}.${THUMBNAILS_FORMAT}"
      else
        if [[ "$IMAGICK_WEBP" = [yY] ]]; then
          echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT}${IMAGICK_PNGOPTS} \
          -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
          "mpr:$filename"${IMAGICK_WEBPOPTS} -resize ${MAXRES}x${MAXRES}\> "${filename}.webp""
          convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT}${IMAGICK_PNGOPTS} \
          -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
          "mpr:$filename"${IMAGICK_WEBPOPTS} -resize ${MAXRES}x${MAXRES}\> "${filename}.webp"
        else
          echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT}${IMAGICK_PNGOPTS} -resize ${MAXRES}x${MAXRES}\> "${fileout}""
          convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT}${IMAGICK_PNGOPTS} -resize ${MAXRES}x${MAXRES}\> "${fileout}"
        fi
      fi
    elif [[ "$IMAGICK_RESIZE" = [yY] ]]; then
      if [[ "$THUMBNAILS" = [yY] ]]; then
        echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT} -quality "$IMAGICK_QUALITY" \
        -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
        "mpr:$filename" -thumbnail '150x150>' -unsharp 0x.5 "${THUMBNAILS_DIRNAME}/${filename}.${THUMBNAILS_FORMAT}""
        convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT} -quality "$IMAGICK_QUALITY" \
        -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
        "mpr:$filename" -thumbnail '150x150>' -unsharp 0x.5 "${THUMBNAILS_DIRNAME}/${filename}.${THUMBNAILS_FORMAT}"
      else
        if [[ "$IMAGICK_WEBP" = [yY] ]]; then
          echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT} -quality "$IMAGICK_QUALITY" \
          -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
          "mpr:$filename"${IMAGICK_WEBPOPTS} -resize ${MAXRES}x${MAXRES}\> "${filename}.webp""
          convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT} -quality "$IMAGICK_QUALITY" \
          -write "mpr:$filename" -resize ${MAXRES}x${MAXRES}\> -write "${fileout}" +delete \
          "mpr:$filename"${IMAGICK_WEBPOPTS} -resize ${MAXRES}x${MAXRES}\> "${filename}.webp"
        else
          echo "convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT} -quality "$IMAGICK_QUALITY" -resize ${MAXRES}x${MAXRES}\> "${fileout}""
          convert -define registry:temporary-path="${IMAGICK_TMPDIR}" "${file}"${INTERLACE_OPT}${STRIP_OPT} -quality "$IMAGICK_QUALITY" -resize ${MAXRES}x${MAXRES}\> "${fileout}"
        fi
      fi
    fi
    if [[ "$extension" = 'png' ]]; then
      if [[ "$OPTIPNG" = [yY] ]]; then
        echo "optipng -o${OPTIPNG_COMPRESSION} "${fileout}" -preserve -out "${fileout}""
        optipng -o${OPTIPNG_COMPRESSION} "${fileout}" -preserve -out "${fileout}"
      fi
      if [[ "$ZOPFLIPNG" = [yY] ]]; then
        echo "zopflipng -y --iterations=1 "${fileout}" "${fileout}""
        zopflipng -y --iterations=1 "${fileout}" "${fileout}"
      fi
    elif [[ "$extension" = 'jpg' || "$extension" = 'jpeg' ]]; then
      if [[ "$JPEGOPTIM" = [yY] ]]; then
        echo "jpegoptim -p --max="$IMAGICK_QUALITY" "${fileout}""
        jpegoptim -p --max="$IMAGICK_QUALITY" "${fileout}"
      fi
    fi

    # check thumbnail image info
    tn_file=$(basename "${THUMBNAILS_DIRNAME}/${filename}.${THUMBNAILS_FORMAT}")
    tn_extension="${tn_file##*.}"
    tn_filename="${tn_file%.*}"
    if [[ "$THUMBNAILS" = [yY] ]]; then
      echo "pushd ${THUMBNAILS_DIRNAME}"
      pushd ${THUMBNAILS_DIRNAME}
      if [[ "$tn_extension" = 'png' ]]; then
        if [[ "$OPTIPNG" = [yY] ]]; then
          echo "optipng -o${OPTIPNG_COMPRESSION} "${filename}.${THUMBNAILS_FORMAT}" -preserve -out "${filename}.${THUMBNAILS_FORMAT}""
          optipng -o${OPTIPNG_COMPRESSION} "${filename}.${THUMBNAILS_FORMAT}" -preserve -out "${filename}.${THUMBNAILS_FORMAT}"
        fi
        if [[ "$ZOPFLIPNG" = [yY] ]]; then
          echo "zopflipng -y --iterations=1 "${filename}.${THUMBNAILS_FORMAT}" "${filename}.${THUMBNAILS_FORMAT}""
          zopflipng -y --iterations=1 "${filename}.${THUMBNAILS_FORMAT}" "${filename}.${THUMBNAILS_FORMAT}"
        fi
      elif [[ "$tn_extension" = 'jpg' || "$tn_extension" = 'jpeg' ]]; then
        if [[ "$JPEGOPTIM" = [yY] ]]; then
          echo "jpegoptim -p --max="$THUMBNAILS_QUALITY" "${filename}.${THUMBNAILS_FORMAT}""
          jpegoptim -p --max="$THUMBNAILS_QUALITY" "${filename}.${THUMBNAILS_FORMAT}"
        fi
      fi
      popd
    fi
  done
  echo "-------------------------------------------------------------------------"
  }
  endtime=$(TZ=UTC date +%s.%N)
  processtime=$(echo "scale=2;$endtime - $starttime"|bc)
  echo "Completion Time: $(printf "%0.2f\n" $processtime) seconds"
  echo "-------------------------------------------------------------------------"
}

###############
case "$1" in
  optimise)
    DIR=$2
    if [ -d "$DIR" ]; then
      optimiser "$DIR"
    fi
    ;;
  profile)
    DIR=$2
    profiler "$DIR"
    ;;
  testfiles)
    DIR=$2
    testfiles "$DIR"
    ;;
    *)
    echo "$0 {optimise} /PATH/TO/DIRECTORY/WITH/IMAGES"
    echo "$0 {profile} /PATH/TO/DIRECTORY/WITH/IMAGES"
    echo "$0 {testfiles} /PATH/TO/DIRECTORY/WITH/IMAGES"
    ;;
esac

exit