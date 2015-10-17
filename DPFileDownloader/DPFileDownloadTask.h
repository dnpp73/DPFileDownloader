#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, DPFileDownloadTaskState) {
    DPFileDownloadTaskStateInitial = 0,
    DPFileDownloadTaskStateWaitingForDownload,
    DPFileDownloadTaskStateDownloading,
    DPFileDownloadTaskStateDownloadSuccess,
    DPFileDownloadTaskStateDownloadFail,
    DPFileDownloadTaskStatePausing,
};


@class DPFileDownloadTask;


@protocol DPFileDownloadTaskObserving <NSObject>
@optional
- (void)fileDownloadTaskDidChangeState:(DPFileDownloadTask*)fileDownloadTask beforeState:(DPFileDownloadTaskState)beforeState;
- (void)fileDownloadTaskDidUpdateProgress:(DPFileDownloadTask*)fileDownloadTask;
@end


@protocol DPFileDownloadTaskDelegate <NSObject>
@optional
- (void)fileDownloadTask:(DPFileDownloadTask*)fileDownloadTask didFinishDownloadToTemporaryLocation:(NSURL*)location;
@end


@interface DPFileDownloadTask : NSObject <NSCoding>

- (instancetype)initWithURLRequest:(NSURLRequest*)URLRequest;
@property (nonatomic, readonly) NSURLRequest* URLRequest;

@property (nonatomic, readonly) DPFileDownloadTaskState state;
@property (nonatomic, readonly) float progress;

@property (nonatomic, readonly) NSHTTPURLResponse* HTTPURLResponse;
@property (nonatomic)           NSString* expectedDirectoryPath;
@property (nonatomic)           NSString* expectedFileName;
@property (nonatomic)           BOOL      useExpectedPathExtension; // default YES
@property (nonatomic, readonly) NSString* expectedPathExtension;

- (void)addFileDownloadTaskObserver:(__weak id<DPFileDownloadTaskObserving>)observer;
- (void)removeFileDownloadTaskObserver:(__weak id<DPFileDownloadTaskObserving>)observer;

@property (nonatomic, weak) id<DPFileDownloadTaskDelegate> delegate;

@end
