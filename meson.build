project('giac', 'c', 'cpp',
  version: '2.0.0',
  meson_version: '>= 1.2.0',
  license: 'GPL-3.0-or-later',
  default_options: [
    'cpp_std=c++17',
    'warning_level=1',
  ],
)

# Compilers
cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')

# ── Mandatory dependencies ───────────────────────────────────────────────────

gmp_dep = dependency('gmp', required: true)

# MPFR must come before GMP in link order (MPFR FAQ).
# On macOS with Homebrew, MPFR's pkg-config may emit a bare -lgmp without
# GMP's -L path (GMP and MPFR live in separate Cellar directories).
# Fix: extract GMP's libdir and inject -L<gmp_libdir> into MPFR's wrapper.
mpfr_dep = dependency('mpfr', method: 'pkg-config', required: false)
if not mpfr_dep.found()
  # Fallback: try any method (cmake, config-tool, etc.)
  mpfr_dep = dependency('mpfr', required: true)
endif

if host_machine.system() == 'darwin'
  gmp_libdir = gmp_dep.get_variable(pkgconfig: 'libdir', default_value: '')
  if gmp_libdir != ''
    mpfr_dep = declare_dependency(
      dependencies: [mpfr_dep],
      link_args: ['-L' + gmp_libdir],
    )
  endif
endif

# ── config.h generation ──────────────────────────────────────────────────────

cdata = configuration_data()

# Package metadata
cdata.set_quoted('PACKAGE', 'giac')
cdata.set_quoted('PACKAGE_NAME', 'giac')
cdata.set_quoted('PACKAGE_VERSION', meson.project_version())
cdata.set_quoted('PACKAGE_STRING', 'giac ' + meson.project_version())
cdata.set_quoted('VERSION', meson.project_version())

# Type sizes
cdata.set('SIZEOF_VOID_P', cc.sizeof('void *'))
cdata.set('SIZEOF_INT', cc.sizeof('int'))
cdata.set('SIZEOF_LONG', cc.sizeof('long'))
cdata.set('SIZEOF_LONG_LONG', cc.sizeof('long long'))

# Header checks
foreach h : [
  'alloca.h', 'dlfcn.h', 'malloc.h', 'memory.h',
  'signal.h', 'unistd.h', 'pwd.h',
  'sys/resource.h', 'sys/times.h', 'sys/time.h', 'sys/wait.h',
  'pthread.h',
  'readline/readline.h', 'readline/history.h',
]
  varname = 'HAVE_' + h.underscorify().to_upper()
  if cc.has_header(h)
    cdata.set(varname, 1)
  endif
endforeach

# C++ hash map / unordered_map detection (needed for MPQS large prime hashmap)
if cxx.has_header('unordered_map')
  cdata.set('C11_UNORDERED_MAP', 1)
elif cxx.has_header('ext/hash_map')
  cdata.set('EXT_HASH_MAP', 1)
elif cxx.has_header('hash_map')
  cdata.set('HASH_MAP', 1)
endif

# C++ feature detection
if cxx.has_header('sstream')
  cdata.set('HAVE_SSTREAM', 1)
endif
if cxx.has_header('gmpxx.h', dependencies: gmp_dep)
  cdata.set('HAVE_GMPXX_H', 1)
endif
if cc.sizeof('long double') > cc.sizeof('double')
  cdata.set('HAVE_LONG_DOUBLE', 1)
endif

# Debug support (interactive debugger in prog.cc)
cdata.set('DEBUG_SUPPORT', 1)

# Function checks
foreach f : [
  'getcwd', 'getpid', 'getpwuid', 'getuid', 'getgid',
  'geteuid', 'getegid', 'setenv', 'system', 'mallinfo',
  'tgammaf', 'sysconf',
]
  if cc.has_function(f)
    cdata.set('HAVE_' + f.to_upper(), 1)
  endif
endforeach

# Big-endian check
if host_machine.endian() == 'big'
  cdata.set('WORDS_BIGENDIAN', 1)
  cdata.set('DOUBLEVAL', 1)
endif

# GMP/MPFR always available
cdata.set('HAVE_LIBGMP', 1)
cdata.set('HAVE_GMP_H', 1)
cdata.set('HAVE_LIBMPFR', 1)

# ── Platform detection ───────────────────────────────────────────────────────

platform_args = []

if host_machine.system() == 'linux'
  cdata.set('HAVE_LIBPTHREAD', 1)
  if cc.has_function('sysconf')
    cdata.set('HAVE_SYSCONF', 1)
  endif

