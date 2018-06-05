#!/bin/bash
 
# Referenced from
# http://coin-c.tumblr.com/post/18063869172/thread-safe-xmllib2
# http://pastie.org/3429938
 
mkdir -p `pwd`/build
OUTDIR="./build"
 
IOS_BASE_SDK="10.3"
IOS_DEPLOY_TGT="10.3"
CONFIGURE_OPTIONS="--without-zlib --without-iconv --with-threads"
DEVROOT=`xcode-select -print-path`/Platforms/iPhoneOS.platform/Developer
setenv_all()
{
        # Add internal libs
        export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -L$GLOBAL_OUTDIR/lib"
 
        #export CC="$DEVROOT/usr/bin/gcc"
        #export LD=$DEVROOT/usr/bin/ld
        #export AR=$DEVROOT/usr/bin/ar
        #export AS=$DEVROOT/usr/bin/as
        #export NM=$DEVROOT/usr/bin/nm
        #export RANLIB=$DEVROOT/usr/bin/ranlib
        export LDFLAGS="-L$SDKROOT/usr/lib/"
 
        export CPPFLAGS=$CFLAGS
        export CXXFLAGS=$CFLAGS
}

buildIOS(){
	ARCH=$1	
	echo "Start Building OpenConnect for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
			PLATFORM="iPhoneSimulator"
		else
			PLATFORM="iPhoneOS"
			#sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
		fi
	export $PLATFORM
	#export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	#export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	#export BUILD_TOOLS="${DEVELOPER}"
	#export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -mios-version-min=${MIN_IOS_VERSION} -arch ${ARCH}"
	echo "Configure"
	export 	MINIOSVERSION="9.0"
	export 	EXTRA_CFLAGS=""
	export 	EXTRA_LDFLAGS=""
	export 	SDKVERSION="10.3"
	export 	DEVELOPER=`xcode-select -print-path`
	export 	PLATFORM="iPhoneOS"
	export 	OUTPUTDIR=${PWD}/build 

	./configure --prefix=${OUTPUTDIR} --with-vpnc-script=/usr/local/etc/vpnc-script --disable-nls --without-gnutls --host arm-apple-darwin --enable-static \
	LDFLAGS="$LDFLAGS -arch arm64 -fPIE -miphoneos-version-min=${MINIOSVERSION} ${EXTRA_LDFLAGS} -L${OUTPUTDIR}/lib" \
	CFLAGS="$CFLAGS -g -O0 -D__APPLE_USE_RFC_3542 -arch arm64 -fPIE -miphoneos-version-min=${MINIOSVERSION} ${EXTRA_CFLAGS} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" 
	
	#if [[ "${ARCH}" == "x86_64" ]]; then
	#	./configure CC="" darwin64-x86_64-cc --with-vpnc-script=/usr/local/etc/vpnc-script --disable-nls
	#else
	#	./configure CC="" --with-vpnc-script=/usr/local/etc/vpnc-script --disable-nls
	#fi
	#sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mios-version-min=${MIN_IOS_VERSION} !" "Makefile"
	
}
 
function setenv_arm6
{
        #unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
 
        #export DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer
        export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
 
        export CFLAGS="-arch armv64 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
 
        #setenv_all
		#MIN_IOS_VERSION="9.0"
		#buildIOS "arm64"
		#make clean
		#make 
		#make install
		#mv build/lib/libxml2.a libxml2-armv6.a
		#make clean; make distclean
}
 
function setenv_arm7
{
        #unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
 
        #export DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer
        export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
 
        export CFLAGS="-arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
 
        setenv_all
}

#make clean; make distclean
 
#setenv_arm6
 
#./configure --host=arm-apple-darwin64 --enable-shared=no ${CONFIGURE_OPTIONS} --prefix=${PWD}/build CC=""
 
#make
#make install
#mv build/lib/libxml2.a libxml2-armv64.a
#make clean; make distclean
 make clean; make distclean
setenv_arm7
 
./configure --host=arm-apple-darwin7 --enable-shared=no ${CONFIGURE_OPTIONS} --prefix=${PWD}/build CC=""
 
make; make install
mv build/lib/libxml2.a libxml2-armv7.a
make clean; make distclean
 
#setenv_i386
#./configure --host=i386-apple-darwin --enable-shared=no ${CONFIGURE_OPTIONS} --prefix ${PWD}/build
 
#make; make install
#mv build/lib/libxml2.a libxml2-i386.a
 
lipo -arch armv7 libxml2-armv7.a -create -output build/libxml2.a
