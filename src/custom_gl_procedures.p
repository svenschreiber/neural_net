glDetachShader: PFNGLDETACHSHADERPROC;
glGetShaderiv: PFNGLGETSHADERIVPROC;
glGetProgramiv: PFNGLGETPROGRAMIVPROC;
glUniform4fv: PFNGLUNIFORM4FVPROC;
glUniform2fv: PFNGLUNIFORM2FVPROC;
glActiveTexture: PFNGLACTIVETEXTUREPROC;

wglSwapIntervalEXT: PFNWGLSWAPINTERVALEXTPROC; 

load_custom_gl_procedures :: () {
    glDetachShader = xx load_gl_procedure("glDetachShader");
	glGetShaderiv = xx load_gl_procedure("glGetShaderiv");
    glGetProgramiv = xx load_gl_procedure("glGetProgramiv");
    glUniform4fv = xx load_gl_procedure("glUniform4fv");
    glUniform2fv = xx load_gl_procedure("glUniform2fv");
    glActiveTexture = xx load_gl_procedure("glActiveTexture");
    wglSwapIntervalEXT = xx load_gl_procedure("wglSwapIntervalEXT");
}