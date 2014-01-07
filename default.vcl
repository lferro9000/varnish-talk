### 6th Circle
include "geoip.vcl";
include "accept-language.vcl";
include "/Users/luis/dev/varnish-talk/detect-device.vcl";

# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
#

### 1st Circle - definition of backend
backend default {
  .host = "127.0.0.1";
  .port = "8080";
  .connect_timeout = 30s;
  .first_byte_timeout = 30s;
  .between_bytes_timeout = 30s;
}

# 
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
sub vcl_recv {
  call detectdevice;

  ### 6th Circle  
  C{
    VRT_SetHdr(sp, HDR_REQ, "\017X-Country-Code:", (*get_country_code)( VRT_IP_string(sp, VRT_r_client_ip(sp)) ), vrt_magic_string_end);
  }C

  if (req.restarts == 0) {
    if (req.http.x-forwarded-for) {
        set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }
  }
  if (req.request != "GET" &&
      req.request != "HEAD" &&
      req.request != "PUT" &&
      req.request != "POST" &&
      req.request != "TRACE" &&
      req.request != "OPTIONS" &&
      req.request != "DELETE") {
      /* Non-RFC2616 or CONNECT which is weird. */
    return (pipe);
  }
  if (req.request != "GET" && req.request != "HEAD") {
    /* We only deal with GET and HEAD by default */
    return (pass);
  }

  ### 5th Circle
  if (req.url ~ "\.(png|gif|jpg)$") {
    remove req.http.Cookie;
  }

  if (req.http.Authorization || req.http.Cookie) {
    /* Not cacheable by default */
    return (pass);
  }

  ### 1st Circle - reset by force refresh in browser
  if (req.http.Cache-Control ~ "no-cache") {
    ban_url(req.url);
  }

  return (lookup);
}

sub vcl_pipe {
  # Note that only the first request to the backend will have
  # X-Forwarded-For set.  If you use X-Forwarded-For and want to
  # have it set for all requests, make sure to have:
  # set bereq.http.connection = "close";
  # here.  It is not set by default as it might break some broken web
  # applications, like IIS with NTLM authentication.
  return (pipe);
}

sub vcl_pass {
  return (pass);
}

sub vcl_hash {
  hash_data(req.url);
  if (req.http.host) {
    hash_data(req.http.host);
  } else {
    hash_data(server.ip);
  }
  return (hash);
}

sub vcl_hit {
  return (deliver);
}

sub vcl_miss {
  return (fetch);
}

sub vcl_fetch {
  if (beresp.http.esi-enabled == "1") {
    set beresp.do_esi = true; /* Do ESI processing               */
    set beresp.ttl = 24 h;    /* Sets the TTL on the HTML above  */
  }

  if (beresp.ttl <= 0s ||
    beresp.http.Set-Cookie ||
    beresp.http.Vary == "*") {
    /*
     * Mark as "Hit-For-Pass" for the next 2 minutes
     */
    set beresp.ttl = 120 s;
    return (hit_for_pass);
  }
  ### 1st Circle - no cache if pragma sent
  if (beresp.http.cache-control ~ "(no-cache|private)" ||
    beresp.http.pragma ~ "no-cache") {
    set beresp.ttl = 0s;
  }

  return (deliver);
}

sub vcl_deliver {
  ### 1sr Circle - statistics on response
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
    set resp.http.X-Cache-Hits = obj.hits;
  } else {
    set resp.http.X-Cache = "MISS";
  }
  return (deliver);
}

sub vcl_error {
  set obj.http.Content-Type = "text/html; charset=utf-8";
  set obj.http.Retry-After = "5";
  synthetic {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} + obj.status + " " + obj.response + {"</title>
  </head>
  <body>
    <h1>Error "} + obj.status + " " + obj.response + {"</h1>
    <p>"} + obj.response + {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} + req.xid + {"</p>
    <hr>
    <p>Varnish cache server</p>
  </body>
</html>
"};
    return (deliver);
}

sub vcl_init {
  return (ok);
}

sub vcl_fini {
  return (ok);
}
