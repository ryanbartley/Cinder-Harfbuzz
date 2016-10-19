#!/bin/bash

lower_case=$(echo "$1" | tr '[:upper:]' '[:lower:]')
 
if [ -z $1 ]; then 
	echo Need to provide platform. Possible platforms are linux, macosx, ios. Exiting!
	exit 
fi

WITH_PANGO=false
if [ -z $2 ]; then
  echo Building without Glib functionality.
else
  if [ -z "${GLIB_LIBS:?false}" ]; then
    echo "Chose with-pango but GLIB flags not present. Use Cinder-Pango to get Glib in the correct place. Exiting!"
    exit
  fi
  echo "Configured to run with Pango"
  WITH_PANGO=true
fi

#########################
## create prefix dirs
#########################

PREFIX_BASE_DIR=`pwd`/tmp

PREFIX_HARFBUZZ=${PREFIX_BASE_DIR}/harfbuzz_install
rm -rf ${PREFIX_HARFBUZZ}
mkdir -p ${PREFIX_HARFBUZZ}

#########################
## gather cairo libs
#########################

CAIRO_BASE_DIR="../../Cairo"
CAIRO_LIB_PATH="${CAIRO_BASE_DIR}/lib/${lower_case}"
CAIRO_INCLUDE_PATH="${CAIRO_BASE_DIR}/include/${lower_case}/cairo"
# make sure it's the correct version
echo "Setting up cairo flags..."

#########################
## create final path
#########################

FINAL_PATH=`pwd`/..
LIB_DIR=lib
INCLUDE_DIR=include
if [ $WITH_PANGO = true ]; then
  LIB_DIR=lib_p
  INCLUDE_DIR=include_p
fi

FINAL_LIB_PATH=${FINAL_PATH}/${LIB_DIR}/${lower_case}
rm -rf ${FINAL_LIB_PATH}
mkdir -p ${FINAL_LIB_PATH}
 
FINAL_INCLUDE_PATH=${FINAL_PATH}/${INCLUDE_DIR}/${lower_case}
rm -rf ${FINAL_INCLUDE_PATH}
mkdir -p ${FINAL_INCLUDE_PATH}

#########################
## different archs
#########################

buildIOS() 
{
  echo Building IOS...
  buildHarfbuzz "${HOST}" "--with-coretext=yes --with-glib=no --with-gobject=no --with-fontconfig=no"
}

buildOSX() 
{
  echo Building OSX...
  OPTIONS="--with-coretext=yes --with-glib=no --with-gobject=no --with-fontconfig=no"
  if [ $WITH_PANGO = true ]; then
    OPTIONS="--with-coretext=yes --with-glib=yes --with-gobject=yes --with-fontconfig=yes"
  fi
  buildHarfbuzz "" "${OPTIONS}"
}

buildLinux() 
{
  echo Building Linux...
  OPTIONS="--with-glib=no --with-gobject=no --with-fontconfig=yes"
  if [ $WITH_PANGO = true ]; then
    OPTIONS="--with-glib=yes --with-gobject=yes --with-fontconfig=yes"
  fi
  buildHarfbuzz "" "${OPTIONS}"
}

#########################
## downloading libs
#########################

downloadHarfbuzz() 
{
	echo Downloading Harfbuzz
	curl -o harfbuzz.tar.bz2 https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.3.2.tar.bz2
	tar xf harfbuzz.tar.bz2 
	mv harfbuzz-* harfbuzz
  if [ "${lower_case}" = "ios" ]; then
    echo In the harfbuzz change...
    if [ ! -f harfbuzz/configure.ac ]; then 
      echo "FILE DOESN'T EXIST" 
    fi
    sed -i -e 's=ApplicationServices/ApplicationServices.h=CoreText/CoreText.h=' harfbuzz/configure
    sed -i -e 's=-framework ApplicationServices=-framework CoreText -framework CoreGraphics=' harfbuzz/configure
  fi
  echo Finished downloading Harfbuzz...
}

