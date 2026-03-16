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

# ── GUI targets (xcas, icas, aide) ───────────────────────────────────────────

build_gui = false
fltk_dep = dependency('', required: false)

if not get_option('gui').disabled()
  # Try system FLTK via fltk-config
  fltk_dep = dependency('fltk', method: 'config-tool', required: false)

  if not fltk_dep.found()
    # Try pkg-config
    fltk_dep = dependency('fltk', required: get_option('gui'))
  endif

  if fltk_dep.found()
    build_gui = true
  endif
endif

if build_gui
  # Optional GL and X11 for GUI
  gl_dep = dependency('gl', required: false)
  x11_dep = dependency('x11', required: false)

  gui_deps = [libgiac_dep, fltk_dep]
  if gl_dep.found()
    gui_deps += gl_dep
  endif
  if x11_dep.found()
    gui_deps += x11_dep
  endif

  # libxcas
  xcas_lib_sources = files(
    'History.cc', 'Input.cc', 'Xcas1.cc', 'Equation.cc',
    'Print.cc', 'Tableur.cc', 'Editeur.cc', 'Graph.cc',
    'Graph3d.cc', 'Help1.cc', 'Cfg.cc',
    'Flv_CStyle.cc', 'Flve_Check_Button.cc', 'Flve_Input.cc',
    'Flv_Style.cc', 'Flv_Data_Source.cc', 'Flve_Combo.cc',
    'Flv_List.cc', 'Flv_Table.cc', 'gl2ps.c', 'Python.cc',
  )

  libxcas = shared_library('xcas',
    xcas_lib_sources,
    include_directories: [giac_inc, config_inc],
    dependencies: gui_deps,
    c_args: giac_common_args,
    cpp_args: giac_common_args,
    install: true,
    version: '0.0.0',
    soversion: '0',
  )

  libxcas_dep = declare_dependency(
    link_with: libxcas,
    include_directories: [giac_inc, config_inc],
    dependencies: gui_deps,
  )

  # xcas executable
  executable('xcas',
    files('xcas.cxx'),
    dependencies: [libgiac_dep, libxcas_dep],
    c_args: giac_common_args,
    cpp_args: giac_common_args,
    install: true,
  )

  # icas CLI shell
  executable('icas',
    files('icas.cc'),
    dependencies: [libgiac_dep, libxcas_dep],
    c_args: giac_common_args,
    cpp_args: giac_common_args,
    install: true,
  )

  # aide help tool
  executable('aide',
    files('aide.cc'),
    dependencies: [libgiac_dep, libxcas_dep],
    c_args: giac_common_args,
    cpp_args: giac_common_args,
    install: true,
  )
endif

# ── Test suite (requires icas from GUI build) ────────────────────────────────

if build_gui
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
    test(name,
      find_program('sh'),
      args: ['-c',
        icas_exe + ' ' + check_dir / input + ' > ' + name + '.tst && diff ' + name + '.tst ' + check_dir / name + '.out',
      ],
      workdir: meson.current_build_dir(),
      timeout: 120,
      suite: 'check',
    )
  endforeach
endif

# ── GUI summary ──────────────────────────────────────────────────────────────

gui_has_gl = false
gui_has_x11 = false
if build_gui
  gui_has_gl = gl_dep.found()
  if host_machine.system() == 'linux' or host_machine.system() == 'freebsd'
    gui_has_x11 = x11_dep.found()
  endif
endif

summary({
  'FLTK GUI': build_gui,
  'OpenGL': gui_has_gl,
  'X11': gui_has_x11,
}, section: 'GUI', bool_yn: true)

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

summary({
  'JNI bindings': build_jni,
}, section: 'Bindings', bool_yn: true)

summary({
  'QuickJS': quickjs_enabled,
  'libbf': libbf_enabled,
  'Flex/Bison regen': get_option('regen_parser'),
}, section: 'Build options', bool_yn: true)
