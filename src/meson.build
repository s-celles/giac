# ── Flex/Bison parser sources ─────────────────────────────────────────────────

if get_option('regen_parser')
  flex = find_program('flex', required: true)
  bison = find_program('bison', required: true)

  parser_cc = custom_target('input_parser',
    input: 'input_parser.yy',
    output: ['input_parser.cc', 'input_parser.h'],
    command: [bison, '-p', 'giac_yy', '-y', '-d', '@INPUT@',
              '--output=@OUTPUT0@', '--defines=@OUTPUT1@'],
  )

  lexer_cc = custom_target('input_lexer',
    input: 'input_lexer.ll',
    output: 'input_lexer.cc',
    command: [flex, '-o', '@OUTPUT@', '@INPUT@'],
  )
else
  parser_cc = files('input_parser.cc')
  lexer_cc = files('input_lexer.cc')
endif

# ── libgiac source files ─────────────────────────────────────────────────────

giac_core_sources = files(
  'sym2poly.cc', 'gausspol.cc', 'threaded.cc', 'moyal.cc',
  'maple.cc', 'ti89.cc', 'mathml.cc', 'misc.cc',
  'permu.cc', 'quater.cc', 'desolve.cc', 'symbolic.cc',
  'index.cc', 'modpoly.cc', 'modfactor.cc', 'ezgcd.cc',
  'derive.cc', 'solve.cc', 'intg.cc', 'intgab.cc',
  'risch.cc', 'lin.cc', 'series.cc', 'subst.cc',
  'vecteur.cc', 'sparse.cc', 'csturm.cc', 'tex.cc',
  'global.cc', 'ifactor.cc', 'alg_ext.cc', 'gauss.cc',
  'isom.cc', 'plot.cc', 'plot3d.cc', 'rpn.cc',
  'prog.cc', 'pari.cc', 'cocoa.cc', 'unary.cc',
  'usual.cc', 'identificateur.cc', 'gen.cc', 'tinymt32.cc',
  'first.cc', 'TmpLESystemSolver.C', 'TmpFGLM.C', 'help.cc',
  'lpsolve.cc', 'optimization.cc', 'signalprocessing.cc',
  'graphe.cc', 'graphtheory.cc', 'nautywrapper.c',
  'markup.cc', 'kdisplay.cc', 'kadd.cc',
  'caseval.c', 'cutils.c', 'graphic.c',
  'qrcodegen.c',
)

giac_sources = [parser_cc, lexer_cc] + giac_core_sources

# Conditional: QuickJS sources
quickjs_enabled = not get_option('quickjs').disabled()
if quickjs_enabled
  giac_sources += files(
    'quickjs.c', 'quickjs-libc.c', 'qjsgiac.c', 'js.c',
  )
  giac_common_args += ['-DQUICKJS', '-DCONFIG_BIGNUM', '-DCONFIG_VERSION="2021-03-27"']
endif

# Conditional: libbf sources (enabled with QuickJS or standalone)
libbf_enabled = not get_option('libbf').disabled() or quickjs_enabled
if libbf_enabled
  giac_sources += files(
    'libbf.c', 'libregexp.c', 'libunicode.c',
  )
endif

# ── Build libgiac ────────────────────────────────────────────────────────────

giac_inc = include_directories('.')

giac_deps = [mpfr_dep, gmp_dep] + optional_deps

libgiac = both_libraries('giac',
  giac_sources,
  include_directories: [giac_inc, config_inc],
  dependencies: giac_deps,
  c_args: giac_common_args,
  cpp_args: giac_common_args,
  install: true,
  version: '0.0.0',
  soversion: '0',
)

libgiac_dep = declare_dependency(
  link_with: libgiac,
  include_directories: [giac_inc, config_inc],
  dependencies: [mpfr_dep, gmp_dep],
)

# ── hevea2mml (standalone, no libgiac dependency) ────────────────────────────

executable('hevea2mml',
  files('hevea2mml.cc', 'lex_yy.c', 'y_tab.c'),
  include_directories: [giac_inc, config_inc],
  install: true,
)

# ── Optional GUI support for icas/aide (external libxcas + FLTK) ─────────────

build_gui = false
fltk_dep = dependency('', required: false)
xcas_dep = dependency('', required: false)

