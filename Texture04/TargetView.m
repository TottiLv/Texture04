//
//  TargetView.m
//  Texture03
//
//  Created by lvjianxiong on 2020/8/4.
//  Copyright © 2020 lvjianxiong. All rights reserved.
//

#import "TargetView.h"
#import <OpenGLES/ES2/gl.h>

@interface TargetView ()

@property (nonatomic, strong) CAEAGLLayer *myEaglLayer;
@property (nonatomic, strong) EAGLContext *myContext;
@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;
@property (nonatomic, assign) GLuint myPrograme;

@end


@implementation TargetView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (void)layoutSubviews{
    [self setupLayer];
    [self setupContext];
    [self clearShader];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self draw];
}

/*
 重写layerClass，将GLSLView返回的图层从CALayer替换成CAEAGLLayer
 */
+ (Class)layerClass{
    return [CAEAGLLayer class];
}

//1.创建图层
- (void)setupLayer{
    //1.创建特殊图层
    self.myEaglLayer = (CAEAGLLayer *)self.layer;
    //2.设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    //3.设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    /*
    kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
    kEAGLDrawablePropertyColorFormat
        可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
    
        kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
        kEAGLColorFormatRGB565：16位RGB的颜色，
        kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。


    */
    self.myEaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
}

//2.创建上下文
- (void)setupContext{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        NSLog(@"Create context failed！");
        return;
    }
    if (![EAGLContext setCurrentContext:context]){
        NSLog(@"setCurrnetContext failed!");
        return;
    }
    self.myContext = context;
}

//3.清空着色器
- (void)clearShader{
    /*
    buffer分为frame buffer 和 render buffer2个大类。
    其中frame buffer 相当于render buffer的管理者。
    frame buffer object即称FBO。
    render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
    */
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

//4.创建RenderBuffer
- (void)setupRenderBuffer{
    //1.定义一个缓存区ID
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    //3
    self.myColorRenderBuffer = buffer;
    //4.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    //5.将可绘制对象drawable object's  CAEAGLLayer的存储绑定到OpenGL ES renderBuffer对象
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEaglLayer];
}

//5.创建FrameBuffer{
- (void)setupFrameBuffer{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    /*
     生成帧缓存区之后，则需要将renderbuffer跟framebuffer进行绑定，
    调用glFramebufferRenderbuffer函数进行绑定到对应的附着点上，后面的绘制才能起作用
    */
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

//6.开始渲染
- (void)draw{
    //1.设置清屏颜色
    glClearColor(0.1f, 0.3f, 0.2f, 1.0f);
    //2.清除屏幕
    glClear(GL_COLOR_BUFFER_BIT);
    //3.设置适口大小
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x*scale, self.frame.origin.y*scale, self.frame.size.width*scale, self.frame.size.height*scale);
    //4.读取顶点着色程序，片元着色程序
    /*
     关于顶点/片元文件详解
     https://blog.csdn.net/Since_lily/article/details/86718670
     */
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    //5.加载shader
    self.myPrograme = [self loadShaders:vertFile withFrag:fragFile];
    //6.链接program
    glLinkProgram(self.myPrograme);
    GLuint linkStatus;
    //获取链接状态
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[512];
        glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error: %@",messageString);
        return;
    }
    //7.使用program
    glUseProgram(self.myPrograme);
    //8.添加数据(顶点、纹理坐标)
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    //处理顶点数据
    //(1)顶点缓存区
    GLuint attrBuffer;
    //(2)申请一个缓存区标识符
    glGenBuffers(1, &attrBuffer);
    //(3)将attrBuffer绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    //(4)把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //8.将顶点数据通过myPrograme传递到顶点着色程序的position
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, sizeof(NULL)*0);
    
    //处理纹理数据
    GLuint textColor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    glEnableVertexAttribArray(textColor);
    glVertexAttribPointer(textColor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL+3);
    
    //9.加载纹理
    [self setupTexture:@"IMG_0195"];
    //10.传递纹理采样器
    glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    
    //11.绘图
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //12.从渲染缓存区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

#pragma mark- private
- (GLuint)loadShaders:(NSString *)vert withFrag:(NSString *)frag{
    //1.定义2个临时着色器对象
    GLuint verShader, fragShader;
    //创建program
    GLuint program = glCreateProgram();
    //2.编译顶点着色程序、片元着色程序
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    //3.将着色器附加到program
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    //4.释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //1.读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    //2.创建一个shader（根据type类型创建）
    *shader = glCreateShader(type);
    //3.将着色器源码附加到着色器对象上
    /*
     参数1：shader,要编译的着色器对象 *shader
     参数2：numOfStrings,传递的源码字符串数量 1个
     参数3：strings,着色器程序的源码（真正的着色器程序源码）
     参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
     */
    glShaderSource(*shader, 1, &source, NULL);
    //4.把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

- (GLuint)setupTexture: (NSString *)fileName{
    //1.将UIImage转换为CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    //判断图片是否获取成功
    if (!spriteImage) {
        NSLog(@"Failed to load image %@",fileName);
        exit(1);
    }
    //2.读取图片的大小；宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    //3.获取图片字节数 width*height*4
    GLubyte *spriteData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    //4.创建上下文
    /*
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的每一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
    */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    //5.在CGContextRef上，将图片绘制出来
    /*
    CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
    CGContextDrawImage
    参数1：绘图上下文
    参数2：rect坐标
    参数3：绘制的图片
    */
    CGRect rect = CGRectMake(0, 0, width, height);
    //6.使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //7.画图完毕就释放上下文
    CGContextRelease(spriteContext);
    //8.绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 0);
    //9.设置纹理属性
    /*
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //10.载入纹理2D数据
    /*
    参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
    参数2：加载的层次，一般设置为0
    参数3：纹理的颜色值GL_RGBA
    参数4：宽
    参数5：高
    参数6：border，边界宽度
    参数7：format
    参数8：type
    参数9：纹理数据
    */
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    //11.释放spriteData
    free(spriteData);
    return 0;
    
}

@end


