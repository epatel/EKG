This is a small project written very quickly trying to show some OpenGLES tricks to draw an EKG curve on an iPhone

* The curve is drawn three times with different colors and width

* Each vertex is also drawn as a point to get a smoother line

* A texture is used to draw the halo and also used when drawing the lit grid

* GL_LINE_SMOOTH does not exist in pre-3GS devices. FBO could perhaps be used to create a nicer line
