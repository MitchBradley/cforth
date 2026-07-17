/* ESP32-extra forth.h: wrapper for ESP32 compatibility */
#pragma once

// Include standard headers first
#include <errno.h>
#include <string.h>

// Include core Forth headers
#include "../../src/cforth/config.h"  // Defines cell, token_t, etc.
#include "../../src/cforth/forth.h"   // Core Forth definitions

// ESP32 specific system wrapper
#include "syswrap.h"

// Compatibility macros
// Ensure C macro is defined (may be different from core)
#ifndef C
#define C(cname)  (cell (*)())cname,
#endif

// Type compatibility
// xt_t is already defined in forth.h as token_t*
// Use it as is