if not get_option('gui').disabled()
  # Try to find external libxcas (installed from xcas repo)
  xcas_dep = dependency('xcas', required: false)
  if not xcas_dep.found()
    _xcas_extra_dirs = []
    if host_machine.system() == 'darwin'
      _xcas_extra_dirs = ['/opt/homebrew/lib', '/usr/local/lib']
    endif
    _xcas_lib = cc.find_library('xcas', required: false, dirs: _xcas_extra_dirs)
    if _xcas_lib.found()
      xcas_dep = _xcas_lib
    endif
  endif

  # Try system FLTK via fltk-config
  fltk_dep = dependency('fltk', method: 'config-tool', required: false)
  if not fltk_dep.found()
    fltk_dep = dependency('fltk', required: get_option('gui'))
  endif

  # Find xcas headers (installed to <prefix>/include/xcas/)
  if xcas_dep.found() and xcas_dep.type_name() != 'pkgconfig'
    # Manual detection — add include path for xcas headers
    _xcas_inc_args = []
    if host_machine.system() == 'darwin'
      _xcas_inc_args = ['-I/opt/homebrew/include/xcas', '-I/usr/local/include/xcas']
    else
      _xcas_inc_args = ['-I/usr/include/xcas']
    endif
    xcas_dep = declare_dependency(
      dependencies: xcas_dep,
      compile_args: _xcas_inc_args,
    )
  endif

  if fltk_dep.found() and xcas_dep.found()
    build_gui = true
  elif fltk_dep.found() and not xcas_dep.found()
    warning('FLTK found but libxcas not found — icas will be built without GUI support. ' +
            'Install xcas (https://github.com/s-celles/xcas) for graph output.')
  endif
endif

# ── icas and aide ─────────────────────────────────────────────────────────────

if build_gui
  gl_dep = dependency('gl', required: false)
  x11_dep = dependency('x11', required: false)

  gui_args = giac_common_args + ['-DHAVE_LIBFLTK']
  if gl_dep.found()
    gui_args += ['-DHAVE_LIBFLTK_GL']
  endif

  gui_deps = [libgiac_dep, xcas_dep, fltk_dep]
  if gl_dep.found()
    gui_deps += gl_dep
  endif
  if x11_dep.found()
    gui_deps += x11_dep
  endif
  if readline_dep.found()
    gui_deps += readline_dep
  endif

  executable('icas',
    files('icas.cc'),
    dependencies: gui_deps,
    c_args: gui_args,
    cpp_args: gui_args,
    install: true,
  )

  executable('aide',
    files('aide.cc'),
    dependencies: [libgiac_dep, xcas_dep, fltk_dep],
    c_args: gui_args,
    cpp_args: gui_args,
    install: true,
  )
else
  # CLI-only icas and aide (no FLTK, no libxcas)
  icas_deps = [libgiac_dep]
  if readline_dep.found()
    icas_deps += readline_dep
  endif
  if host_machine.system() == 'windows'
    _intl_dep = cc.find_library('intl', required: false)
    if _intl_dep.found()
      icas_deps += _intl_dep
    endif
  endif
  executable('icas',
    files('icas.cc'),
    dependencies: icas_deps,
    c_args: giac_common_args,
    cpp_args: giac_common_args,
    install: true,
  )

  aide_deps = [libgiac_dep]
  if host_machine.system() == 'windows' and _intl_dep.found()
    aide_deps += _intl_dep
  endif
  executable('aide',
    files('aide.cc'),
    dependencies: aide_deps,
    c_args: giac_common_args,
    cpp_args: giac_common_args,
    install: true,
  )
endif

# ── Test suite (runs whenever icas is available) ──────────────────────────────

check_dir = meson.current_source_dir() / '..' / 'check'

# Script-based tests that run icas with .cas input and diff against .out
check_tests = {
  'factor': 'testfactor',
  'normalize': 'testnormalize',
  'partfrac': 'testpartfrac',
  'limit': 'testlimit',
  'cas': 'testcas',
  'geo': 'testgeo',
}

icas_exe = meson.current_build_dir() / 'icas'

foreach name, input : check_tests
  # Create a wrapper test file that resets python_compat(0) to ensure
  # ^ notation (not **) regardless of user config or runtime defaults,
  # then strip its extra output line with tail.
  test(name,
    find_program('sh'),
    args: ['-c',
      'printf "python_compat(0):;\\n" > ' + name + '.in && ' +
      'cat ' + check_dir / input + ' >> ' + name + '.in && ' +
      icas_exe + ' ' + name + '.in > ' + name + '.raw && ' +
      'tail -n +2 ' + name + '.raw > ' + name + '.tst && ' +
      'diff ' + name + '.tst ' + check_dir / name + '.out',
    ],
    workdir: meson.current_build_dir(),
    timeout: 120,
    suite: 'check',
    env: {'HOME': meson.current_build_dir()},
  )
