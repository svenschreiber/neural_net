glDetachShader: PFNGLDETACHSHADERPROC;
glGetShaderiv: PFNGLGETSHADERIVPROC;
glDeleteProgram: PFNGLDELETEPROGRAMPROC; 
glGetProgramiv: PFNGLGETPROGRAMIVPROC;
glUniformMatrix4fv: PFNGLUNIFORMMATRIX4FVPROC;
glUniform1f: PFNGLUNIFORM1FPROC;
glUniform4fv: PFNGLUNIFORM4FVPROC;
glUniform2fv: PFNGLUNIFORM2FVPROC;

wglSwapIntervalEXT: PFNWGLSWAPINTERVALEXTPROC; 

load_custom_gl_procedures :: () {
    glDetachShader = xx load_gl_procedure("glDetachShader");
	glGetShaderiv = xx load_gl_procedure("glGetShaderiv");
    glDeleteProgram = xx load_gl_procedure("glDeleteProgram");
    glGetProgramiv = xx load_gl_procedure("glGetProgramiv");
    glUniformMatrix4fv = xx load_gl_procedure("glUniformMatrix4fv");
    glUniform1f = xx load_gl_procedure("glUniform1f");
    glUniform4fv = xx load_gl_procedure("glUniform4fv");
    glUniform2fv = xx load_gl_procedure("glUniform2fv");
    wglSwapIntervalEXT = xx load_gl_procedure("wglSwapIntervalEXT");
}