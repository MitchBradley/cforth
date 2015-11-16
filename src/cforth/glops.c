// OpenGL2 interface

#include "forth.h"

#ifdef USE_GLEW
#include <GL/glew.h>
#endif

#define GLFW_INCLUDE_GLEXT
#define GLFW_INCLUDE_GLU
#include <GLFW/glfw3.h>

#include "glops.h"
#include <math.h>
#include <stdio.h>

void glop(int op, cell **i, double **f, cell *up)
{
  switch (op) {
    case GLBEGIN: //g glBegin  ( i.mode -- )
      glBegin((int)(*i)[0]);
      *i += 1;
      return;
    case GLEND:  //g glEnd ( -- )
      glEnd();
      return;
    case GLCALLLIST: //g glCallList ( i.list# -- )
      glCallList((int)(*i)[0]);
      *i += 1;
      return;
    case GLCLEARCOLOR: //g glClearColor ( f.alpha f.blue f.red f.green -- )
      glClearColor((float)*f[0], (float)(*f)[1], (float)(*f)[2], (float)(*f)[3]);
      *f += 4;
      return;
    case GLCLEAR: //g glClear ( i.mask -- )
      glClear((int)(*i)[0]);
      *i += 1;
      return;
    case GLCLEARDEPTH: //g glClearDepth ( d.depth -- )
      glClearDepth((*f)[0]);
      *f += 1;
      return;
    case GLDEPTHFUNC: //g glDepthFunc ( i.func -- )
      glDepthFunc((int)(*i)[0]);
      *i += 1;
      return;
    case GLCOLOR3: //g glColor3 ( d.blue d.green d.red -- )
      glColor3d((*f)[0], (*f)[1], (*f)[2]);
      *f += 3;
      return;
    case GLCOLOR4: //g glColor4 ( d.alpha d.blue d.green d.red -- )
      glColor4d((*f)[0], (*f)[1], (*f)[2], (*f)[3]);
      *f += 4;
      return;
    case GLENABLE: //g glEnable ( i.cap -- )
      glEnable((*i)[0]);
      *i += 1;
      return;
    case GLDISABLE: //g glDisable ( i.cap -- )
      glDisable((*i)[0]);
      *i += 1;
      return;
    case GLNEWLIST: //g glNewList  ( i.mode i.list -- )
      glNewList((*i)[0], (*i)[1]);
      *i += 2;
      return;
    case GLENDLIST: //g glEndList ( -- )
      glEndList();
      return;
    case GLFLUSH: //g glFlush  ( -- )
      glFlush();
      return;
    case GLGETBOOLEANV:  //g glGetBooleanv  ( a.where i.which -- )
      glGetBooleanv((*i)[0], (void *)(*i)[1]);;
      *i += 2;
      return;
    case GLGETDOUBLEV:  //g glGetDoublev  ( a.where i.which -- )
      glGetDoublev((*i)[0], (void *)(*i)[1]);
      *i += 2;
      return;
    case GLGETFLOATV:  //g glGetFloatv  ( a.where i.which -- )
      glGetFloatv((*i)[0], (void *)(*i)[1]);
      *i += 2;
      return;
    case GLGETINTEGERV:  //g glGetIntegerv  ( a.where i.which -- )
     glGetIntegerv((*i)[0], (void *)(*i)[1]);
      *i += 2;
      return;
    case GLINITNAMES: //g glInitNames  ( -- )
      glInitNames();
      return;
    case GLLIGHTF: //g glLightf ( f.param i.pname i.light -- )
      glLightf((*i)[0], (*i)[1], (*f)[0]);
      *i += 2;
      *f += 1;
      return;
    case GLLIGHTI: //g glLighti ( i.param i.pname i.light -- )
      glLighti((*i)[0], (*i)[1], (*i)[2]);
      *i += 3;
      return;
    case GLLIGHTFV: //g glLightfv ( a.fparam i.pname i.light -- )
      glLightfv((*i)[0], (*i)[1], (void *)(*i)[2]);
      *i += 3;
      return;
    case GLLIGHTIV: //g glLightiv ( a.iparam i.pname i.light -- )
      glLightiv((*i)[0], (*i)[1], (void *)(*i)[2]);
      *i += 3;
      return;
    case GMATERIALFV: //g glMaterialfv ( a.fparam i.pname i.light -- )
      glMaterialfv((*i)[0], (*i)[1], (void *)(*i)[2]);
      *i += 3;
      return;
    case GMATERIALIV: //g glMaterialiv ( a.iparam i.pname i.light -- )
      glMaterialiv((*i)[0], (*i)[1], (void *)(*i)[2]);
      *i += 3;
      return;
    case GMATERIALI: //g glMateriali ( i.param i.pname i.light -- )
      glMateriali((*i)[0], (*i)[1], (*i)[2]);
      *i += 3;
      return;
    case GLSHADEMODEL: //g glShadeModel  ( i.model -- )
      glShadeModel((*i)[0]);
      *i += 1;
      return;
    case GLFRONTFACE: //g glFrontFace  ( i.winding -- )
      glFrontFace((*i)[0]);
      *i += 1;
      return;
    case GLLINEWIDTH: //g glLineWidth ( f.width -- )
      glLineWidth((float)(*f)[0]);
      *f += 1;
      return;
    case GLLOADIDENTITY: //g glLoadIdentity ( -- )
      glLoadIdentity();
      return;
    case GLLOADNAME: //g glLoadName ( i.name -- )
      glLoadName((*i)[0]);
      *i += 1;
      return;
    case GLMATRIXMODE: //g glMatrixMode  ( i.mode -- )
      glMatrixMode((*i)[0]);
      *i += 1;
      return;
    case GLORTHO: //g glOrtho ( d.far d.near d.top d.bottom d.right d.left -- )
      glOrtho((*f)[0], (*f)[1], (*f)[2], (*f)[3], (*f)[4], (*f)[5]);
      *f += 6;
      return;
    case GLPOINTSIZE: //g glPointSize ( f.size -- )
      glPointSize((float)(*f)[0]);
      *f += 1;
      return;
    case GLPUSHMATRIX: //g glPushMatrix ( -- )
      glPushMatrix();
      return;
    case GLPOPMATRIX: //g glPopMatrix ( -- )
      glPopMatrix();
      return;
    case GLPUSHNAME: //g glPushName ( i.name -- )
      glPushName((*i)[0]);
      *i += 1;
      return;
    case GLPOPNAME: //g glPopName ( - )
      glPopName();
      return;
    case GLRENDERMODE: //g glRenderMode ( i.mode -- )
      glRenderMode((*i)[0]);
      *i += 1;
      return;
    case GLSELECTBUFFER: //g glSelectBuffer ( a.buf i.size -- )
      glSelectBuffer((*i)[0], (GLuint *)(*i)[1]);
      *i += 2;
      return;
    case GLVERTEX2D: //g glVertex2d ( d.y d.x -- )
      glVertex2d((*f)[0], (*f)[1]);
      *f += 2;
      return;
    case GLVERTEX3D: //g glVertex3d ( d.z d.y d.x -- )
      glVertex3d((*f)[0], (*f)[1], (*f)[2]);
      *f += 3;
      return;
    case GLVERTEX4: //g glVertex4d ( d.w d.z d.y d.x -- )
      glVertex4d((*f)[0], (*f)[1], (*f)[2], (*f)[3]);
      *f += 4;
      return;
    case GLVERTEX2I: //g glVertex2i ( i.y i.x -- )
      glVertex2i((*i)[0], (*i)[1]);
      *i += 2;
      return;
    case GLVERTEX3I: //g glVertex3i ( i.z i.y i.x -- )
      glVertex3i((*i)[0], (*i)[1], (*i)[2]);
      *i += 3;
      return;
    case GLVERTEX4I: //g glVertex4i ( i.w i.z i.y i.x -- )
      glVertex4i((*i)[0], (*i)[1], (*i)[2], (*i)[3]);
      *i += 4;
      return;
    case GLVIEWPORT: //g glViewport ( i.height i.width i.y i.x -- )
      glViewport((*i)[0], (*i)[1], (*i)[2], (*i)[3]);
      *i += 4;
      return;
    case GLROTATE: //g glRotate ( d.z d.y d.x d.angle -- )
      glRotatef((*f)[0], (*f)[1], (*f)[2], (*f)[3]);
      *f += 4;
      return;
    case GLFRUSTUM: //g glFrustum  ( d.far d.near d.top d.bottom d.right d.left -- )
      glFrustum((*f)[0], (*f)[1], (*f)[2], (*f)[3], (*f)[4], (*f)[5]);
      *f += 6;
      return;
    case GLSCALE: //g glScale ( d.z d.y d.x -- )
      glScaled((*f)[0], (*f)[1], (*f)[2]);
      *f += 3;
      return;
    case GLTRANSLATE: //g glTranslate ( d.z d.y d.x -- )
      glTranslated((*f)[0], (*f)[1], (*f)[2]);
      *f += 3;
      return;

    case GLDRAWARRAYS: //g glDrawArrays  ( i.count i.first i.mode -- )
      glDrawArrays((*i)[0], (*i)[1], (*i)[2]);
      *i += 3;
      return;
    case GLDRAWELEMENTS: //g glDrawElements  ( a.start i.datatype i.count i.mode -- )
      glDrawElements((*i)[0], (*i)[1], (*i)[2], (GLvoid *)(*i)[3]);
      *i += 4;
      return;

    case GLVERTEXPOINTER: //g glVertexPointer  ( a.ptr i.stride i.type i.size -- )
      glVertexPointer((*i)[0], (*i)[1], (*i)[2], (GLvoid *)(*i)[3]);
      *i += 4;
      return;

    case GLNORMALPOINTER: //g glNormalPointer  ( a.ptr i.stride i.type -- )
      glNormalPointer((*i)[0], (*i)[1], (GLvoid *)(*i)[2]);
      *i += 3;
      return;

    case GLCOLORPOINTER: //g glColorPointer  ( a.ptr i.stride i.type i.size -- )
      glColorPointer((*i)[0], (*i)[1], (*i)[2], (GLvoid *)(*i)[3]);
      *i += 4;
      return;
    case GLEnableClientState: //g glEnableClientState  ( i.type -- )
      glEnableClientState((*i)[0]);
      *i += 1;
      return;
    case GLDisableClientState: //g glDisableClientState  ( i.type -- )
      glDisableClientState((*i)[0]);
      *i += 1;
      return;

    case GLBUFFERDATA: //g glBufferData  ( i.usage a.vertices i.size i.target -- )
      glBufferData((*i)[0], (*i)[1], (GLvoid *)(*i)[2], (*i)[3]);
      *i += 4;
      return;
    case GLBINDBUFFER: //g glBindBuffer ( a.buffer i.mode -- )
      glBindBuffer((*i)[0], (*i)[1]);
      *i += 2;
      return;
    case GLENABLEVERTEXATTRIBARRAY: //g glEnableVertexAttribArray ( i.mode -- )
      glEnableVertexAttribArray((*i)[0]);
      *i += 1;
      return;
    case GLDISABLEVERTEXATTRIBARRAY: //g glDisableVertexAttribArray ( i.mode -- )
      glDisableVertexAttribArray((*i)[0]);
      *i += 1;
      return;
    case GLVERTEXATTRIBPOINTER: //g glVertexAttribPointer  ( a.ptr i.stride i.normalized i.type i.size i.index -- )
      glVertexAttribPointer((*i)[0], (*i)[1], (*i)[2], (*i)[3], (*i)[4], (void *)(*i)[5]);
      *i += 6;
      return;
    case GLGENBUFFERS: //g glGenBuffers ( a.vbuf i.n -- )
      glGenBuffers((*i)[0], (GLuint *)(*i)[1]);
      *i += 2;
      return;
    case GLGENTEXTURES: //g glGenTextures ( a.vbuf i.n -- )
      glGenTextures((*i)[0], (GLuint *)(*i)[1]);
      *i += 2;
      return;
    case GLBINDTEXTURE: //g glBindTexture ( i.texture i.type -- )
      glBindTexture((*i)[0], (*i)[1]);
      *i += 2;
      return;
    case GLTEXPARAMETERI: //g glTexParameteri ( i.param i.name i.target -- )
      glTexParameteri((*i)[0], (*i)[1], (*i)[2]);
      *i += 3;
      return;
    case GLGETTEXPARAMETERIV: //g glGetTexParameteriv ( a.param i.name i.target -- )
      glTexParameteriv((*i)[0], (*i)[1], (GLvoid *)(*i)[2]);
      *i += 3;
      return;
    case GLTEXPARAMETERF: //g glTexParameterf ( f.param i.name i.target -- )
      glTexParameteri((*i)[0], (*i)[1], (*f)[0]);
      *i += 2;
      *f += 1;
      return;
    case GLTEXIMAGE2D: //g glTexImage2D ( a.data i.type i.format i.border i.height i.width i.intformat i.level i.target )
      glTexImage2D((*i)[0], (*i)[1], (*i)[2], (*i)[3], (*i)[4], (*i)[5], (*i)[6], (*i)[7], (const GLvoid *)(*i)[8]);
      *i += 9;
      return;
    case GLTEXCOORD2F: //g glTexCoord2F ( f.v f.u -- )
      glTexCoord2f((*f)[0], (*f)[1]);
      *f += 2;
      return;
    case GLPIXELSTOREI: //g glPixelStorei ( i.value i.name -- )
      glPixelStorei((*i)[0], (*i)[1]);
      *i += 2;
      return;
    case GLULOOKAT: //g gluLookAt ( d.upz d.upy d.upx d.centerz d.centery d.centerx d.eyez d.eyey d.eyex -- )
      gluLookAt((*f)[0], (*f)[1], (*f)[2], (*f)[3], (*f)[4], (*f)[5], (*f)[6], (*f)[7], (*f)[8]);
      *f += 9;
      return;
  }
  return;
}
