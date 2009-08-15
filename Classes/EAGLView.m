//
//  EAGLView.m
//  EKG
//
//  Created by Edward Patel on 2009-08-13.
//  Copyright Memention AB 2009. All rights reserved.
//



#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <math.h>

#import "EAGLView.h"

#define USE_DEPTH_BUFFER 1

// A class extension to declare private methods
@interface EAGLView ()

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) NSTimer *animationTimer;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation EAGLView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;


// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)loadTexture
{
	CGImageRef spriteImage;
	CGContextRef spriteContext;
	GLubyte *spriteData;
	size_t	width, height;
		
	// Creates a Core Graphics image from an image file
	spriteImage = [UIImage imageNamed:@"dot.png"].CGImage;
	// Get the width and height of the image
	width = CGImageGetWidth(spriteImage);
	height = CGImageGetHeight(spriteImage);
	// Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
	// you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.
	
	if(spriteImage) {
		// Allocated memory needed for the bitmap context
		spriteData = (GLubyte *) malloc(width * height * 4);
		// Uses the bitmatp creation function provided by the Core Graphics framework. 
		spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
		// After you create the context, you can draw the sprite image to the context.
		CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), spriteImage);
		// You don't need the context at this point, so you need to release it to avoid memory leaks.
		CGContextRelease(spriteContext);
		
		// Use OpenGL ES to generate a name for the texture.
		glGenTextures(1, &texture);
		// Bind the texture name. 
		glBindTexture(GL_TEXTURE_2D, texture);
		// Speidfy a 2D texture image, provideing the a pointer to the image data in memory
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
		// Release the image data
		free(spriteData);
		
		// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// Enable use of the texture
		glEnable(GL_TEXTURE_2D);
		// Set a blending function to use
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		// Enable blending
		glEnable(GL_BLEND);
	}
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
    
    if ((self = [super initWithCoder:coder])) {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            [self release];
            return nil;
        }
		
		[self loadTexture];
        
        animationInterval = 1.0 / 30.0;

		int i, k = 0;
		
		//for (k=0; k < 30; k++)
		while(k < 10)
		{
			ekgMap[k] = 0.0;
			k++;
		}
		//for (i = (MAX_CURVE_POINT_NO / 6); i < MAX_CURVE_POINT_NO *3/12; i++)
		while (k < 15)
		{
			ekgMap[k] = sin(1.0*_PI*(k-10)/(5))/5;
			k++;
		}
		//for (i = (MAX_CURVE_POINT_NO*3/12); i < MAX_CURVE_POINT_NO*2/6; i++)
		while(k < 17)
		{
			ekgMap[k] = 0.0;
			k++;
		}
		//for (i = (MAX_CURVE_POINT_NO*2/6); i < MAX_CURVE_POINT_NO*9/24; i++)
		while (k < 21)
		{
			ekgMap[k] = -sin(1.0*_PI*(k-17)/(4))/10.0;
			k++;
		}
		while (k < 26)
		{
			ekgMap[k] = sin(1.0*_PI*(k-21)/(5));
			k++;
		}
		while (k < 31)
		{
			ekgMap[k] = - sin(1.0*_PI*(k-26)/(5))/2.0;
			k++;
		}
		while (k < 35)
		{
			ekgMap[k] = 0.0;
			k++;
		}
		while (k < 46)
		{
			ekgMap[k] = sin(1.0*_PI*(k-35)/(11))/8.0;
			k++;
		}
		
		while (k < 180)
		{
			ekgMap[k] = ekgMap [k%45];
			k++;
		}
		
		for (i = 0; i < MAX_CURVE_POINT_NO; i++)
		{
			curve[i] = 0.0;
		}
		
		curveStart = 0;
		
		
    }
    return self;
}

// Sets up an array of values to use as the sprite vertices.
const GLfloat spriteVertices[] = {
-0.7f, -0.7f,
0.7f, -0.7f,
-0.7f,  0.7f,
0.7f,  0.7f,
};

// Sets up an array of values for the texture coordinates.
const GLshort spriteTexcoords[] = {
0, 0,
1, 0,
0, 1,
1, 1,
};

