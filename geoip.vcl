C{
  #include <dlfcn.h>
  #include <stdlib.h>
  #include <stdio.h>

  static const char* (*get_country_code)(char* ip) = NULL;

  __attribute__((constructor)) void
  load_module()
  {
    const char* symbol_name = "get_country_code";
    const char* plugin_name = "/usr/lib/geoip_plugin.so";
    void* handle = NULL;

    handle = dlopen( plugin_name, RTLD_NOW );
    if (handle != NULL) {
      get_country_code = dlsym( handle, symbol_name );
      if (get_country_code == NULL)
        fprintf( stderr, "\nError: Could not load GeoIP plugin:\n%s\n\n", dlerror() );
      else
        printf( "GeoIP plugin loaded successfully.\n");
      }
    else
      fprintf( stderr, "\nError: Could not load GeoIP plugin:\n%s\n\n", dlerror() );
  }
}C