elif host_machine.system() == 'darwin'
  cdata.set('HAVE_LIBPTHREAD', 1)
  is_ios = false
  is_catalyst = false
  if host_machine.subsystem() == 'ios'
    is_ios = true
    platform_args += ['-DAPPLE_SMART', '-DNO_GETTEXT', '-DNO_SCANDIR', '-D_IOS_FIX_']
    cdata.set('HAVE_CONFIG_H', 1)
  elif host_machine.subsystem() == 'macos'
    # Could be Mac Catalyst or native macOS
    is_catalyst = true
    platform_args += ['-DAPPLE_SMART', '-DNO_GETTEXT', '-DNO_SCANDIR']
  else
    # Native macOS desktop
    platform_args += ['-DNO_SCANDIR']
    # NO_GETTEXT only if gettext not found (set later)
  endif

elif host_machine.system() == 'windows'
  platform_args += [
    '-DGIAC_MPQS', '-D__MINGW_H', '-DMINGW32',
    '-DYY_NO_UNISTD_H',
    '-DHAVE_NO_SYS_TIMES_H', '-DHAVE_NO_SYS_RESOURCE_WAIT_H',
    '-DHAVE_NO_PWD_H', '-DHAVE_NO_CWD', '-DHAVE_NO_HOME_DIRECTORY',
    '-DWIN32_LEAN_AND_MEAN',  # Skip RPC headers to avoid std::byte / Windows byte conflict in C++17
  ]

elif host_machine.system() == 'freebsd'
  cdata.set('HAVE_LIBPTHREAD', 1)

elif host_machine.system() == 'android'
  platform_args += ['-DNO_BSD']
  cdata.set('HAVE_CONFIG_H', 1)
  cdata.set('HAVE_UNISTD_H', 1)

elif host_machine.system() == 'emscripten'
  platform_args += ['-DEMCC2', '-Dgammaf=tgammaf']

endif

# ── Optional dependencies ────────────────────────────────────────────────────

optional_deps = []

# PARI
pari_dep = dependency('pari', required: false)
if not pari_dep.found() and not get_option('pari').disabled()
  # PARI often lacks a pkg-config file; fall back to manual detection
  _pari_extra_dirs = []
  _pari_extra_args = []
  if host_machine.system() == 'darwin'
    _pari_extra_dirs = ['/opt/homebrew/lib', '/usr/local/lib']
    _pari_extra_args = ['-I/opt/homebrew/include', '-I/usr/local/include']
  endif
  _pari_lib = cc.find_library('pari', required: false, dirs: _pari_extra_dirs)
  if _pari_lib.found() and cc.has_header('pari/pari.h', args: _pari_extra_args)
    pari_dep = declare_dependency(
      dependencies: _pari_lib,
      compile_args: _pari_extra_args,
    )
  elif get_option('pari').enabled()
    error('PARI library requested but not found')
  endif
endif
if pari_dep.found()
  cdata.set('HAVE_LIBPARI', 1)
  cdata.set('HAVE_PARI_PARI_H', 1)
  optional_deps += pari_dep
endif

# NTL
ntl_dep = dependency('ntl', required: get_option('ntl'))
if ntl_dep.found()
  cdata.set('HAVE_LIBNTL', 1)
  optional_deps += ntl_dep
endif

# CoCoA (math library, not macOS Cocoa.framework — use pkg-config only)
cocoa_dep = dependency('cocoa', method: 'pkg-config', required: get_option('cocoa'))
if cocoa_dep.found()
  cdata.set('HAVE_LIBCOCOA', 1)
  optional_deps += cocoa_dep
endif

# GSL
gsl_dep = dependency('gsl', required: get_option('gsl'))
if gsl_dep.found()
  cdata.set('HAVE_LIBGSL', 1)
  optional_deps += gsl_dep
endif

# LAPACK — explicit control, no APPLE_SMART auto-detection (FR-019)
if not get_option('lapack').disabled()
  if host_machine.system() == 'darwin'
    lapack_dep = dependency('appleframeworks', modules: ['Accelerate'], required: get_option('lapack'))
  else
    # LAPACK requires BLAS
    blas_dep = dependency('blas', required: get_option('lapack'))
    lapack_dep = dependency('lapack', required: get_option('lapack'))
    if blas_dep.found() and lapack_dep.found()
      lapack_dep = declare_dependency(dependencies: [lapack_dep, blas_dep])
    endif
  endif
  if lapack_dep.found()
    cdata.set('HAVE_LIBLAPACK', 1)
    optional_deps += lapack_dep
  endif
else
  lapack_dep = dependency('', required: false)
endif

