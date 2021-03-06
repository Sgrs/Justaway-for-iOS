#import "JFIActionStatus.h"

@interface JFIActionStatus ()

@property (nonatomic) NSMutableDictionary *favoriteDictionary;
@property (nonatomic) NSMutableDictionary *retweetDictionary;

@end

@implementation JFIActionStatus

+ (JFIActionStatus *)sharedActionStatus
{
    static JFIActionStatus *actionStatus;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        actionStatus = [[JFIActionStatus alloc] init];
    });
    
    return actionStatus;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.favoriteDictionary = [NSMutableDictionary dictionary];
        self.retweetDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)isFavorite:(NSString *)key
{
    return [self.favoriteDictionary objectForKey:key] != nil ? YES : NO;
}

- (void)setFavorite:(NSString *)key
{
    [self.favoriteDictionary setObject:@(1) forKey:key];
}

- (void)removeFavorite:(NSString *)key
{
    [self.favoriteDictionary removeObjectForKey:key];
}

- (BOOL)isRetweet:(NSString *)key
{
    return [self.retweetDictionary objectForKey:key] != nil ? YES : NO;
}

- (NSString *)getRetweetId:(NSString *)key
{
    return [self.retweetDictionary objectForKey:key];
}

- (void)setRetweet:(NSString *)key
{
    [self.retweetDictionary setObject:@"" forKey:key];
}

- (void)setRetweetId:(NSString *)key statusId:(NSString *)statusId
{
    [self.retweetDictionary setObject:statusId forKey:key];
}

- (void)removeRetweet:(NSString *)key
{
    [self.retweetDictionary removeObjectForKey:key];
}

@end
