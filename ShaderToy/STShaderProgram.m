#import "STShaderProgram.h"

#ifdef DEBUG
#   define glError() do { \
        const char *errStr = NULL; \
        GLenum err; \
        while((err = glGetError()) != GL_NO_ERROR) { \
            switch(err) { \
                case GL_INVALID_ENUM:      errStr = "GL_INVALID_ENUM";      break; \
                case GL_INVALID_VALUE:     errStr = "GL_INVALID_VALUE";     break; \
                case GL_OUT_OF_MEMORY:     errStr = "GL_OUT_OF_MEMORY";     break; \
                case GL_INVALID_OPERATION: errStr = "GL_INVALID_OPERATION"; break; \
                case GL_INVALID_FRAMEBUFFER_OPERATION: \
                    errStr = "GL_INVALID_FRAMEBUFFER_OPERATION"; break; \
                default: errStr = "UNKNOWN"; \
            } \
            NSLog(@"glError(0x%04x): %s caught at %s:%u\n", \
                  err, errStr, __FILE__, __LINE__); \
        } \
        NSCAssert(errStr == NULL, @"OpenGL Error"); \
    } while(0)
#else
#   define glError()
#endif

@interface STShaderProgram ()
- (GLuint)_compileShader:(GLuint *)aoShader
              fromSource:(NSString *)aSourceStr
                    type:(GLenum)aShaderType
                   error:(NSError **)aoErr;
- (BOOL)_linkProgram:(NSError **)aoErr;
@end

@implementation STShaderProgram {
    NSMutableDictionary *_shaders, *_uniforms, *_attributes;
}

- (instancetype)init
{
    if(!(self = [super init]))
        return nil;
    
    _program = glCreateProgram();

    _uniforms   = [NSMutableDictionary new];
    _attributes = [NSMutableDictionary new];
    _shaders    = [NSMutableDictionary new];

    return self;
}

- (BOOL)attachShaderOfType:(GLenum const)aShaderType
                    source:(NSString * const)aSrc
                     error:(NSError **)aoErr
{
    GLuint shader;
    if(![self _compileShader:&shader fromSource:aSrc type:aShaderType error:aoErr])
        return NO;

    if(_shaders[@(aShaderType)]) {
        glDetachShader(_program, [_shaders[@(aShaderType)] unsignedIntValue]);
    }
    [_uniforms removeAllObjects];
    [_attributes removeAllObjects];
    _shaders[@(aShaderType)] = @(shader);

    glAttachShader(_program, shader);
    glError();

    return [self _linkProgram:aoErr];
}

- (GLint)getUniformLocation:(NSString * const)aUniformName
{
    if(_uniforms[aUniformName])
        return [_uniforms[aUniformName] intValue];
    else {
        GLint loc = glGetUniformLocation(_program, (const GLchar*)[aUniformName UTF8String]);
        if(loc != -1)
            _uniforms[aUniformName] = @(loc);
        return loc;
    }
}

- (GLint)getAttributeLocation:(NSString *)aAttribName
{
    if(_attributes[aAttribName])
        return [_attributes[aAttribName] intValue];
    else {
        GLint loc = glGetAttribLocation(_program, (const GLchar*)[aAttribName UTF8String]);
        if(loc != -1)
            _attributes[aAttribName] = @(loc);
        return loc;
    }
}

- (void)dealloc
{
    if(_program) {
        glDeleteProgram(_program), _program = 0;;
        glError();
    }
}

- (GLuint)_compileShader:(GLuint *)aoShader
              fromSource:(NSString * const)aSourceStr
                    type:(GLenum const)aShaderType
                   error:(NSError **)aoErr
{
    NSParameterAssert(aoShader && aSourceStr);
    const GLchar * const source = (GLchar *)[aSourceStr UTF8String];
    
    GLuint const shaderObject = glCreateShader(aShaderType);
    glShaderSource(shaderObject, 1, &source, NULL);
    glCompileShader(shaderObject);
    glError();

    GLint logLength = 0;
    glGetShaderiv(shaderObject, GL_INFO_LOG_LENGTH, &logLength);
    NSString *log;
    if(logLength > 0) {
        GLchar *logBuf = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shaderObject, logLength, &logLength, logBuf);
        log = [[NSString alloc] initWithBytesNoCopy:logBuf
                                             length:logLength
                                           encoding:NSUTF8StringEncoding
                                       freeWhenDone:YES];
        NSLog(@">> %@ shader compile log:\n %@",
                 aShaderType == GL_FRAGMENT_SHADER ? @"Fragment" : @"Vertex", log);
    }

    GLint succeeded;
    glGetShaderiv(shaderObject, GL_COMPILE_STATUS, &succeeded);
    if(succeeded == GL_FALSE) {
        if(aoErr)
            *aoErr = [NSError errorWithDomain:STShaderErrorDomain
                                         code:STShaderCompilationError
                                     userInfo:@{
                NSLocalizedDescriptionKey: logLength > 0 ? log : @"Compilation error"
            }];
        NSLog(@">> Failed to compile shader %@", aSourceStr);
        return NO;
    } else {
        *aoShader = shaderObject;
        return YES;
    }
}

- (BOOL)_linkProgram:(NSError **)aoErr
{
    glLinkProgram(_program);
    glError();

    GLint logLength = 0;
    glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLength);
    NSString *log;
    if(logLength > 0) {
        GLchar *logBuf = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_program, logLength, &logLength, logBuf);
        log = [[NSString alloc] initWithBytesNoCopy:logBuf
                                             length:logLength
                                           encoding:NSUTF8StringEncoding
                                       freeWhenDone:YES];
        NSLog(@">> Program link log:\n%@", log);
    }

    GLint succeeded = 0;
    glGetProgramiv(_program, GL_LINK_STATUS, &succeeded);
    if(!succeeded) {
        NSLog(@"Failed to link shader program");
        if(aoErr) {
            *aoErr = [NSError errorWithDomain:STShaderErrorDomain
                                         code:STShaderLinkingError
                                     userInfo:@{
                NSLocalizedDescriptionKey: logLength > 0 ? log : @"Linking error"
            }];
        }
    }
    glError();
    return succeeded;
}

@end
