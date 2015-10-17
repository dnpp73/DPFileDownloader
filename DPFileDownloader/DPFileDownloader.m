#import "DPFileDownloader.h"
#import "DPFileDownloadTask.h"
#import "DPFileDownloadTask_Private.h"


@interface DPFileDownloader () <NSURLSessionDownloadDelegate>
{
    NSHashTable* _observers;
    
    NSURLSession*        _session;
    NSMutableDictionary* _fileDownloadTaskDictionary; // key is NSURLSessionTask
    
    NSMutableArray* _queuedFileDownloadTasks;
    NSMutableArray* _operatingFileDownloadTasks;
    NSMutableArray* _historyOfFileDownloadTasks;
}
@end


@implementation DPFileDownloader

#pragma mark - Singleton Pattern

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initSharedDownloader
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        
        _maxConcurrentDownloadCount = 3;
        
        NSURLSessionConfiguration* configuration;
        {
            NSString* backgroundSessionIdentifier = @"DPFileDownloaderBackgroundSessionIdentifier";
            #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
            // iOS 8.0 未満
            if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated"
                configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:backgroundSessionIdentifier];
                #pragma clang diagnostic pop
            }
            // iOS 8.0 以降
            else {
                configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:backgroundSessionIdentifier];
            }
            #elif TARGET_OS_MAC
            // OSX 10.10 未満
            if (NSFoundationVersionNumber <= NSFoundationVersionNumber10_9_2) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated"
                configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:backgroundSessionIdentifier];
                #pragma clang diagnostic pop
            }
            // OSX 10.10 以降
            else {
                configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:backgroundSessionIdentifier];
            }
            #endif
            // configuration.HTTPAdditionalHeaders = nil;
            configuration.allowsCellularAccess = YES;
            configuration.timeoutIntervalForRequest = 60;
            // configuration.timeoutIntervalForResource;
            configuration.HTTPMaximumConnectionsPerHost = 3;
        }
        NSURLSession* session = [NSURLSession sessionWithConfiguration:configuration
                                                              delegate:self
                                                         delegateQueue:[NSOperationQueue mainQueue]];
        _session = session;
        
        _fileDownloadTaskDictionary = [NSMutableDictionary dictionary];
        
        _queuedFileDownloadTasks    = [NSMutableArray array];
        _operatingFileDownloadTasks = [NSMutableArray array];
        _historyOfFileDownloadTasks = [NSMutableArray array];
        
        // 不整合があるとアレなので強制終了とかで残ってた場合はもう全部キャンセルしちゃう
        [session getTasksWithCompletionHandler:^(NSArray* dataTasks, NSArray* uploadTasks, NSArray* downloadTasks){
            for (NSURLSessionTask* task in dataTasks) {
                [task cancel];
            }
            for (NSURLSessionTask* task in uploadTasks) {
                [task cancel];
            }
            for (NSURLSessionTask* task in downloadTasks) {
                [task cancel];
            }
        }];
    }
    return self;
}

+ (instancetype)sharedDownloader
{
    static id downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[self alloc] initSharedDownloader];
    });
    return downloader;
}

#pragma mark - Observers

- (void)addFileDownloaderObserver:(__weak id<DPFileDownloaderObserving>)observer
{
    if (observer && [observer conformsToProtocol:@protocol(DPFileDownloaderObserving)]) {
        if ([_observers containsObject:observer] == NO) {
            [_observers addObject:observer];
        }
    }
}

- (void)removeFileDownloaderObserver:(__weak id<DPFileDownloaderObserving>)observer
{
    if (observer && [_observers containsObject:observer]) {
        [_observers removeObject:observer];
    }
}

- (void)sendObserversOperationUpdateMessageWithFileDownloadTask:(DPFileDownloadTask*)task
{
    for (id<DPFileDownloaderObserving> observer in _observers) {
        if ([observer respondsToSelector:@selector(fileDownloader:didUpdateOperationOfFileDownloadTask:)]) {
            [observer fileDownloader:self didUpdateOperationOfFileDownloadTask:task];
        }
    }
}

#pragma mark -

- (void)enqueueFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask
{
    NSURLSessionDownloadTask* task = [_session downloadTaskWithRequest:fileDownloadTask.URLRequest];
    fileDownloadTask.URLSessionDownloadTask = task;
    _fileDownloadTaskDictionary[task] = fileDownloadTask;
    [fileDownloadTask setState:DPFileDownloadTaskStateWaitingForDownload];
    
    if (_operatingFileDownloadTasks.count < _maxConcurrentDownloadCount) {
        [_operatingFileDownloadTasks addObject:fileDownloadTask];
        [task resume];
        [self sendObserversOperationUpdateMessageWithFileDownloadTask:fileDownloadTask];
    } else {
        [_queuedFileDownloadTasks addObject:fileDownloadTask];
        [self sendObserversOperationUpdateMessageWithFileDownloadTask:fileDownloadTask];
    }
}

