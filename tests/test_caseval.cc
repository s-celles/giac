#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include "gen.h"
#include <cstdio>
#include <cstring>
#include <cstdlib>

struct TestCase {
  const char *input;
  const char *expected;
};

static const TestCase tests[] = {
  // Arithmetic
  {"2+3", "5"},
  {"10-7", "3"},
  {"6*7", "42"},
  {"100/4", "25"},
  {"2^10", "1024"},
  // GCD / LCM
  {"gcd(12,8)", "4"},
  {"lcm(4,6)", "12"},
  // Symbolic
  {"expand((x+1)^2)", "x^2+2*x+1"},
  {"simplify(x^2-1)", "x^2-1"},
  // Type checks
  {"type(42)", "integer"},
  {"type(3.14)", "real"},
};

int main() {
  int failures = 0;
  int total = sizeof(tests) / sizeof(tests[0]);

  for (int i = 0; i < total; ++i) {
    const char *result = giac::caseval(tests[i].input);
    if (std::strcmp(result, tests[i].expected) != 0) {
      std::fprintf(stderr, "FAIL: caseval(\"%s\") = \"%s\", expected \"%s\"\n",
                   tests[i].input, result, tests[i].expected);
      ++failures;
    }
  }

  if (failures == 0) {
    std::printf("All %d tests passed.\n", total);
  } else {
    std::fprintf(stderr, "%d/%d tests failed.\n", failures, total);
  }

  return failures > 0 ? 1 : 0;
}
