#import <DPFileDownloader/DPFileDownloadTask.h>


@interface DPFileDownloadTask (URLSession_Private)

- (void)setState:(DPFileDownloadTaskState)state;

@property (nonatomic, weak) NSURLSessionDownloadTask* URLSessionDownloadTask;
- (void)sendProgressDidChangeMessageToObservers;

@end
