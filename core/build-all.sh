###################################
# 		 SDK Version
###################################
IOS_SDK_VERSION=$(xcodebuild -version -sdk iphoneos | grep SDKVersion | cut -f2 -d ':' | tr -d '[[:space:]]')
###################################

################################################
# 		 Minimum iOS deployment target version
################################################
MIN_IOS_VERSION="9.0"
export LIBTOOLIZE=glibtoolizey
echo "----------------------------------------"
echo "Build for ios"
DEVELOPER=`xcode-select -print-path`
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
	export 	OUTPUTDIR="/usr/local"

	./configure --prefix=${OUTPUTDIR} --with-vpnc-script=/usr/local/etc/vpnc-script --disable-nls --without-gnutls --host arm-apple-darwin --enable-static \
	LDFLAGS="$LDFLAGS -arch $ARCH -fPIE -miphoneos-version-min=${MINIOSVERSION} ${EXTRA_LDFLAGS} -L${OUTPUTDIR}/lib" \
	CFLAGS="$CFLAGS -g -O0 -D__APPLE_USE_RFC_3542 -arch $ARCH -fPIE -miphoneos-version-min=${MINIOSVERSION} ${EXTRA_CFLAGS} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" 
	
	#if [[ "${ARCH}" == "x86_64" ]]; then
	#	./configure CC="" darwin64-x86_64-cc --with-vpnc-script=/usr/local/etc/vpnc-script --disable-nls
	#else
	#	./configure CC="" --with-vpnc-script=/usr/local/etc/vpnc-script --disable-nls
	#fi
	#sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mios-version-min=${MIN_IOS_VERSION} !" "Makefile"
	make 
	make install
	make clean
	mv /usr/local/lib/libopenconnect.a /usr/local/lib/libopenconnect-${ARCH}.a
	echo "build done for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
}
buildIOS "armv7"
buildIOS "arm64"
#buildIOS "i386"
#buildIOS "x86_64"
#buildIOS "armv7s"
#make clean
lipo -arch armv7 /usr/local/lib/libopenconnect-armv7.a -arch arm64 /usr/local/lib/libopenconnect-arm64.a -create -output /usr/local/lib/libopenconnect.a