# ECM (GMP-ECM factoring library)
# Try system first, then fall back to subproject via ecm.wrap
ecm_dep = dependency('ecm', required: false)
if not ecm_dep.found() and not get_option('ecm').disabled()
  # No pkg-config; try manual detection (macOS Homebrew paths)
  _ecm_extra_dirs = []
  _ecm_extra_args = []
  if host_machine.system() == 'darwin'
    _ecm_extra_dirs = ['/opt/homebrew/lib', '/usr/local/lib']
    _ecm_extra_args = ['-I/opt/homebrew/include', '-I/usr/local/include']
  endif
  _ecm_lib = cc.find_library('ecm', required: false, dirs: _ecm_extra_dirs)
  if _ecm_lib.found() and cc.has_header('ecm.h', args: _ecm_extra_args)
    ecm_dep = declare_dependency(
      dependencies: _ecm_lib,
      compile_args: _ecm_extra_args,
    )
  elif get_option('ecm').enabled()
    # Force subproject build
    ecm_dep = dependency('ecm', fallback: ['ecm', 'ecm_dep'], required: true)
  endif
endif
if ecm_dep.found()
  cdata.set('HAVE_LIBECM', 1)
  optional_deps += ecm_dep
endif

# GLPK
glpk_dep = dependency('glpk', required: get_option('glpk'))
if glpk_dep.found()
  cdata.set('HAVE_LIBGLPK', 1)
  optional_deps += glpk_dep
endif

# libpng
png_dep = dependency('libpng', required: get_option('png'))
if png_dep.found()
  cdata.set('HAVE_LIBPNG', 1)
  cdata.set('HAVE_PNG_H', 1)
  optional_deps += png_dep
endif

# libao
ao_dep = dependency('ao', required: get_option('ao'))
if ao_dep.found()
  cdata.set('HAVE_LIBAO', 1)
  optional_deps += ao_dep
endif

# libsamplerate
samplerate_dep = dependency('samplerate', required: get_option('samplerate'))
if samplerate_dep.found()
  cdata.set('HAVE_LIBSAMPLERATE', 1)
  optional_deps += samplerate_dep
endif

# curl
curl_dep = dependency('libcurl', required: get_option('curl'))
if curl_dep.found()
  cdata.set('HAVE_LIBCURL', 1)
  optional_deps += curl_dep
endif

# readline (keg-only on macOS, not in default pkg-config path)
readline_dep = dependency('readline', required: false)
if not readline_dep.found()
  # Fallback: try to find Homebrew readline directly
  readline_dep = cc.find_library('readline', required: get_option('readline'))
  if readline_dep.found() and not cc.has_header('readline/readline.h', dependencies: readline_dep)
    readline_dep = dependency('', required: false)
  endif
endif
if readline_dep.found()
  cdata.set('HAVE_LIBREADLINE', 1)
  optional_deps += readline_dep
endif

# gettext / libintl
if not get_option('gettext').disabled()
  intl_dep = dependency('intl', required: get_option('gettext'))
  if intl_dep.found()
    cdata.set('HAVE_GETTEXT', 1)
    optional_deps += intl_dep
  else
    # macOS without gettext
    if host_machine.system() == 'darwin' and '-DNO_GETTEXT' not in platform_args
      platform_args += ['-DNO_GETTEXT']
    endif
  endif
else
  intl_dep = dependency('', required: false)
  if host_machine.system() == 'darwin' and '-DNO_GETTEXT' not in platform_args
    platform_args += ['-DNO_GETTEXT']
  endif
endif

# Boehm GC
gc_dep = dependency('bdw-gc', required: get_option('gc'))
if gc_dep.found()
  cdata.set('HAVE_LIBGC', 1)
  optional_deps += gc_dep
endif

# dl (dynamic loading)
dl_dep = dependency('dl', required: get_option('dl'))
if not dl_dep.found()
  dl_dep = cc.find_library('dl', required: get_option('dl'))
endif
if dl_dep.found()
  cdata.set('HAVE_LIBDL', 1)
  optional_deps += dl_dep
endif

# pthread
thread_dep = dependency('threads', required: false)
if thread_dep.found()
  optional_deps += thread_dep
endif

# librt (clock_gettime on older Linux)
rt_dep = cc.find_library('rt', required: false)
if rt_dep.found()
  cdata.set('HAVE_LIBRT', 1)
  optional_deps += rt_dep
endif

# nauty (graph automorphism — bundled in src/nautywrapper.c)
# The source includes its own nauty; HAVE_LIBNAUTY enables system nauty
_nauty_dep = cc.find_library('nauty', required: false)
if _nauty_dep.found() and cc.has_header('nauty/naututil.h')
  cdata.set('HAVE_LIBNAUTY', 1)
  cdata.set('HAVE_NAUTY_NAUTUTIL_H', 1)
  optional_deps += _nauty_dep
endif

# ── Write config.h ───────────────────────────────────────────────────────────

config_h = configure_file(
  output: 'config.h',
  configuration: cdata,
)

config_inc = include_directories('.')

# ── Common compile arguments ─────────────────────────────────────────────────