endforeach

# ── JNI bindings (libjavagiac) ───────────────────────────────────────────────

build_jni = false

_skip_jni = get_option('jni').disabled() or host_machine.system() == 'emscripten'
if not _skip_jni
  # Determine platform-specific JDK header subdirectory
  _jni_platform_dir = 'linux'
  if host_machine.system() == 'darwin'
    _jni_platform_dir = 'darwin'
  elif host_machine.system() == 'windows'
    _jni_platform_dir = 'win'
  endif

  _jni_base = meson.current_source_dir() / 'jni' / 'jdkHeaders'

  # Check if vendored headers exist
  if cc.has_header('jni.h', args: '-I' + _jni_base)
    jni_header_inc = include_directories('jni/jdkHeaders', 'jni/jdkHeaders' / _jni_platform_dir)
    build_jni = true
  else
    # Try system JNI
    jni_dep_check = dependency('jni', required: get_option('jni'))
    if jni_dep_check.found()
      jni_header_inc = include_directories()
      build_jni = true
    endif
  endif
endif

if build_jni
  # Verify giac_wrap.cxx is in sync with current API before building.
  # The SWIG-generated wrapper may reference removed methods (e.g. printcharptr).
  _wrap_check = cxx.compiles('''
    #include "gen.h"
    void test() { giac::gen g; (void)g.print(); }
  ''',
    name: 'giac_wrap.cxx API compatibility',
    include_directories: [giac_inc, config_inc],
    args: giac_common_args,
    dependencies: [mpfr_dep, gmp_dep],
  )
  # Also check the wrapper itself compiles (quick syntax check of a known symbol)
  _wrap_file_ok = run_command('grep', '-q', 'printcharptr', files('giac_wrap.cxx'),
    check: false,
  ).returncode() != 0  # If printcharptr is NOT found, wrapper is probably regenerated

  if not _wrap_file_ok
    warning('giac_wrap.cxx references removed API (printcharptr). ' +
            'JNI bindings skipped. Regenerate with: swig -c++ -java -package javagiac giac.i')
    build_jni = false
  endif
endif

if build_jni
  javagiac_link_args = []

  if host_machine.system() == 'darwin'
    javagiac_link_args = ['-framework', 'CoreFoundation', '-lc++', '-lpthread']
  elif host_machine.system() == 'linux'
    javagiac_link_args = ['-static-libgcc', '-static-libstdc++']
  elif host_machine.system() == 'windows'
    javagiac_link_args = ['-Wl,--add-stdcall-alias', '-static-libgcc', '-static-libstdc++', '-static']
  elif host_machine.system() == 'android'
    javagiac_link_args = ['-s']
  endif

  shared_library('javagiac',
    files('giac_wrap.cxx'),
    include_directories: [giac_inc, config_inc, jni_header_inc],
    link_with: libgiac.get_static_lib(),
    dependencies: giac_deps,
    c_args: giac_common_args,
    cpp_args: giac_common_args,
    link_args: javagiac_link_args,
    install: true,
  )
endif

# ── MicroPython (optional, disabled by default) ──────────────────────────────

micropython_enabled = false

if get_option('micropython').enabled()
  micropython_dir = meson.current_source_dir() / '..' / 'micropython'
  fs = import('fs')
  if not fs.is_dir(micropython_dir / 'py')
    error('MicroPython submodule not initialized. Run: git submodule update --init')
  endif
  make_prog = find_program('make', required: true)

  micropython_lib = custom_target('micropython',
    output: 'libmicropython.a',
    command: [make_prog, '-C', micropython_dir / 'unix',
      'CC=' + cc.cmd_array()[0],
      'libmicropython.a',
    ],
    build_by_default: true,
  )

  micropython_dep = declare_dependency(
    sources: micropython_lib,
    include_directories: include_directories('..' / 'micropython'),
  )

  micropython_enabled = true
  cdata.set('HAVE_LIBMICROPYTHON', 1)
endif

# ── Summaries ────────────────────────────────────────────────────────────────

summary({
  'JNI bindings': build_jni,
}, section: 'Bindings', bool_yn: true)

summary({
  'QuickJS': quickjs_enabled,
  'libbf': libbf_enabled,
  'MicroPython': micropython_enabled,
  'Flex/Bison regen': get_option('regen_parser'),
}, section: 'Build options', bool_yn: true)
