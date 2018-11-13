#include "__fc_builtin.h"

#include "wchar.c"

#include "string.c"

#include "stdio.c"

#include <stdlib.h>

int abs (int i) {
  if (i < 0)
    return -i;
  return i;
}

long labs (long i) {
  if (i < 0L)
    return -i;
  return i;
}

long long llabs (long long i) {
  if (i < 0LL)
    return -i;
  return i;
}

#include "math.c"
