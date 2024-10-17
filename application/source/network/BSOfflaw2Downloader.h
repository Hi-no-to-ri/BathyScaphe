//
//  BSOfflaw2Downloader.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/12/07.
//
//

#import "CMRDATDownloader.h"

@interface BSOfflaw2Downloader : CMRDATDownloader {
    NSString *m_downloadingHost;
    NSString *m_candidateHost;
    BOOL    m_reuse;
}

+ (id)downloaderWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host;
- (id)initWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host;

- (NSString *)downloadingHost;
- (void)setDownloadingHost:(NSString *)host;

- (NSString *)candidateHost;
- (void)setCandidateHost:(NSString *)host;
@end
