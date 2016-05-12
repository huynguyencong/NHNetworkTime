# NHNetworkTime
A network time protocol (NTP) client.

### About

The clock on the oldest iPhone, iTouch or iPad is not closely synchronized to the correct time. In the case of a device which is obtaining its time from the telephone system, there is a setting to enable synchronizing to the phone company time, but that time has been known to be over a minute different from the correct time.

In addition, users may change their device time and severely affect applications that rely on correct times to enforce functionality, or may set their devices clock into the past in an attempt to dodge an expiry date.

This project contains code to provide time obtained from standard time servers using the simple network time protocol (SNTP: RFC 5905). The implementation is not a rigorous as described in that document since the goal was to improve time accuracy to tens of milliSeconds, not to microseconds.

Computers using the NTP protocol usually employ it in a continuous low level task to keep track of the time on a continuous basis.  A background application uses occasional time estimates from a set of time servers to determine the best time by sampling these values over time. iOS applications are different, being more likely to want a one-time, quick estimate of the time.

#### Compatible
- iOS 7 and later.  
- Objective C, and Swift with bridge header (read below guide)

### Usage

#### Cocoapod
Add below line to Podfile:  

```
pod NHNetworkTime
```  
and then run below command in Terminal to install:  
`pod install`

Note: If above pod isn't working, try using below pod defination in Podfile:  
`pod 'NHNetworkTime', :git => 'https://github.com/huynguyencong/NHNetworkTime.git'`
#### Manual
Add all file in folder NHNetworkTime to your project. Then add `CocoaAsyncSocket` use Cocoapod or add manual.

#### Simple to use
Import this whenever you want to get time:   

```
#import "NHNetworkTime.h"
```

Call `synchronize` in `- application: didFinishLaunchingWithOptions:` to update time from server when you launch app:

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NHNetworkClock sharedNetworkClock] synchronize];
    return YES;
}
```

then you can get network time when sync complete in anywhere in your source code:

```
NSDate *networkDate = [NSDate networkDate];
```

or add notification to re-update your UI in anywhere you want when time is updated:

```
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkTimeSyncCompleteNotification:) name:kNHNetworkTimeSyncCompleteNotification object:nil];
```

#### Swift
#####Use `use_frameworks!`

If you have `use_frameworks!` option in Podfile, import `NHNetworkTime` framework in each code file use `NHNetworkTime` objects:

```
@import NHNetworkTime
```


##### Not use `use_frameworks!`


Import `NHNetworkTime.h` to your in bridge header file:  

```
#import <NHNetworkTime.h>
```
* You can create bridge header file by create an Objective C file in project. Xcode will ask you to create bridge header file. After, you can delete the temporatory Objective C file have just added, and import `NHNetworkTime.h` into there (Read more: https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html)

##### In your code
Now, you can call below code in your code:  

```
NHNetworkClock.sharedNetworkClock().synchronize()
```
and:

```
NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("syncCompleteNotification"), name: kNHNetworkTimeSyncCompleteNotification, object: nil)
```
#### More from NHNetworkClock
- Use `NSNotifcationCenter` to add observer `kNHNetworkTimeSyncCompleteNotification` to receive notification when time sync complete
- Property `isSynchronized`: Check network time synchronized or not
- Property `shouldUseSavedSynchronizedTime`: Should use offset time saved in the last synchronization before sync from server. Default is YES.
- Property `isAutoSynchronizedWhenUserChangeLocalTime`: Is auto sync when user change local time. Default is YES.

#### Custom time server
Add to project file name `ntp.hosts`, with content is time server address in every line. If file is not exist, it will use default time server. Example for `ntp.hosts` file:

```
asia.pool.ntp.org
europe.pool.ntp.org
north-america.pool.ntp.org
```


### About this source
NHNetworkTime is built from ios ntp open source from jbenet. NHNetworkTime fixed a critical bug get wrong time from origin source, and added more improvements:

- Post notification when sync complete
- Property make you know whether sync complete or not
- Save offset time local to use immediately right after launch app, don't have to waiting for server
- Auto sync when user change local time

### License
NHNetworkTime is released under the Apache license. See LICENSE for details. Copyright © Nguyen Cong Huy