- (void)pauseFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask
{
    if ([_operatingFileDownloadTasks containsObject:fileDownloadTask]) {
        if (fileDownloadTask.state == DPFileDownloadTaskStateDownloading) {
            [fileDownloadTask.URLSessionDownloadTask suspend];
            [fileDownloadTask setState:DPFileDownloadTaskStatePausing];
        }
    }
}

- (void)resumeFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask
{
    if ([_operatingFileDownloadTasks containsObject:fileDownloadTask]) {
        if (fileDownloadTask.state == DPFileDownloadTaskStatePausing) {
            [fileDownloadTask.URLSessionDownloadTask resume];
        }
    }
}

- (void)cancelFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask
{
    if ([_operatingFileDownloadTasks containsObject:fileDownloadTask]) {
        [fileDownloadTask.URLSessionDownloadTask cancel];
    }
    else if ([_queuedFileDownloadTasks containsObject:fileDownloadTask]) {
        [fileDownloadTask.URLSessionDownloadTask cancel];
    }
}

- (void)setMaxConcurrentDownloadCount:(NSInteger)maxConcurrentDownloadCount
{
    _maxConcurrentDownloadCount = MAX(0, maxConcurrentDownloadCount);
}

- (NSArray*)queuedFileDownloadTasks
{
    return _queuedFileDownloadTasks.copy;
}

- (NSArray*)operatingFileDownloadTasks
{
    return _operatingFileDownloadTasks.copy;
}

- (NSArray*)historyOfFileDownloadTasks
{
    return _historyOfFileDownloadTasks.copy;
}

- (void)clearFileDownloadHistory
{
    [_historyOfFileDownloadTasks removeAllObjects];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (session == _session) {
        DPFileDownloadTask* fileDownloadTask = _fileDownloadTaskDictionary[downloadTask];
        [fileDownloadTask setState:DPFileDownloadTaskStateDownloading];
        [fileDownloadTask sendProgressDidChangeMessageToObservers];
    }
}

- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    if (session == _session) {
        DPFileDownloadTask* fileDownloadTask = _fileDownloadTaskDictionary[downloadTask];
        [fileDownloadTask sendProgressDidChangeMessageToObservers];
    }
}

- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask
didFinishDownloadingToURL:(NSURL*)location
{
    if (session == _session) {
        DPFileDownloadTask* fileDownloadTask = _fileDownloadTaskDictionary[downloadTask];
        if ([fileDownloadTask.delegate respondsToSelector:@selector(fileDownloadTask:didFinishDownloadToTemporaryLocation:)]) {
            [fileDownloadTask.delegate fileDownloadTask:fileDownloadTask didFinishDownloadToTemporaryLocation:location];
        }
        else if (fileDownloadTask.expectedDirectoryPath.length && fileDownloadTask.expectedFileName.length) {
            NSURL*    to;
            NSString* toString;
            NSError*  error;
            {
                toString = [fileDownloadTask.expectedDirectoryPath stringByAppendingPathComponent:fileDownloadTask.expectedFileName];
                NSString* pathExtension = fileDownloadTask.expectedPathExtension;
                if (fileDownloadTask.useExpectedPathExtension && pathExtension.length) {
                    toString = [toString stringByAppendingPathExtension:pathExtension];
                }
                to = [NSURL fileURLWithPath:toString];
            }
            NSFileManager* fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:toString]) {
                [fm removeItemAtURL:to error:&error];
            }
            if (!error) {
                [fm moveItemAtURL:location toURL:to error:&error];
            }
        }
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task
didCompleteWithError:(NSError*)error
{
    if (session == _session) {
        DPFileDownloadTask* fileDownloadTask = _fileDownloadTaskDictionary[task];
        if (fileDownloadTask) {
            
            if (error) {
                [fileDownloadTask setState:DPFileDownloadTaskStateDownloadFail];
            } else {
                [fileDownloadTask setState:DPFileDownloadTaskStateDownloadSuccess];
            }
            
            [_operatingFileDownloadTasks removeObject:fileDownloadTask];
            [_queuedFileDownloadTasks removeObject:fileDownloadTask];
            [_historyOfFileDownloadTasks addObject:fileDownloadTask];
            [_fileDownloadTaskDictionary removeObjectForKey:task];
            [self sendObserversOperationUpdateMessageWithFileDownloadTask:fileDownloadTask];
            
            if (_operatingFileDownloadTasks.count < _maxConcurrentDownloadCount && _queuedFileDownloadTasks.count > 0) {
                DPFileDownloadTask* newFileDownloadTask = _queuedFileDownloadTasks[0];
                [_queuedFileDownloadTasks removeObject:newFileDownloadTask];
                [_operatingFileDownloadTasks addObject:newFileDownloadTask];
                [newFileDownloadTask.URLSessionDownloadTask resume];
                [self sendObserversOperationUpdateMessageWithFileDownloadTask:newFileDownloadTask];
            }
            
        }
    }
}

@end
