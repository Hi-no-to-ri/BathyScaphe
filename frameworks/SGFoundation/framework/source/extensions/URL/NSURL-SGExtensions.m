//
//  NSURL-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/NSURL-SGExtensions_p.h>
#import <SGFoundation/SGFileRef.h>
#import <SGFoundation/String+Utils.h>


@implementation NSURL(SGExtensions)
// https://github.com/nicerobot/objc/blob/master/NSURL/NSURL+Bug8840060Fix/NSURL+Bug8840060Fix.m より
/**
 * Simplistic workaround for NSURL bug 8840060. This will simply strip
 * the the additional fragments from the string.
 */
NSString* stripFragments(NSString* url) {
    NSArray *fragments = [url componentsSeparatedByString:@"#"];
    if (2 <= [fragments count]) {
        url = [NSString stringWithFormat:@"%@#%@",
               [fragments objectAtIndex:0],
               [fragments objectAtIndex:1]];
    }
    return url;
}

+ (id)URLWithLink:(id)aLink
{
	return [self URLWithLink:aLink baseURL:nil];
}

+ (id)URLWithLink:(id)anLink baseURL:(NSURL *)baseURL
{
	NSString		*path_ = nil;
	
	if (!anLink) { 
		return nil;
	}
	if ([anLink isKindOfClass:[NSURL class]]){
		if (!baseURL) {
			return anLink;
		}
		path_ = [anLink absoluteString];
	}
	
	if ([anLink isKindOfClass:[NSString class]]) {
		path_ = stripFragments(anLink);
    }
    
    if ([anLink isKindOfClass:NSClassFromString(@"BSInnerLinkValueRep")]) {
        path_ = [anLink stringValue];
    }
    
	return [self URLWithString:path_ relativeToURL:baseURL];
}

+ (id)URLWithScheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path
{
	return [[[self alloc] initWithScheme:scheme host:host path:path] autorelease];
}

- (NSString *)stringValue
{
	return [self absoluteString];
}

- (NSDictionary *)queryDictionary
{
	NSMutableDictionary	*params_;
	NSString			*query_;
	
	if(nil == (query_ = [self query]))
		return nil;
	
	params_ = [NSMutableDictionary dictionary];
	
	if([query_ length] > 1){
		NSArray      *parray_;
		NSEnumerator *iter_;
		NSString     *pstr_;
		
		//各パラメータを切り出す
		parray_ = [query_ componentsSeparatedByString : @"&"];
		iter_ = [parray_ objectEnumerator];
		while(pstr_ = [iter_ nextObject]){
			NSArray *pair_;
			if([pstr_ length] < 2){
				continue;
			}
			pair_ = [pstr_ componentsSeparatedByString : @"="];
			if([pair_ count] != 2){
				continue;
			}
			//辞書に登録
			[params_ setObject : [pair_ objectAtIndex : 1]
						forKey : [pair_ objectAtIndex : 0]];
		}
	}
	
	return params_;
}

// Carbon FSRef
- (BOOL) getFileSystemReference : (FSRef *) fileSystemRef
{
    if (![self isFileURL]) {
        return NO;
    }
    Boolean result = CFURLGetFSRef((CFURLRef)self, fileSystemRef);
    return result ? YES : NO;
}
@end
