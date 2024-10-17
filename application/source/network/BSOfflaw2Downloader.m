//
//  BSOfflaw2Downloader.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/12/07.
//
//

#import "BSOfflaw2Downloader.h"
#import "ThreadTextDownloader_p.h"

static NSString *const kResourceURLTemplate = @"http://%@/test/offlaw2.so?shiro=kuma&bbs=%@&key=%@";

@implementation BSOfflaw2Downloader
- (id)initWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host
{
    if (self = [super init]) {
        [self setReusesDownloader:NO];
        [self setCandidateHost:host];
        [self setNextIndex:0];
        [self setIdentifier:signature];
        [self setThreadTitle:aTitle];
    }
    return self;
}

+ (id)downloaderWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host
{
    return [[[self alloc] initWithIdentifier:signature threadTitle:aTitle candidateHost:host] autorelease];
}

- (void)dealloc
{
    [m_candidateHost release];
    [m_downloadingHost release];
    [super dealloc];
}

- (NSString *)downloadingHost
{
    if (!m_downloadingHost) {
        m_downloadingHost = [[[self boardURL] host] retain];
    }
    return m_downloadingHost;
}

- (void)setDownloadingHost:(NSString *)host
{
    [host retain];
    [m_downloadingHost release];
    m_downloadingHost = host;
}

- (NSString *)candidateHost
{
    return m_candidateHost;
}

- (void)setCandidateHost:(NSString *)host
{
    [host retain];
    [m_candidateHost release];
    m_candidateHost = host;
}

- (BOOL)reusesDownloader
{
    return m_reuse;
}

- (void)setReusesDownloader:(BOOL)willReuse
{
    m_reuse = willReuse;
}

- (NSURL *)resourceURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:kResourceURLTemplate, [self downloadingHost], [[self boardURL] path], [[self threadSignature] identifier]]];
}

- (BOOL)useMaru
{
    return NO;
}

- (void)cancelDownloadWithDetectingDatOchi:(NSString *)movedLocation
{
    if (![self candidateHost] || [[self candidateHost] isEqualToString:[self downloadingHost]]) {
        NSArray			*recoveryOptions;
        NSDictionary	*dict;
        NSError			*error;
        NSString *description;
        NSString *suggestion;
        BOOL isPink = NO;
        
        const char *cs = [[self downloadingHost] UTF8String];
        isPink = is_2channel(cs); // && !is_2ch_except_pink(cs);

        description = isPink ? [self localizedString:@"Offlaw2soFailPinkDescription"] : [self localizedString:@"Offlaw2soFailDescription"];
        suggestion = isPink ? [self localizedString:@"Offlaw2soFailPinkSuggestion"] : [self localizedString:@"Offlaw2soFailSuggestion"];
        
        recoveryOptions = isPink ? [NSArray arrayWithObjects:[self localizedString:@"ErrorRecoveryCancel"], [self localizedString:@"DatOchiRetry"], nil] : [NSArray arrayWithObjects:[self localizedString:@"ErrorRecoveryCancel"], nil];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
                description, NSLocalizedDescriptionKey,
                suggestion, NSLocalizedRecoverySuggestionErrorKey,
                NULL];
        error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSOfflaw2DownloaderThreadNotFoundError userInfo:dict];
        UTILNotifyInfo3(CMRDATDownloaderDidDetectDatOchiNotification, error, @"Error");
        return;
    }
    
    [[CMRNetGrobalLock sharedInstance] remove:[self resourceURL]];
    [self setReusesDownloader:YES];
    [self setDownloadingHost:[self candidateHost]];
    [self setCandidateHost:nil]; // 今はこうしておかないと、万一移転前サーバにも見つからなかったときに無限再挑戦してしまう
}

- (void)checkResponse:(NSHTTPURLResponse *)response statusCode:(NSInteger)status forConnection:(NSURLConnection *)connection
{
    if (status == 200) {
        [self setMessage:[NSString stringWithFormat:[self localizedMessageFormat], [[self resourceURL] absoluteString]]];
    } else {
        // 想定外の http レスポンス
        [connection cancel];
		[self setMessage:[self localizedCanceledString]];
        [self cancelDownloadWithDetectingDatOchi:nil];
        [self didFinishLoading];
    }
}
@end
