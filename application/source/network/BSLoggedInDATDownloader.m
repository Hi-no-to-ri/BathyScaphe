//
//  BSLoggedInDATDownloader.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/10/15.
//  Copyright 2007-2014 BathyScaphe Project. All rights reserved.
//

#import "BSLoggedInDATDownloader.h"
#import "ThreadTextDownloader_p.h"
#import "AppDefaults.h"
#import "w2chConnect.h"

//static NSString *const kResourceURLTemplate = @"http://%@/%@%@/%@/?sid=%@";
static NSString *const kResourceURLTemplate = @"http://%@/%@%@/%@/?raw=0.0&sid=%@";

@implementation BSLoggedInDATDownloader

@synthesize rokkaLastError;

+ (NSArray *)errorStringArray
{
    static NSArray *cache;
    if (!cache) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"RokkaErrorCodes" withExtension:@"plist"];
        cache = [[NSArray arrayWithContentsOfURL:url] retain];
    }
    return cache;
}

- (NSString *)localizedRokkaErrorString
{
    NSArray *array = [[self class] errorStringArray];
    for (NSDictionary *dict in array) {
        NSInteger code = [dict integerForKey:@"Code"];
        if (code == [self rokkaLastError]) {
            return [dict objectForKey:@"Message"];
        }
    }

    return @"";
}

- (id)initWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host
{
    if (self = [super init]) {
        [self setReusesDownloader:NO];
        [self setCandidateHost:host];
        [self setNextIndex:0];
        [self setIdentifier:signature];
        [self setThreadTitle:aTitle];
        rokkaLastError = 0;

        if (![self updateSessionID]) {
            [self autorelease];
            return nil;
        }
    }
    return self;
}

+ (id)downloaderWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host
{
    return [[[self alloc] initWithIdentifier:signature threadTitle:aTitle candidateHost:host] autorelease];
}

- (BOOL)updateSessionID
{
    id<w2chAuthenticationStatus>    authenticator_;
    NSString                        *sessionID_;

    authenticator_ = [CMRPref shared2chAuthenticator];
    if (!authenticator_) return NO;

    sessionID_ = [authenticator_ sessionID];

    if (sessionID_) {
        m_sessionID = [sessionID_ retain];
    } else if ([authenticator_ recentErrorType] != w2chNoError) {
        [m_sessionID release];
        m_sessionID = nil;
        return NO;
    }
    
    return YES;
}

- (NSString *)sessionID
{
    return m_sessionID;
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

- (void)dealloc
{
    [m_candidateHost release];
    [m_downloadingHost release];
    [m_sessionID release];

    [super dealloc];
}

- (NSString *)rokkaHost
{
    NSString *host = [self downloadingHost];
    if ([host hasSuffix:@".bbspink.com"]) {
        return @"rokka.bbspink.com";
    }
    return @"rokka.2ch.net";
}

- (NSString *)rokkaServer
{
    NSString *host = [self downloadingHost];
    NSArray *foo = [host componentsSeparatedByString:@"."];
    return [foo objectAtIndex:0];
}

- (NSURL *)resourceURL
{
    if (![self sessionID]) {
        return [super resourceURL];
    }
    NSString *sidEscaped = [[self sessionID] stringByURLEncodingUsingEncoding:NSASCIIStringEncoding];

    return [NSURL URLWithString:[NSString stringWithFormat:kResourceURLTemplate, [self rokkaHost], [self rokkaServer], [[self boardURL] path], [[self threadSignature] identifier], sidEscaped]];
}

- (BOOL)useMaru
{
    return ([self sessionID] != nil);
}

- (void)cancelDownloadWithDetectingDatOchi:(NSString *)movedLocation
{
    if (![self candidateHost] || [[self candidateHost] isEqualToString:[self downloadingHost]]) {
        NSArray			*recoveryOptions;
        NSDictionary	*dict;
        NSError			*error;
        NSString *description;
        NSString *suggestion;
        description = [self localizedString:@"MaruFailDescription"];
        suggestion = [NSString stringWithFormat:[self localizedString:@"MaruFailSuggestionFormat"], [self localizedRokkaErrorString], (long)[self rokkaLastError]];

        recoveryOptions = [NSArray arrayWithObjects:[self localizedString:@"ErrorRecoveryCancel"], nil];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
                description, NSLocalizedDescriptionKey,
                suggestion, NSLocalizedRecoverySuggestionErrorKey,
                NULL];
        error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSLoggedInDATDownloaderThreadNotFoundError userInfo:dict];
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
    if (status == 200 || status == 400 || status == 401 || status == 403 || status == 404 || status == 501) {
        [self setMessage:[NSString stringWithFormat:[self localizedMessageFormat], [[self resourceURL] absoluteString]]];
    } else {
        // 想定外の http レスポンス
        [connection cancel];
        [self setRokkaLastError:-3];
		[self setMessage:[self localizedCanceledString]];
        [self cancelDownloadWithDetectingDatOchi:nil];
        [self didFinishLoading];
    }
}
@end
