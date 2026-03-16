# ── Unit tests (link against libgiac, no GUI needed) ──────────────────────────

test_deps = [libgiac_dep]

# On MSYS2/MinGW, printf/fprintf redirect through libintl
if host_machine.system() == 'windows'
  intl_test_dep = cc.find_library('intl', required: false)
  if intl_test_dep.found()
    test_deps += intl_test_dep
  endif
endif

test_caseval = executable('test_caseval',
  'test_caseval.cc',
  include_directories: [giac_inc, config_inc],
  dependencies: test_deps,
  cpp_args: giac_common_args,
)

test('caseval', test_caseval, suite: 'unit', timeout: 60)
