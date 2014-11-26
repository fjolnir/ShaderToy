#import "STShaderDocument.h"
#import "STView.h"

@implementation STShaderDocument {
    NSString *_shaderSource;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    aController.window.acceptsMouseMovedEvents = YES;
    [aController.window makeKeyAndOrderFront:nil];
    [aController.window makeFirstResponder:_shaderView];
    
    [self _updateView];
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (NSString *)windowNibName
{
    return @"STShaderDocument";
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSString *source = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if(![_shaderSource isEqualToString:source]) {
        _shaderSource = source;
        [self _updateView];
    }
    return YES;
}

- (void)_updateView
{
    if(_shaderView) {
        NSError *err;
        if(![_shaderView setShaderSource:_shaderSource error:&err])
            dispatch_async(dispatch_get_main_queue(), ^{
                [_logView.textStorage.mutableString appendString:err.localizedDescription];
            });
    }
}

- (void)presentedItemDidChange
{
    [self readFromURL:self.presentedItemURL ofType:nil error:NULL];
}
@end
