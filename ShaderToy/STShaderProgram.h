#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>

static NSString * const STShaderErrorDomain = @"STShaderErrorDomain";
typedef NS_ENUM(NSInteger, STShaderErrorCode) {
    STShaderUnknownError,
    STShaderCompilationError,
    STShaderLinkingError
};

@interface STShaderProgram : NSObject
@property(nonatomic, readonly, nonatomic) GLuint program;

- (BOOL)attachShaderOfType:(GLenum)aShaderType
                    source:(NSString *)aSrc
                     error:(NSError **)aoErr;

- (GLint)getUniformLocation:(NSString *)aUniformName;
- (GLint)getAttributeLocation:(NSString *)aAttribName;
@end
