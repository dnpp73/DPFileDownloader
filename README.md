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

`NSURLSession` wrapper. Background downloader.

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