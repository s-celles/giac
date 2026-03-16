project('ecm', 'c',
  version: '7.0.6',
  license: 'LGPL-3.0-or-later',
  meson_version: '>= 1.2.0',
  default_options: ['c_std=c11', 'warning_level=1'],
)

cc = meson.get_compiler('c')

gmp_dep = dependency('gmp', required: true)

# Generate config.h with the defines ECM needs
cdata = configuration_data()
cdata.set_quoted('ECM_VERSION', meson.project_version())
cdata.set_quoted('PACKAGE_NAME', 'ecm')
cdata.set_quoted('PACKAGE_VERSION', meson.project_version())

# Check for functions/headers ECM uses
foreach f : ['alloca', 'access', 'ctime', 'fileno', 'gethostname',
             'getrusage', 'gettimeofday', 'isascii',
             'isdigit', 'isspace', 'isxdigit', 'memset', 'signal',
             'strlen', 'strncasecmp']
  if cc.has_function(f)
    cdata.set('HAVE_' + f.to_upper(), 1)
  endif
endforeach

foreach h : ['alloca.h', 'ctype.h', 'fcntl.h', 'inttypes.h', 'limits.h',
             'math.h', 'signal.h', 'stdint.h', 'string.h', 'strings.h',
             'unistd.h', 'sys/resource.h', 'sys/time.h', 'gmp.h']
  if cc.has_header(h)
    cdata.set('HAVE_' + h.underscorify().to_upper(), 1)
  endif
endforeach

# GMP internals
if cc.has_header_symbol('gmp.h', '__gmpn_add_nc', dependencies: gmp_dep)
  cdata.set('HAVE___GMPN_ADD_NC', 1)
endif
if cc.has_header_symbol('gmp.h', '__gmpn_mod_34lsub1', dependencies: gmp_dep)
  cdata.set('HAVE___GMPN_MOD_34LSUB1', 1)
endif
if cc.has_header_symbol('gmp.h', '__gmpn_redc_1', dependencies: gmp_dep)
  cdata.set('HAVE___GMPN_REDC_1', 1)
endif
if cc.has_header_symbol('gmp.h', '__gmpn_redc_2', dependencies: gmp_dep)
  cdata.set('HAVE___GMPN_REDC_2', 1)
endif
if cc.has_header_symbol('gmp.h', '__gmpn_mullo_n', dependencies: gmp_dep)
  cdata.set('HAVE___GMPN_MULLO_N', 1)
endif

# Enable APRCL primality proving
cdata.set('HAVE_APRCL', 1)

# Compiler attributes
if cc.compiles('__attribute__((hot)) void f(void) {}', name: 'hot attribute')
  cdata.set('ATTRIBUTE_HOT', '__attribute__((hot))')
else
  cdata.set('ATTRIBUTE_HOT', '')
endif

# sizeof checks
cdata.set('SIZEOF_UNSIGNED_LONG', cc.sizeof('unsigned long'))
cdata.set('SIZEOF_UNSIGNED_LONG_LONG', cc.sizeof('unsigned long long'))

# 64-bit check
if cc.sizeof('unsigned long') >= 8
  cdata.set('HAVE_NATIVE_MULREDC1_N', 1)
endif

configure_file(output: 'config.h', configuration: cdata)

# Generate ecm.h from ecm.h.in (just copy — no @substitutions@ needed)
ecm_h = configure_file(
  input: 'ecm.h.in',
  output: 'ecm.h',
  copy: true,
)

config_inc = include_directories('.')
src_inc = include_directories('.')

# libecm source files (from Makefile.am libecm_la_SOURCES)
ecm_sources = files(
  'ecm.c', 'ecm2.c', 'pm1.c', 'pp1.c', 'getprime_r.c', 'listz.c', 'lucas.c',
  'stage2.c', 'mpmod.c', 'mul_lo.c', 'polyeval.c', 'median.c',
  'schoen_strass.c', 'ks-multiply.c', 'rho.c', 'bestd.c', 'auxlib.c',
  'random.c', 'factor.c', 'sp.c', 'spv.c', 'spm.c', 'mpzspm.c', 'mpzspv.c',
  'ntt_gfp.c', 'ecm_ntt.c', 'pm1fs2.c', 'sets_long.c',
  'auxarith.c', 'batch.c', 'parametrizations.c',
  'addlaws.c', 'torsions.c',
  'aprtcle/mpz_aprcl.c',
)

libecm = static_library('ecm',
  ecm_sources,
  include_directories: [config_inc, src_inc],
  dependencies: gmp_dep,
  c_args: ['-DHAVE_CONFIG_H'],
)

ecm_dep = declare_dependency(
  link_with: libecm,
  include_directories: [config_inc],
  dependencies: gmp_dep,
)

meson.override_dependency('ecm', ecm_dep)
