#!/bin/bash


lower_case=$(echo "$1" | tr '[:upper:]' '[:lower:]')
 
if [ -z $1 ]; then 
	echo Need to provide platform. Possible platforms are linux, macosx, ios. Exiting!
	exit 
fi 

#########################
## create prefix dirs
#########################

PREFIX_BASE_DIR=`pwd`/tmp

PREFIX_LIBZ=${PREFIX_BASE_DIR}/libz_install
rm -rf ${PREFIX_LIBZ}
mkdir ${PREFIX_LIBZ}

PREFIX_LIBFFI=${PREFIX_BASE_DIR}/libffi_install
rm -rf ${PREFIX_LIBFFI}
mkdir ${PREFIX_LIBFFI}

PREFIX_GETTEXT=${PREFIX_BASE_DIR}/gettext_install
rm -rf ${PREFIX_GETTEXT}
mkdir ${PREFIX_GETTEXT}

PREFIX_GLIB=${PREFIX_BASE_DIR}/glib_install
rm -rf ${PREFIX_GLIB}
mkdir ${PREFIX_GLIB}

PREFIX_HARFBUZZ=${PREFIX_BASE_DIR}/harfbuzz_install
rm -rf ${PREFIX_HARFBUZZ}
mkdir ${PREFIX_HARFBUZZ}

#########################
## gather cairo libs
#########################

CAIRO_BASE_DIR="../../Cairo"
CAIRO_LIB_PATH="${CAIRO_BASE_DIR}/lib/${lower_case}"
CAIRO_INCLUDE_PATH="${CAIRO_BASE_DIR}/include/${lower_case}/cairo"
# make sure it's the correct version
echo "Setting up cairo flags..."

#############################
## cinder paths for freetype
#############################

CINDER_DIR=`pwd`/../../../
CINDER_LIB_DIR=${CINDER_DIR}/lib/${lower_case}/Release
CINDER_FREETYPE_INCLUDE_PATH=${CINDER_DIR}/include/freetype

#########################
## create final path
#########################

FINAL_PATH=`pwd`/..
FINAL_LIB_PATH=${FINAL_PATH}/lib/${lower_case}
rm -rf ${FINAL_LIB_PATH}
mkdir -p ${FINAL_LIB_PATH}
 
FINAL_INCLUDE_PATH=${FINAL_PATH}/include/${lower_case}
rm -rf ${FINAL_INCLUDE_PATH}
mkdir -p ${FINAL_INCLUDE_PATH}

#########################
## different archs
#########################

buildIOS() 
{
  echo Building IOS...

# buildZlib
# buildLibffi $HOST
# buildGettext $HOST
# buildGlib $HOST
  buildHarfbuzz $HOST "--with-coretext=yes"
}

buildOSX() 
{
  echo Building OSX...

  buildZlib
  buildLibffi
  buildGettext
	export LDFLAGS="${LDFLAGS} -L${PREFIX_GETTEXT}/lib -lintl -lgettextpo -lasprintf"
  buildGlib 
  buildHarfbuzz "" "--with-coretext=yes"
}

buildLinux() 
{
  echo Building Linux...

  buildZlib
  buildLibffi
  buildGettext
	export LDFLAGS="${LDFLAGS} -L${PREFIX_GETTEXT}/lib -lgettextpo -lasprintf"
  buildGlib 
  buildHarfbuzz
}

#########################
## downloading libs
#########################

downloadZlib()
{
	echo Downloading zlib...
  curl http://zlib.net/zlib-1.2.8.tar.gz -o zlib.tar.gz
  tar -xf zlib.tar.gz
  mv zlib-* zlib
  rm zlib.tar.gz
  echo Finished Downloading zlib...
}

downloadLibffi()
{
	echo Downloading libffi...
  if [ "${lower_case}" = "ios" ]; then 
    curl ftp://sourceware.org/pub/libffi/libffi-3.2.tar.gz -o libffi.tar.gz
    tar -xf libffi.tar.gz
    mv libffi-* libffi
    rm libffi.tar.gz 
  else 
    curl ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz -o libffi.tar.gz
    tar -xf libffi.tar.gz
    mv libffi-* libffi
    rm libffi.tar.gz
  fi
  echo Finished Downloading libffi...
}

downloadGettext()
{
	echo Downloading gettext...
  curl ftp://ftp.gnu.org/pub/gnu/gettext/gettext-latest.tar.gz -o gettext.tar.gz
  tar -xf gettext.tar.gz
  mv gettext-* gettext
  rm gettext.tar.gz
  echo Finished Downloading gettext...
}

downloadGlib()
{
	echo Downloading Glib...
	curl -o glib.tar.xz ftp://ftp.gnome.org/pub/GNOME/sources/glib/2.50/glib-2.50.0.tar.xz
	tar xf glib.tar.xz
	mv glib-* glib
	echo Finished downloading glib...
}