- (void)drawView {
    
    // Replace the implementation of this method to do your own custom drawing
#define GRID_LINES_HORZ 30
#define GRID_LINES_VERT 30
	
	GLfloat lineVertices[MAX_CURVE_POINT_NO*2];
	GLfloat lineVerticesGrid[GRID_LINES_HORZ*GRID_LINES_VERT*4];
	GLfloat lineVerticesGridTexCoords[GRID_LINES_HORZ*GRID_LINES_VERT*4];
	float currLevel = curve[(MAX_CURVE_POINT_NO+curveStart-1)%MAX_CURVE_POINT_NO];
	
	int i;
	for (i=0; i<MAX_CURVE_POINT_NO; i++) {
		lineVertices[i*2] = i/(MAX_CURVE_POINT_NO/2.0)-1.0; // X
		lineVertices[i*2+1] = curve[(i+curveStart)%MAX_CURVE_POINT_NO]; // Y
	}

	for (i=0; i<GRID_LINES_HORZ; i++) {
		float yval = 4.0*i/GRID_LINES_HORZ-2.0;
		lineVerticesGrid[i*4] = -2.0; // X
		lineVerticesGrid[i*4+1] = yval; // Y
		lineVerticesGrid[i*4+2] = 2.0; // X
		lineVerticesGrid[i*4+3] = yval; // Y
		lineVerticesGridTexCoords[i*4] = -2.3/1.4; // X
		lineVerticesGridTexCoords[i*4+1] = (yval-currLevel)/1.4; // Y
		lineVerticesGridTexCoords[i*4+2] = 1.7/1.4; // X
		lineVerticesGridTexCoords[i*4+3] = (yval-currLevel)/1.4+0.7; // Y
	}
	
	for (i=0; i<GRID_LINES_VERT; i++) {
		int j = (GRID_LINES_HORZ+i)*4; 
		float xval = 4.0*i/GRID_LINES_VERT-2.0;
		lineVerticesGrid[j] = 4.0*i/GRID_LINES_VERT-2.0; // X
		lineVerticesGrid[j+1] = -2.0; // Y
		lineVerticesGrid[j+2] = 4.0*i/GRID_LINES_VERT-2.0; // X
		lineVerticesGrid[j+3] = 2.0; // Y
		lineVerticesGridTexCoords[j] = (xval-0.7)/1.4; // X
		lineVerticesGridTexCoords[j+1] = currLevel/1.4+1.4+0.5; // Y
		lineVerticesGridTexCoords[j+2] = (xval-0.7)/1.4+0.7; // X
		lineVerticesGridTexCoords[j+3] = currLevel/1.4-1.4+0.5; // Y
	}
	
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glEnable(GL_DEPTH_TEST);
	//glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POINT_SMOOTH);
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	
	glScalef(0.8, 0.8, 1.0);
	glTranslatef(-0.2, 0, 0);
		
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	glEnable(GL_TEXTURE_2D);

	glVertexPointer(2, GL_FLOAT, 0, spriteVertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glTexCoordPointer(2, GL_SHORT, 0, spriteTexcoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	glPushMatrix();
	glTranslatef(1.0, currLevel, -0.01);
	glColor4f(0.0, 0.5, 1.0, 1.0);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glPopMatrix();
	
    glVertexPointer(2, GL_FLOAT, 0, lineVerticesGrid);
	glEnableClientState(GL_VERTEX_ARRAY);
    
	glTexCoordPointer(2, GL_FLOAT, 0, lineVerticesGridTexCoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	glLineWidth(1.0);
	glColor4f(0.0, 0.4, 0.6, 1.0);
    glDrawArrays(GL_LINES, 0, (GRID_LINES_HORZ+GRID_LINES_VERT)*2);
	
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	
    glVertexPointer(2, GL_FLOAT, 0, lineVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    
	glLineWidth(9.0);
	glPointSize(9.0);
	glColor4f(0.0, 0.5, 1.0, 0.2);
    glDrawArrays(GL_LINE_STRIP, 0, MAX_CURVE_POINT_NO);
	glTranslatef(0, 0, .01);
    glDrawArrays(GL_POINTS, 0, MAX_CURVE_POINT_NO);
	glPointSize(15.0);
	glDrawArrays(GL_POINTS, MAX_CURVE_POINT_NO-1, 1);

	glTranslatef(0, 0, .01);
	
	glLineWidth(3.0);
	glPointSize(3.0);
	glColor4f(0.0, 0.5, 1.0, 0.7);
    glDrawArrays(GL_LINE_STRIP, 0, MAX_CURVE_POINT_NO);
	glTranslatef(0, 0, .01);
    glDrawArrays(GL_POINTS, 0, MAX_CURVE_POINT_NO);
	glPointSize(9.0);
	glDrawArrays(GL_POINTS, MAX_CURVE_POINT_NO-1, 1);

	glTranslatef(0, 0, .01);

	glLineWidth(1.0);
	glPointSize(1.0);
	glColor4f(1.0, 1.0, 1.0, 1.0);
    glDrawArrays(GL_LINE_STRIP, 0, MAX_CURVE_POINT_NO);
	glPointSize(5.0);
	glDrawArrays(GL_POINTS, MAX_CURVE_POINT_NO-1, 1);

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	curve[ curveStart ] =  ekgMap[ curveStart ]; // ((rand()%32768)/32768.0)*0.4-0.2;
	curveStart = (curveStart+1)%MAX_CURVE_POINT_NO;
	
}


- (void)layoutSubviews {
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView];
}


- (BOOL)createFramebuffer {
    
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if (USE_DEPTH_BUFFER) {
        glGenRenderbuffersOES(1, &depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    }
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}


- (void)destroyFramebuffer {
    
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


- (void)startAnimation {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}


- (void)stopAnimation {
    self.animationTimer = nil;
}


- (void)setAnimationTimer:(NSTimer *)newTimer {
    [animationTimer invalidate];
    animationTimer = newTimer;
}


- (void)setAnimationInterval:(NSTimeInterval)interval {
    
    animationInterval = interval;
    if (animationTimer) {
        [self stopAnimation];
        [self startAnimation];
    }
}


- (void)dealloc {
    
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];  
    [super dealloc];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(animationTimer != nil)
		[self stopAnimation];
	else
		[self startAnimation];
}
@end
