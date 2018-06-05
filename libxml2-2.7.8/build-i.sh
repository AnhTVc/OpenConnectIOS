#!/bin/bash
 
# Referenced from
# http://coin-c.tumblr.com/post/18063869172/thread-safe-xmllib2
# http://pastie.org/3429938
 
mkdir -p `pwd`/build
OUTDIR="./build"
 
IOS_BASE_SDK="10.3"
IOS_DEPLOY_TGT="10.3"
CONFIGURE_OPTIONS="--without-zlib --without-iconv --with-threads"
 
setenv_all()
{
        # Add internal libs
        export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -L$GLOBAL_OUTDIR/lib"
 
#        export CC="$DEVROOT/usr/bin/gcc"
#        export LD=$DEVROOT/usr/bin/ld
#        export AR=$DEVROOT/usr/bin/ar
#        export AS=$DEVROOT/usr/bin/as
#        export NM=$DEVROOT/usr/bin/nm
#        export RANLIB=$DEVROOT/usr/bin/ranlib
        export LDFLAGS="-L$SDKROOT/usr/lib/"
 
#        export CPPFLAGS=$CFLAGS
#        export CXXFLAGS=$CFLAGS
}
 
function setenv_arm6
{
        unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
 
        export DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer
        export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
 
        export CFLAGS="-arch armv6 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
 
        setenv_all
}
 
function setenv_arm7
{
        unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
 
        export DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer
        export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
 
        export CFLAGS="-arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
 
        setenv_all
}
 
setenv_i386()
{
        unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
 
        export DEVROOT=/Developer/Platforms/iPhoneSimulator.platform/Developer
        export SDKROOT=$DEVROOT/SDKs/iPhoneSimulator$IOS_BASE_SDK.sdk
 
        export CFLAGS="-arch i386 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT"
 
        setenv_all
}
 
make clean; make distclean
 
setenv_arm6
 
./configure --host=arm-apple-darwin6 --enable-shared=no ${CONFIGURE_OPTIONS} --prefix ${PWD}/build
 
make; make install
mv build/lib/libxml2.a libxml2-armv6.a
make clean; make distclean
 
setenv_arm7
 
./configure --host=arm-apple-darwin7 --enable-shared=no ${CONFIGURE_OPTIONS} --prefix ${PWD}/build
 
make; make install
mv build/lib/libxml2.a libxml2-armv7.a
make clean; make distclean
 
setenv_i386
./configure --host=i386-apple-darwin --enable-shared=no ${CONFIGURE_OPTIONS} --prefix ${PWD}/build
 
make; make install
mv build/lib/libxml2.a libxml2-i386.a
 
lipo -arch armv6 libxml2-armv6.a -arch armv7 libxml2-armv7.a -arch i386 libxml2-i386.a -create -output build/libxml2.a