downloadHarfbuzz() 
{
	echo Downloading Harfbuzz
	curl -o harfbuzz.tar.bz2 https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.3.2.tar.bz2
	tar xf harfbuzz.tar.bz2 
	mv harfbuzz-* harfbuzz
	echo Finished downloading Harfbuzz...
}

buildZlib()
{
  cd zlib
  echo "Building and installing zlib, ${PREFIX_LIBZ}"
  PREFIX=${PREFIX_LIBZ}
 
  ./configure --prefix=${PREFIX}

  make -j 6
  make install
  make clean

  cd ..
}

buildLibffi()
{
  cd libffi
  echo "Building and installing libffi"
  PREFIX=${PREFIX_LIBFFI}
  HOST=$1
  if [ -z "$HOST" ]; then
    ./configure --prefix=${PREFIX}
  else
    #python ./generate-darwin-source-and-headers.py
    ./configure --prefix=${PREFIX} --host=${HOST}
  fi

  make -j 6
  make install
  make clean

  cd ..
}

buildGettext()
{
  cd gettext
  echo "Building and installing gettext"
  PREFIX=${PREFIX_GETTEXT}
  HOST=$1
  if [ -z "${HOST}"]; then
    ./configure --prefix=${PREFIX} --disable-java --without-emacs --disable-native-java --disable-openmp 
  else
    ./configure --host=${HOST} --prefix=${PREFIX} --disable-java --without-emacs --disable-native-java --disable-openmp 
  fi

  make -j 6
  make install
  make clean

  cd ..
}

