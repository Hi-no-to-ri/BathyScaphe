//
//  p22chConnector.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/06/29.
//  encoding="UTF-8"
//

#import "SG2chConnector.h"

@interface p22chConnector : SG2chConnector <p22chPosting> {
    NSDictionary *m_userInfo;
    id m_confirmationFormData; // 書き込み確認のときの全責任を承諾して書き込むフォームのデータ
}

- (BOOL)detectIsP2PostSuccess:(NSData *)responseData error:(NSError **)error;
- (BOOL)getEncodedConfirmationForm:(NSString **)encodedStr actionPath:(NSString **)pathStr error:(NSError **)error;
@end