#########################
## building libs
#########################

buildHarfbuzz()
{
  cd harfbuzz
  echo "Building harfbuzz, and installing $1"
  PREFIX=$PREFIX_HARFBUZZ
  HOST=$1
  OPTIONS=$2
  echo "Passed in $HOST"

  if [ -z "$HOST" ]; then
    ./configure --disable-shared --enable-static=yes --prefix=${PREFIX} --enable-gtk-doc-html=no --with-cairo=yes --with-freetype=yes ${OPTIONS}
  else
    echo Building with cross-compile    
    ./configure --host=${HOST} --disable-shared --enable-static=yes --prefix=${PREFIX} --enable-gtk-doc-html=no --with-cairo=yes --with-freetype=yes ${OPTIONS} 
  fi

  make -j 6
  make install
  make clean

  cp -r ${PREFIX}/include/* ${FINAL_INCLUDE_PATH}
  cp ${PREFIX}/lib/*.a ${FINAL_LIB_PATH}

  cd ..
}

#########################
## echo the flags
#########################

echoFlags()
{
  echo "==================================================================="
  echo "Environment for ${lower_case}..."
  echo -e "\t CXX:      ${CXX}"
  echo -e "\t CC:       ${CC}"
  echo -e "\t CFLAGS:   ${CFLAGS}"
  echo -e "\t CXXFLAGS: ${CXXFLAGS}"
  echo -e "\t LDFLAGS:  ${LDFLAGS}"
  echo "==================================================================="
}

rm -rf tmp
mkdir tmp
cd tmp

downloadHarfbuzz

declare -a config_settings=("debug" "release")
declare -a config_paths=("/Debug" "/Release")

export CAIRO_CFLAGS="-I${CAIRO_INCLUDE_PATH}"
export CAIRO_LIBS="-L${CAIRO_LIB_PATH} -lcairo"

echo "Building harfbuzz for {$lower_case}"
if [ "${lower_case}" = "mac" ] || [ "${lower_case}" = "macosx" ];
then
  export PATH="${PATH}:${PREFIX_GETTEXT}/bin"
  
	export CPPFLAGS="${CPPFLAGS} -I${PREFIX_GETTEXT}/include"	
	export CXX="$(xcrun -find -sdk macosx clang++) -Wno-enum-conversion"
	export CC="$(xcrun -find -sdk macosx clang) -Wno-enum-conversion"
	export CFLAGS="-O3 -pthread -I${PREFIX_GETTEXT}/include ${CFLAGS}"
	export CXXFLAGS="-O3 -pthread ${CXXFLAGS}"
	export LDFLAGS="-stdlib=libc++ -framework AppKit -framework CoreText -framework CoreFoundation -framework CoreGraphics  -framework Carbon -L/usr/local/lib ${LDFLAGS}"

  ##################################
  ## we use cinder to link freetype
  ##################################

  CINDER_DIR=`pwd`/../../../..
  CINDER_LIB_DIR=${CINDER_DIR}/lib/${lower_case}/Release
  CINDER_FREETYPE_INCLUDE_PATH=${CINDER_DIR}/include/

  if [ ! -f "${CINDER_LIB_DIR}/libcinder.a" ]; then
    echo "Need to build release version of cinder to run this install. Cairo needs Freetype. Exiting!"
    exit
  fi

  export FREETYPE_LIBS="-L${CINDER_LIB_DIR} -lcinder"
  export FREETYPE_CFLAGS="-I${CINDER_FREETYPE_INCLUDE_PATH}/freetype -I${CINDER_FREETYPE_INCLUDE_PATH}"

  echoFlags
	buildOSX
elif [ "${lower_case}" = "linux" ];
then
  export PATH="${PATH}:${PREFIX_GETTEXT}/bin"
	
	export CXX="/usr/bin/clang++ -Wno-enum-conversion"
	export CC="/usr/bin/clang -Wno-enum-conversion"
	export CFLAGS="-O3 -pthread -I${PREFIX_GETTEXT}/include ${CFLAGS}"
  export CPPFLAGS="${CPPFLAGS} -I${PREFIX_GETTEXT}/include"
	export CXXFLAGS="-O3 -pthread ${CXXFLAGS}"

  ##################################
  ## we use cinder to link freetype
  ##################################

  CINDER_DIR=`pwd`/../../../..
  CINDER_LIB_DIR=${CINDER_DIR}/lib/${lower_case}/x86_64/ogl/Release
  CINDER_FREETYPE_INCLUDE_PATH=${CINDER_DIR}/include/

  if [ ! -f "${CINDER_LIB_DIR}/libcinder.a" ]; then
    echo "Need to build release version of cinder to run this install. Cairo needs Freetype. Exiting!"
    exit
  fi

  export FREETYPE_LIBS="-L${CINDER_LIB_DIR} -lcinder"
  export FREETYPE_CFLAGS="-I${CINDER_FREETYPE_INCLUDE_PATH}/freetype -I${CINDER_FREETYPE_INCLUDE_PATH}"

  echoFlags 
	buildLinux
elif [ "${lower_case}" = "ios" ];
then

  ARCH="arm64"
  HOST="arm-apple-darwin"
  export IOS_PLATFORM="iPhoneOS"
  export IOS_PLATFORM_DEVELOPER="$(xcode-select --print-path)/Platforms/${IOS_PLATFORM}.platform/Developer"
  export IOS_SDK="${IOS_PLATFORM_DEVELOPER}/SDKs/$(ls ${IOS_PLATFORM_DEVELOPER}/SDKs | sort -r | head -n1)"
  echo $IOS_SDK
  export XCODE_DEVELOPER=`xcode-select --print-path`
  export CXX="$(xcrun -find -sdk iphoneos clang++) -Wno-enum-conversion"
  export CC="$(xcrun -find -sdk iphoneos clang) -Wno-enum-conversion"
  
  export CPPFLAGS="-isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -mios-version-min=8.0"
  export CFLAGS="-O3 -pthread ${CFLAGS}"
  #export PIXMAN_CFLAGS_i386="${CFLAGS} -DPIXMAN_NO_TLS"
  #export PIXMAN_CXXFLAGS_i386="${CXXFLAGS} -DPIXMAN_NO_TLS"
  export CXXFLAGS="-O3 -pthread ${CXXFLAGS} -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -I${INCLUDEDIR}/pixman-1 -arch ${ARCH} -mios-version-min=8.0"
  
  export LDFLAGS="-stdlib=libc++ -isysroot ${IOS_SDK} -L${FINAL_LIB_PATH} -L${IOS_SDK}/usr/lib -arch ${ARCH} -mios-version-min=8.0 -framework CoreText -framework CoreFoundation -framework CoreGraphics  ${LDFLAGS}"
  export PNG_LIBS="-L${IOS_SDK}/usr/lib ${PNG_LIBS}"

  ##################################
  ## we use cinder to link freetype
  ##################################

  CINDER_DIR=`pwd`/../../../..
  CINDER_LIB_DIR=${CINDER_DIR}/lib/${lower_case}/Release
  CINDER_FREETYPE_INCLUDE_PATH=${CINDER_DIR}/include/
 
  if [ ! -f "${CINDER_LIB_DIR}/libcinder.a" ]; then
    echo "Need to build release version of cinder to run this install. Cairo needs Freetype. Exiting!"
    exit
  fi
 
  export FREETYPE_LIBS="-L${CINDER_LIB_DIR} -lcinder"
  export FREETYPE_CFLAGS="-I${CINDER_FREETYPE_INCLUDE_PATH}/freetype -I${CINDER_FREETYPE_INCLUDE_PATH}"

  echoFlags
  buildIOS
else
  echo "Unkown selection: ${1}"
  echo "usage: ./install.sh [platform]"
  echo "accepted platforms are macosx, linux, ios"
  exit 1
fi

# rm -rf tmp
