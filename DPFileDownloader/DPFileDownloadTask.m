#import "DPFileDownloadTask.h"
#import "DPFileDownloadTask_Private.h"
#import <DPUTIUtil/DPUTIUtil.h>


@interface DPFileDownloadTask ()
{
    NSHashTable* _observers;
    __weak NSURLSessionDownloadTask* _URLSessionDownloadTask;
}
@end


@implementation DPFileDownloadTask

#pragma mark - Initializer

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return self;
}

- (instancetype)initWithURLRequest:(NSURLRequest*)URLRequest
{
    self = [super init];
    if (self) {
        _URLRequest               = URLRequest;
        _state                    = DPFileDownloadTaskStateInitial;
        _useExpectedPathExtension = YES;
        _observers                = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

static NSString* const DPFileDownloadTaskURLRequestKey               = @"DPFileDownloadTaskURLRequestKey";
static NSString* const DPFileDownloadTaskStateKey                    = @"DPFileDownloadTaskStateKey";
static NSString* const DPFileDownloadTaskExpectedDirectoryPathKey    = @"DPFileDownloadTaskExpectedDirectoryPathKey";
static NSString* const DPFileDownloadTaskExpectedFileNameKey         = @"DPFileDownloadTaskExpectedFileNameKey";
static NSString* const DPFileDownloadTaskUseExpectedPathExtensionKey = @"DPFileDownloadTaskUseExpectedPathExtensionKey";

- (instancetype)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        _URLRequest               = [decoder decodeObjectForKey:DPFileDownloadTaskURLRequestKey];
        _state                    = (DPFileDownloadTaskState)[decoder decodeIntForKey:DPFileDownloadTaskStateKey];
        _expectedDirectoryPath    = [decoder decodeObjectForKey:DPFileDownloadTaskExpectedDirectoryPathKey];
        _expectedFileName         = [decoder decodeObjectForKey:DPFileDownloadTaskExpectedFileNameKey];
        _useExpectedPathExtension = [decoder decodeBoolForKey:DPFileDownloadTaskUseExpectedPathExtensionKey];
        _observers                = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_URLRequest             forKey:DPFileDownloadTaskURLRequestKey];
    [encoder encodeInt:(int)_state                forKey:DPFileDownloadTaskStateKey];
    [encoder encodeObject:_expectedDirectoryPath  forKey:DPFileDownloadTaskExpectedDirectoryPathKey];
    [encoder encodeObject:_expectedFileName       forKey:DPFileDownloadTaskExpectedFileNameKey];
    [encoder encodeBool:_useExpectedPathExtension forKey:DPFileDownloadTaskUseExpectedPathExtensionKey];
}

#pragma mark - Attributes

- (float)progress
{
    if (_URLSessionDownloadTask) {
        float  current = (float)(_URLSessionDownloadTask.countOfBytesReceived);
        float  total   = (float)(_URLSessionDownloadTask.countOfBytesExpectedToReceive);
        return current/total;
    }
    else {
        return -1.0;
    }
}

- (NSHTTPURLResponse*)HTTPURLResponse
{
    if (_URLSessionDownloadTask) {
        if ([_URLSessionDownloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
            return (NSHTTPURLResponse*)(_URLSessionDownloadTask.response);
        }
    }
    
    return nil;
}

- (NSString*)expectedPathExtension
{
    NSHTTPURLResponse* httpURLResponse = self.HTTPURLResponse;
    if (httpURLResponse) {
        NSString* MIMEType = httpURLResponse.allHeaderFields[@"Content-Type"];
        if (MIMEType) {
            return [DPUTIUtil pathExtensionFromMIMEType:MIMEType];
        }
    }
    
    return nil;
}

#pragma mark - Observers

- (void)addFileDownloadTaskObserver:(__weak id<DPFileDownloadTaskObserving>)observer
{
    if (observer && [observer conformsToProtocol:@protocol(DPFileDownloadTaskObserving)]) {
        if ([_observers containsObject:observer] == NO) {
            [_observers addObject:observer];
        }
    }
}

- (void)removeFileDownloadTaskObserver:(__weak id<DPFileDownloadTaskObserving>)observer
{
    if (observer && [_observers containsObject:observer]) {
        [_observers removeObject:observer];
    }
}

@end


@implementation DPFileDownloadTask (URLSession_Private)

- (void)setState:(DPFileDownloadTaskState)state
{
    if (_state != state) {
        DPFileDownloadTaskState beforeState = _state;
        _state = state;
        
        for (id<DPFileDownloadTaskObserving> observer in _observers) {
            if ([observer respondsToSelector:@selector(fileDownloadTaskDidChangeState:beforeState:)]) {
                [observer fileDownloadTaskDidChangeState:self beforeState:beforeState];
            }
        }
    }
}

- (NSURLSessionDownloadTask*)URLSessionDownloadTask
{
    return _URLSessionDownloadTask;
}

- (void)setURLSessionDownloadTask:(NSURLSessionDownloadTask*)URLSessionDownloadTask
{
    _URLSessionDownloadTask = URLSessionDownloadTask;
}

- (void)sendProgressDidChangeMessageToObservers
{
    for (id<DPFileDownloadTaskObserving> observer in _observers) {
        if ([observer respondsToSelector:@selector(fileDownloadTaskDidUpdateProgress:)]) {
            [observer fileDownloadTaskDidUpdateProgress:self];
        }
    }
}

@end
