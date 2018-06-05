//
//  Wrapper.h
//  OpenConnectNew
//
//  Created by Tran Viet Anh on 7/31/17.
//  Copyright © 2017 NextVPN Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "config.h"

#ifdef HAVE_GETLINE
/* Various BSD systems require this for getline() to be visible */
#define _WITH_GETLINE
#endif

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <getopt.h>
#include <time.h>

#ifdef LIBPROXY_HDR
#include LIBPROXY_HDR
#endif

#include "openconnect-internal.h"

#ifdef _WIN32
#include <shlwapi.h>
#include <wtypes.h>
#include <wincon.h>
#else
#include <sys/utsname.h>
#include <pwd.h>
#include <termios.h>
#endif

@interface Wrapper : NSObject
+ (void) abc;

+ (void) startWithOptions:(NSArray*)options;

+ (Boolean) isConnected;

+ (char *) getVPNInfo;
@end
