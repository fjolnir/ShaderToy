#import "STView.h"
#import "STShaderProgram.h"

static CVReturn _displayLinkCallback(CVDisplayLinkRef,
                                     const CVTimeStamp*,
                                     const CVTimeStamp*,
                                     CVOptionFlags,
                                     CVOptionFlags*,
                                     void*);

@implementation STView {
    STShaderProgram *_shaderProgram;
    CVDisplayLinkRef _displayLink;
    NSDate *_startDate;
    NSPoint _mouseLoc;
    NSString *_shaderSource;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if((self = [super initWithCoder:coder])) {
        [self.openGLContext makeCurrentContext];
        _shaderProgram = [STShaderProgram new];
        [_shaderProgram attachShaderOfType:GL_VERTEX_SHADER
                                    source:
         @"attribute vec2 aPos;\n"
         @"void main() { gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0); }"
         error:NULL];
        self.shaderSource = @"void main() {}";
    }
    return self;
}

- (void)mouseMoved:(NSEvent * const)aEvent
{
    _mouseLoc = [self convertPoint:[aEvent locationInWindow] fromView:nil];
}

- (BOOL)canBecomeKeyView
{
    return YES;
}
- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)prepareOpenGL
{
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
    CVDisplayLinkSetOutputCallback(_displayLink, &_displayLinkCallback, (__bridge void *)self);

    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cglContext, cglPixelFormat);

    CVDisplayLinkStart(_displayLink);
    _startDate = [NSDate new];
}

- (CVReturn)getFrameForTime:(const CVTimeStamp * const)aOutputTime
{
    if ([self lockFocusIfCanDraw]) {
        [self.openGLContext makeCurrentContext];
        CGLLockContext(self.openGLContext.CGLContextObj);

        [self drawRect:self.bounds];
        [self.openGLContext flushBuffer];

        CGLUnlockContext(self.openGLContext.CGLContextObj);
        [self unlockFocus];
    }
    return kCVReturnSuccess;
}

- (void)drawRect:(NSRect const)aDirtyRect
{
    glClear(GL_COLOR_BUFFER_BIT);
    GLfloat const quad[] = {
        -1, -1,
        -1, 1,
        1, -1,
        1, 1
    };
    glUseProgram(_shaderProgram.program);

    GLint const posAttr = [_shaderProgram getAttributeLocation:@"aPos"];
    glEnableVertexAttribArray(posAttr);
    glVertexAttribPointer(posAttr, 2, GL_FLOAT, GL_FALSE, 0, quad);


    NSDate * const now = [NSDate new];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear
                                                                      |NSCalendarUnitMonth
                                                                      |NSCalendarUnitDay
                                                                      |NSCalendarUnitSecond
                                                              fromDate:now];
    glUniform1f([_shaderProgram getUniformLocation:@"iGlobalTime"],
                [now timeIntervalSinceDate:_startDate]);
    glUniform4f([_shaderProgram getUniformLocation:@"iDate"],
                comps.year, comps.month, comps.day, comps.second);

    GLint viewport[4];
    glGetIntegerv( GL_VIEWPORT, viewport);
    glUniform3f([_shaderProgram getUniformLocation:@"iResolution"],
                viewport[2], viewport[3], 0);
    glUniform4f([_shaderProgram getUniformLocation:@"iMouse"],
                _mouseLoc.x, _mouseLoc.y, 0, 1);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)dealloc
{
    CVDisplayLinkRelease(_displayLink);
}

- (void)setShaderSource:(NSString * const)aSrc
{
    [self setShaderSource:aSrc error:NULL];
}
- (BOOL)setShaderSource:(NSString *)aSrc error:(NSError **)aoErr
{
    CGLLockContext(self.openGLContext.CGLContextObj);
    [self.openGLContext makeCurrentContext];
    _shaderSource = aSrc;
    NSString *prefix = @"uniform vec3 iResolution;\n"            // viewport resolution (in pixels)
                       @"uniform float iGlobalTime;\n"           // shader playback time (in seconds)
                       @"uniform vec4 iMouse;\n"                // mouse pixel coords. xy: current (if MLB down), zw: click
                       @"uniform vec4 iDate;\n"
                       @"uniform float iChannelTime[4];\n"       // channel playback time (in seconds)
                       @"uniform vec3 iChannelResolution[4];\n"; // channel resolution (in pixels)
    BOOL  const result = [_shaderProgram attachShaderOfType:GL_FRAGMENT_SHADER
                                                     source:[prefix stringByAppendingString:aSrc]
                                                      error:aoErr];
    CGLUnlockContext(self.openGLContext.CGLContextObj);
    return result;
}

@end

static CVReturn _displayLinkCallback(CVDisplayLinkRef const aDisplayLink,
                                     const CVTimeStamp * const aNow,
                                     const CVTimeStamp * const aOutputTime,
                                     CVOptionFlags const aFlagsIn,
                                     CVOptionFlags * const aoFlagsOut,
                                     void * const aCtx)
{
    @autoreleasepool {
        return [(__bridge STView *)aCtx getFrameForTime:aOutputTime];
    }
}