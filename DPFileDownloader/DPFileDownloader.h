#import <Foundation/Foundation.h>


@class DPFileDownloadTask, DPFileDownloader;


@protocol DPFileDownloaderObserving <NSObject>
@optional
- (void)fileDownloader:(DPFileDownloader*)fileDownloader didUpdateOperationOfFileDownloadTask:(DPFileDownloadTask*)task;
@end


@interface DPFileDownloader : NSObject

+ (instancetype)sharedDownloader;

- (void)addFileDownloaderObserver:(__weak id<DPFileDownloaderObserving>)observer;
- (void)removeFileDownloaderObserver:(__weak id<DPFileDownloaderObserving>)observer;

@property (nonatomic) NSInteger maxConcurrentDownloadCount;
- (void)enqueueFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask;
- (void)pauseFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask;
- (void)resumeFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask;
- (void)cancelFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask;

@property (nonatomic, readonly, copy) NSArray* queuedFileDownloadTasks;
@property (nonatomic, readonly, copy) NSArray* operatingFileDownloadTasks;
@property (nonatomic, readonly, copy) NSArray* historyOfFileDownloadTasks;

- (void)clearFileDownloadHistory;

@end