buildGlib()
{
  cd glib
  echo "Building glib, and installing $1"
  PREFIX=$PREFIX_GLIB
  HOST=$1
  echo "Passed in $HOST"
  if [ -z "$HOST" ]; then
    ./configure --disable-shared --prefix=${PREFIX} --disable-gtk-doc-html --disable-installed-tests --disable-always-build-tests
  else
    echo Building with cross-compile
    ./configure --host=${HOST} --disable-shared --prefix=${PREFIX} --disable-gtk-doc-html --disable-installed-tests --disable-always-build-tests
  fi

  make -j 6
  make install
  make clean

  cp -r ${PREFIX}/include/* ${FINAL_INCLUDE_PATH}
  cp ${PREFIX}/lib/*.a ${FINAL_LIB_PATH}

  cd ..
}

buildHarfbuzz()
{
  cd harfbuzz
  echo "Building harfbuzz, and installing $1"
  PREFIX=$PREFIX_HARFBUZZ
  HOST=$1
  OPTIONS=$2
  echo "Passed in $HOST"

  if [ -z "$HOST" ]; then
    ./configure --disable-shared --enable-static=yes --prefix=${PREFIX} --enable-gtk-doc-html=no --with-gobject=yes --with-cairo=yes --with-fontconfig=yes --with-freetype=yes ${OPTIONS}
  else
    echo Building with cross-compile    
    ./configure --host=${HOST} --disable-shared --enable-static=yes --prefix=${PREFIX} --enable-gtk-doc-html=no --with-cairo=yes --with-fontconfig=yes --with-freetype=yes ${OPTIONS} 
  fi

  make -j 6
  make install
  make clean

  cp -r ${PREFIX}/include/* ${FINAL_INCLUDE_PATH}
  cp ${PREFIX}/lib/*.a ${FINAL_LIB_PATH}

  cd ..
}

rm -rf tmp
mkdir tmp
cd tmp

downloadZlib
downloadLibffi
downloadGettext
downloadGlib
downloadHarfbuzz

declare -a config_settings=("debug" "release")
declare -a config_paths=("/Debug" "/Release")

export ZLIB_LIBS="-L${PREFIX_LIBZ}/lib -lz"
export ZLIB_CFLAGS="-I${PREFIX_LIBZ}/include"
export LIBFFI_LIBS="-L${PREFIX_LIBFFI}/lib -lffi"
export LIBFFI_CFLAGS="-I${PREFIX_LIBFFI}/lib/libffi-3.2.1/include/"
export FREETYPE_LIBS="-L${CINDER_LIB_DIR} -lcinder"
export FREETYPE_CFLAGS="-I${CINDER_FREETYPE_INCLUDE_PATH}"
export GLIB_CFLAGS="-I${PREFIX_GLIB}/include/glib-2.0 -I${PREFIX_GLIB}/lib/glib-2.0/include"
export GLIB_LIBS="-L${PREFIX_GLIB}/lib -lglib-2.0"
export GOBJECT_CFLAGS="-I${PREFIX_GLIB}/include/glib-2.0 -I${PREFIX_GLIB}/lib/glib-2.0/include"
export GOBJECT_LIBS="-L${PREFIX_GLIB}/lib -lgobject-2.0"
export CAIRO_CFLAGS="-I${CAIRO_INCLUDE_PATH}"
export CAIRO_LIBS="-L${CAIRO_LIB_PATH} -lcairo"

echo "Building harfbuzz for {$lower_case}"
if [ "${lower_case}" = "mac" ] || [ "${lower_case}" = "macosx" ];
then
  export PATH="${PATH}:${PREFIX_GETTEXT}/bin"
  
	export CPPFLAGS="${CPPFLAGS} -I${PREFIX_GETTEXT}/include"	
	export CXX="$(xcrun -find -sdk macosx clang++) -Wno-enum-conversion"
	export CC="$(xcrun -find -sdk macosx clang) -Wno-enum-conversion"
	export CFLAGS="-O3 -pthread $ -I${PREFIX_GETTEXT}/include {CFLAGS}"
	export CXXFLAGS="-O3 -pthread ${CXXFLAGS}"
	export LDFLAGS="-stdlib=libc++ -framework AppKit -framework CoreText -framework CoreFoundation -framework CoreGraphics  -framework Carbon -L/usr/local/lib ${LDFLAGS}"
	
	echo Environment for Mac OSX...
	echo \t PATH: 		${PATH}
	echo \t CXX:      ${CXX}
	echo \t CC:       ${CC}
	echo \t CFLAGS:   ${CFLAGS}
	echo \t CPPFLAGS: ${CPPFLAGS}
	echo \t CXXFLAGS: ${CXXFLAGS}
	echo \t LDFLAGS:  ${LDFLAGS}

	buildOSX
elif [ "${lower_case}" = "linux" ];
then
  export PATH="${PATH}:${PREFIX_GETTEXT}/bin"
	
	export CXX="/usr/bin/clang++ -Wno-enum-conversion"
	export CC="/usr/bin/clang -Wno-enum-conversion"
	export CFLAGS="-O3 -pthread -I${PREFIX_GETTEXT}/include ${CFLAGS}"
  export CPPFLAGS="${CPPFLAGS} -I${PREFIX_GETTEXT}/include"
	export CXXFLAGS="-O3 -pthread ${CXXFLAGS}"
  
	echo Environment for Linux...
	echo \t PATH:     ${PATH}
	echo \t CXX:      ${CXX}
	echo \t CC:       ${CC}
	echo \t CFLAGS:   ${CFLAGS}
	echo \t CPPFLAGS: ${CPPFLAGS}
	echo \t CXXFLAGS: ${CXXFLAGS}
	echo \t LDFLAGS:  ${LDFLAGS}

	buildLinux
elif [ "${lower_case}" = "ios" ];
then

  ARCH="arm64"
  export XCODE_DEVELOPER=`xcode-select --print-path` 
  export IOS_PLATFORM="iPhoneOS"
  export IOS_PLATFORM_DEVELOPER="${XCODE_DEVELOPER}/Platforms/${IOS_PLATFORM}.platform/Developer"
  LATEST_SDK=`ls ${IOS_PLATFORM_DEVELOPER}/SDKs | sort -r | head -n1`
  export IOS_SDK="${IOS_PLATFORM_DEVELOPER}/SDKs/${LATEST_SDK}"
  HOST="arm-apple-darwin"
  
  export CXX=`xcrun -find -sdk iphoneos clang++`
  export CC=`xcrun -find -sdk iphoneos clang`
  export CPPFLAGS="-isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch arm64 -mios-version-min=8.0"
  export CXXFLAGS="-stdlib=libc++ -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch arm64  -mios-version-min=8.0"
  export LDFLAGS="-stdlib=libc++ -isysroot ${IOS_SDK} -framework CoreText -L${FINAL_LIB_PATH} -L${IOS_SDK}/usr/lib -arch arm64 -mios-version-min=8.0"
  echo 'IOS_SDK =' ${IOS_SDK}
#  export PATH="${PATH}:${PREFIX_GETTEXT}/bin"
#  export LDFLAGS="${LDFLAGS} -framework AppKit -framework CoreFoundation -framework Carbon -L${PREFIX_GETTEXT}/lib -lintl -lgettextpo -lasprintf -L/usr/local/lib" 
  #export CPPFLAGS="${CPPFLAGS} -I${PREFIX_GETTEXT}/include"
  #export CFLAGS="${CFLAGS} -I${PREFIX_GETTEXT}/include"
	buildIOS
else
  echo "Unkown selection: ${1}"
  echo "usage: ./install.sh [platform]"
  echo "accepted platforms are macosx, linux, ios"
  exit 1
fi

# rm -rf tmp
