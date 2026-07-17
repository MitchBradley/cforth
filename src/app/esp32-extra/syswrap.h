// ~/cf_551/cforth/src/app/esp32-extra/syswrap.h - FINALE VERSIE
#pragma once
#ifndef SYSWRAP_H
#define SYSWRAP_H

// SIMPELE OPLOSSING: cell = int voor ESP32
// Dit voorkomt alle type conflicts
typedef int cell;
typedef unsigned int ucell;

int alsystem(char *path, cell arg);
int alchdir(char *path, cell arg);
void prerror(const char *msg, cell *up);

#endif
