# ── Unit tests (link against libgiac, no GUI needed) ──────────────────────────

test_caseval = executable('test_caseval',
  'test_caseval.cc',
  include_directories: [giac_inc, config_inc],
  dependencies: libgiac_dep,
  cpp_args: giac_common_args,
)

test('caseval', test_caseval, suite: 'unit', timeout: 60)
