DPFileDownloader
===================

[![Build Status](http://img.shields.io/travis/dnpp73/DPFileDownloader.svg?style=flat-square)](https://travis-ci.org/dnpp73/DPFileDownloader)
[![Pod Version](http://img.shields.io/cocoapods/v/DPFileDownloader.svg?style=flat-square)](http://cocoadocs.org/docsets/DPFileDownloader/)
[![Pod Platform](http://img.shields.io/cocoapods/p/DPFileDownloader.svg?style=flat-square)](http://cocoadocs.org/docsets/DPFileDownloader/)
[![Pod License](http://img.shields.io/cocoapods/l/DPFileDownloader.svg?style=flat-square)](http://opensource.org/licenses/MIT)

### Dependency
* [`DPUTIUtil`](https://github.com/dnpp73/DPUTIUtil)

### Require Framework
* None

# Description

iOS 7-9, OSX 10.9-10.11 Compatible `NSURLSession` File Downloader

# Usage

### Sample

```Objective-C
[[DPFileDownloader sharedDownloader] addFileDownloaderObserver:self];
```

```Objective-C
NSURL*        URL;
NSURLRequest* req  = [NSURLRequest requestWithURL:URL];
NSString*     dirName;
NSString*     fileName;

DPFileDownloadTask* task   = [[DPFileDownloadTask alloc] initWithURLRequest:req];
[task addFileDownloadTaskObserver:self];
task.delegate = self;
task.expectedDirectoryPath = dirName;
task.expectedFileName      = fileName;
[[DPFileDownloader sharedDownloader] enqueueFileDownloadTask:task];
```

### Catch downloader/task messages

```Objective-C
#pragma mark - DPFileDownloaderObserving

- (void)fileDownloader:(DPFileDownloader*)fileDownloader didUpdateOperationOfFileDownloadTask:(DPFileDownloadTask*)task
{
    
}

#pragma mark - DPFileDownloadTaskObserving

- (void)fileDownloadTaskDidChangeState:(DPFileDownloadTask*)fileDownloadTask beforeState:(DPFileDownloadTaskState)beforeState
{
    
}

- (void)fileDownloadTaskDidUpdateProgress:(DPFileDownloadTask*)fileDownloadTask
{
    
}

#pragma mark - DPFileDownloadTaskDelegate

- (void)fileDownloadTask:(DPFileDownloadTask*)fileDownloadTask didFinishDownloadToTemporaryLocation:(NSURL*)location
{
    
}
```

### How to get valid directory path

```Objective-C
NSArray*  paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString* documentDirectoryPath = paths[0];
```

### Using file explorer for debug

```Objective-C
[self.navigationController pushViewController:[DPFileListViewController rootFileListViewController] animated:YES];
```

#LICENSE

Copyright (c) 2015 dnpp.org

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