giac_common_args = [
  '-U_GLIBCXX_ASSERTIONS',
  '-DUSE_OBJET_BIDON',
  '-fno-strict-aliasing',
  '-DGIAC_GENERIC_CONSTANTS',
  '-DTIMEOUT',
  '-DHAVE_CONFIG_H',
  '-D_GNU_SOURCE',
] + platform_args

# ── Install headers ──────────────────────────────────────────────────────────

giac_headers = files(
  'src/dispatch.h', 'src/fraction.h', 'src/gen.h', 'src/desolve.h',
  'src/misc.h', 'src/ti89.h', 'src/mathml.h', 'src/identificateur.h',
  'src/unary.h', 'src/symbolic.h', 'src/index.h', 'src/modpoly.h',
  'src/modfactor.h', 'src/modint.h', 'src/permu.h', 'src/monomial.h',
  'src/poly.h', 'src/threaded.h', 'src/gausspol.h', 'src/sym2poly.h',
  'src/ezgcd.h', 'src/derive.h', 'src/solve.h', 'src/quater.h',
  'src/subst.h', 'src/usual.h', 'src/intg.h', 'src/intgab.h',
  'src/risch.h', 'src/lin.h', 'src/series.h', 'src/vecteur.h',
  'src/sparse.h', 'src/vector.h', 'src/csturm.h', 'src/moyal.h',
  'src/tex.h', 'src/global.h', 'src/ifactor.h', 'src/alg_ext.h',
  'src/gauss.h', 'src/isom.h', 'src/plot.h', 'src/plot3d.h',
  'src/rpn.h', 'src/prog.h', 'src/pari.h', 'src/cocoa.h',
  'src/giac.h', 'src/first.h', 'src/maple.h', 'src/help.h',
  'src/tinymt32.h', 'src/tinymt32_license.h',
  'src/static.h', 'src/static_extern.h',
  'src/static_lexer.h', 'src/static_lexer_.h',
  'src/lexer_tab_int.h', 'src/static_help.h',
  'src/giacPCH.h', 'src/giacintl.h', 'src/gmp_replacements.h',
  'src/myostream.h', 'src/lpsolve.h', 'src/optimization.h',
  'src/signalprocessing.h', 'src/graphe.h', 'src/graphtheory.h',
  'src/nautywrapper.h', 'src/markup.h', 'src/kdisplay.h',
  'src/k_csdk.h', 'src/k_defs.h', 'src/fenv.h',
  'src/libregexp.h', 'src/libregexp-opcode.h',
  'src/libunicode.h', 'src/libunicode-table.h',
  'src/libbf.h', 'src/list.h', 'src/cutils.h',
  'src/qjsgiac.h', 'src/quickjs.h', 'src/js.h',
  'src/quickjs-atom.h', 'src/quickjs-libc.h', 'src/quickjs-opcode.h',
  'src/bf2gmp.h',
  'src/input_lexer.h',
  'src/opengl.h',
  'src/path.h',
  'src/qrcodegen.h',
)

install_headers(giac_headers, subdir: 'giac')

# Also install generated config.h
install_headers(config_h, subdir: 'giac')

# ── Configuration summary ────────────────────────────────────────────────────

summary({
  'prefix': get_option('prefix'),
  'libdir': get_option('libdir'),
  'buildtype': get_option('buildtype'),
}, section: 'Directories')

summary({
  'GMP': gmp_dep.found(),
  'MPFR': mpfr_dep.found(),
}, section: 'Core dependencies', bool_yn: true)

summary({
  'PARI': pari_dep.found(),
  'NTL': ntl_dep.found(),
  'CoCoA': cocoa_dep.found(),
  'GSL': gsl_dep.found(),
  'LAPACK': lapack_dep.found(),
  'ECM': ecm_dep.found(),
  'GLPK': glpk_dep.found(),
}, section: 'Optional math libraries', bool_yn: true)

summary({
  'libpng': png_dep.found(),
  'libao': ao_dep.found(),
  'libsamplerate': samplerate_dep.found(),
  'libcurl': curl_dep.found(),
  'readline': readline_dep.found(),
  'gettext': not get_option('gettext').disabled() and intl_dep.found(),
  'Boehm GC': gc_dep.found(),
}, section: 'Optional utility libraries', bool_yn: true)

# ── Subdirectory ─────────────────────────────────────────────────────────────

subdir('src')
subdir('tests')

# ── pkg-config file (after src/ so libgiac is defined) ───────────────────────

pkg = import('pkgconfig')
pkg.generate(libgiac,
  name: 'giac',
  description: 'Giac Computer Algebra System library',
  url: 'https://www-fourier.ujf-grenoble.fr/~parisse/giac.html',
  requires: [gmp_dep, mpfr_dep],
)
