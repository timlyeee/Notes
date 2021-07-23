
### 1. Window32 

```
#enable_profiling=true
#v8_enable_trace_ignition=true
is_clang=true
is_debug=false
target_cpu="x86" #change to x64 for amd64
is_component_build=true
icu_use_data_file=false
use_custom_libcxx=false
v8_use_external_startup_data=false
#is_official_build=true
#use_incremental_wpo=false
v8_enable_i18n_support = false        # Produces a smaller binary.
```


### 2.1 android armeabi-v7
```
is_component_build = false
is_debug = false
target_cpu = "arm"
v8_target_cpu = "arm"
target_os = "android"
use_goma = false
goma_dir = "None"
v8_enable_backtrace = true
v8_enable_disassembler = true
v8_enable_object_print = true
v8_enable_verify_heap = true
v8_use_external_startup_data = false
icu_use_data_file=false
clang_use_chrome_plugins = false
use_custom_libcxx=false
v8_monolithic=true
#is_official_build=true
v8_static_library=true
strip_debug_info=true        
v8_enable_i18n_support = false        # Produces a smaller binary.

```

### 2.2 android arm64
```
# Build arguments go here.
# See "gn args <out_dir> --list" for available build arguments.
is_component_build = false
is_debug = false
target_cpu = "arm64"
v8_target_cpu = "arm64"
target_os = "android"
use_goma = false
goma_dir = "None"
v8_enable_backtrace = true
v8_enable_disassembler = true
v8_enable_object_print = true
v8_enable_verify_heap = true
v8_use_external_startup_data = false
icu_use_data_file=false
clang_use_chrome_plugins = false
#is_official_build=true
v8_monolithic=true
use_custom_libcxx=false
strip_debug_info=true
v8_enable_i18n_support = false        # Produces a smaller binary.

```

### 3.1 Mac OS 

```
# Build arguments go here.
# See "gn args <out_dir> --list" for available build arguments.
is_component_build = false
is_debug = false
target_cpu = "x64"
use_custom_libcxx = false
v8_monolithic = true
v8_use_external_startup_data = false
icu_use_data_file= false # should be false
symbol_level = 0
is_clang=false
#use_xcode_clang=true
v8_static_library=true
treat_warnings_as_errors=false
```


### 3.2 iOS for ARM64


```
# Build arguments go here.
# See "gn args <out_dir> --list" for available build arguments.
#enable_ios_bitcode = true
ios_deployment_target = 10
is_component_build = false
is_debug = false
target_cpu = "arm64"                  # "x64" for a simulator build.
target_os = "ios"
use_custom_libcxx = false             # Use Xcode's libcxx.
use_xcode_clang = true
v8_enable_i18n_support = false        # Produces a smaller binary.
v8_monolithic = true                  # Enable the v8_monolith target.
v8_use_external_startup_data = false  # The snaphot is included in the binary.
v8_static_library=true
treat_warnings_as_errors=false
#icu_use_data_file=false
#v8_enable_lite_mode=true
v8_enable_pointer_compression=false   # cause crash
```