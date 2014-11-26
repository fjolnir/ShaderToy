#import <Cocoa/Cocoa.h>

@class STView;

@interface STShaderDocument : NSDocument
@property(nonatomic) IBOutlet STView *shaderView;
@property(nonatomic) IBOutlet NSTextView *logView;
@end
