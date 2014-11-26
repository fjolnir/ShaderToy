#import <Cocoa/Cocoa.h>

@interface STView : NSOpenGLView
@property(nonatomic, copy) NSString *shaderSource;

- (BOOL)setShaderSource:(NSString *)aSrc error:(NSError **)aoErr;
@end
