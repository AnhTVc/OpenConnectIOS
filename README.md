# OpenConnectIOS
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-lightgrey.svg)
![iOS Versions](https://img.shields.io/badge/iOS-9.0+-yellow.svg)
![Xcode Version](https://img.shields.io/badge/Xcode-9.0+-yellow.svg)
![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-4BC51D.svg?style=flat)
![License](https://img.shields.io/badge/License-AGPLv3-lightgrey.svg)
# What is this?
OpenConnectIOS is an Objective-C project that allows to easily configure and establish VPN connection using OpenConnect protocol. It is based on the original [openconnect v7.07](https://github.com/dlenski/openconnect) library so it has every feature the library has.

The framework is designed to use in conjunction with [`NetworkExtension`](https://developer.apple.com/documentation/networkextension) framework and doesn't use any private Apple API.
## Installation

### Requirements
- iOS 9.0+ or macOS 10.11+
- Xcode 9.0+
### Usage
- Setup OpenConnect [`server`](https://gist.github.com/moklett/3170636)
- Clone project: 
```sh
$ cd [your folder]
$ git clone https://github.com/AnhTVc/OpenConnectIOS.git
```
- Open with Xcode
- Open file VPNViewController.m and setup config
``` java
 [Wrapper startWithOptions:@[@"--no-cert-check",
                                    @"--user", @"[your username]",
                                    @"[your server]";
 Find line "- (void) saveToPreferences" 
 reconfig:
    NSString *server = @"[your server]";
    NSString *ippublicserver = @"[ip public server]";
    NSString *port  = @"[port connect]";
```
### Contact
if you are interested, contact me skype: tranvietanh.hust@gmail.com or email: tranvietanh.hust@gmail.com
