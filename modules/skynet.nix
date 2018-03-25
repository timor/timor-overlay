{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.skynet;
nextcloud-drv = {stdenv, fetchurl, fetchpatch }: pkgs.stdenv.mkDerivation rec {
  name= "nextcloud-${version}";
  version = "13.0.1";

  src = fetchurl {
    url = "https://download.nextcloud.com/server/releases/${name}.tar.bz2";
    sha256 = "048x3x6d11m75ghxjcjzm8amjm6ljirv6djbl53awwp9f5532hsp";
  };

  installPhase = ''
    mkdir -p $out/
    cp -R . $out/
    mkdir -p $out/data
    mkdir -p $out/apps
  '';

  meta = {
    description = "Sharing solution for files, calendars, contacts and more";
    homepage = https://nextcloud.com;
    license = stdenv.lib.licenses.agpl3Plus;
    platforms = with stdenv.lib.platforms; unix;
  };
};
nextcloud = pkgs.callPackage nextcloud-drv { };
in
{

  options.services.skynet = {
    enable = mkEnableOption "skynet";
  };

  config = mkIf cfg.enable {
  services.nginx.enable = true;

  services.nginx.virtualHosts.skynet = {
    # serverName = "skynet.meterriblecrew.net";
    serverName = "*";
    root = nextcloud.out;
    default = true;
    extraConfig = ''
location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
}

# The following 2 rules are only needed for the user_webfinger app.
# Uncomment it if you're planning to use this app.
# rewrite ^/.well-known/host-meta /nextcloud/public.php?service=host-meta
# last;
#rewrite ^/.well-known/host-meta.json
# /nextcloud/public.php?service=host-meta-json last;

location = /.well-known/carddav {
    return 301 $scheme://$host/nextcloud/remote.php/dav;
}
location = /.well-known/caldav {
    return 301 $scheme://$host/nextcloud/remote.php/dav;
}

location /.well-known/acme-challenge { }

location ^~ /nextcloud {

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    location /nextcloud {
        rewrite ^ /nextcloud/index.php$uri;
    }

    location ~ ^/nextcloud/(?:build|tests|config|lib|3rdparty|templates|data)/ {
        deny all;
    }
    location ~ ^/nextcloud/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^/nextcloud/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+)\.php(?:$|/) {
        # fastcgi_split_path_info ^(.+\.php)(/.*)$;
        # include fastcgi_params;
        # fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        # fastcgi_param PATH_INFO $fastcgi_path_info;
        # fastcgi_param HTTPS on;
        #Avoid sending the security headers twice
        # fastcgi_param modHeadersAvailable true;
        # fastcgi_param front_controller_active true;
        # fastcgi_pass php-handler;
        # fastcgi_intercept_errors on;
        # fastcgi_request_buffering off;
        uwsgi_modifier1 14;
        # Avoid duplicate headers confusing OC checks
        uwsgi_hide_header X-Frame-Options;
        uwsgi_hide_header X-XSS-Protection;
        uwsgi_hide_header X-Content-Type-Options;
        uwsgi_hide_header X-Robots-Tag;
        uwsgi_pass unix:/run/uwsgi/nextcloud.sock;
    }

    location ~ ^/nextcloud/(?:updater|ocs-provider)(?:$|/) {
        try_files $uri/ =404;
        index index.php;
    }

    # Adding the cache control header for js and css files
    # Make sure it is BELOW the PHP block
    location ~ \.(?:css|js|woff|svg|gif)$ {
        try_files $uri /nextcloud/index.php$uri$is_args$args;
        add_header Cache-Control "public, max-age=15778463";
        # Add headers to serve security related headers  (It is intended
        # to have those duplicated to the ones above)
        # Before enabling Strict-Transport-Security headers please read
        # into this topic first.
        # add_header Strict-Transport-Security "max-age=15768000;
        # includeSubDomains; preload;";
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        # Optional: Don't log access to assets
        access_log off;
    }

    location ~ \.(?:png|html|ttf|ico|jpg|jpeg)$ {
        try_files $uri /nextcloud/index.php$uri$is_args$args;
        # Optional: Don't log access to other assets
        access_log off;
    }
}
    '';
    # locations = {
    #   "/robots.txt" = {
    #     extraConfig = "allow all;";
    #   };
    #   "/.well-known/carddav" = {
    #     extraConfig = "return 301 $scheme://$host/remote.php/dav;";
    #   };
    #   "/.well-known/caldav" = {
    #     extraConfig = "return 301 $scheme://$host/remote.php/dav;";
    #   };

    #   "/.well-known/acme-challenge" = {};
    #   # Root
    #   "/" = {
    #     extraConfig = ''
    #       rewrite ^ /index.php$uri;
    #     '';
    #   };
    #   # PHP files
    #   "~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\\.php(?:$|/)" = {
    #     # extraConfig = ''
    #     #   fastcgi_split_path_info ^(.+\\.php)(/.*)$;
    #     #   include ${pkgs.nginx}/conf/fastcgi_params;
    #     #   fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    #     #   fastcgi_param PATH_INFO $fastcgi_path_info;
    #     #   fastcgi_pass unix:/run/phpfpm/nextcloud.sock;
    #     # '';
    #     extraConfig = ''
    #       # include uwsgi_params;
    #       uwsgi_modifier1 14;
    #       # Avoid duplicate headers confusing OC checks
    #       uwsgi_hide_header X-Frame-Options;
    #       uwsgi_hide_header X-XSS-Protection;
    #       uwsgi_hide_header X-Content-Type-Options;
    #       uwsgi_hide_header X-Robots-Tag;
    #       uwsgi_pass unix:/run/uwsgi/nextcloud.sock;
    #       '';
    #   };
    #   # CSS and JavaScript files
    #   "~* ^/(?!apps-local).*\\.(?:css|js)$" = {
    #     tryFiles = "$uri /index.php$uri$is_args$args";
    #   };
    #   # Other static assets
    #   "~* ^/(?!apps-local).*\\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$" = {
    #     tryFiles = "$uri /index.php$uri$is_args$args";
    #   };
    #   # Locally installed apps:
    #   #
    #   # No need to specify location for PHP files of installed apps???
    #   #
    #   # CSS and JavaScript files for installed apps
    #   "~* ^/apps-local/.*\\.(?:css|js)$" = {
    #     root = "/var/nextcloud";
    #     tryFiles = "$uri =404";
    #   };
    #   # Other static assets for installed apps
    #   "~* ^/apps-local/.*\\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$" = {
    #     root = "/var/nextcloud";
    #     tryFiles = "$uri =404";
    #   };
    #   "~ ^/(?:build|tests|config|lib|3rdparty|templates|data|\\.|autotest|occ|issue|indie|db_|console)" = {
    #     extraConfig = "deny all;";
    #   };
    # };
  };

    services.uwsgi = {
      enable = true;
      user = "nginx";
      group = "nginx";
      plugins = ["php"];
      instance = {
        type = "emperor";
        vassals = {
          nextcloud = {
            type = "normal";
            uid = "nginx";
            gid = "nginx";
            # chown-socket = "nextcloud:nextcloud";
            socket = "/run/uwsgi/nextcloud.sock";
            cheaper = 1;
            processes = 4;
            php-docroot = "${nextcloud}";
            php-allowed-ext = ".php";
            php-index = "index.php";
            php-set = 
            };
        };
      };
    };

  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE nginx WITH LOGIN PASSWORD 'nginx' CREATEDB;
      CREATE DATABASE nginx;
      GRANT ALL PRIVILEGES ON DATABASE nginx TO nginx;
  '';

  };
  systemd.services.fakeFucker = let
    ncroot = "/var/db/nextcloud";
    bindcmd = (path: ''
      mkdir -p ${ncroot}/${path}
      chown nginx:nginx ${ncroot}/${path}
      /run/current-system/sw/bin/mount --bind  ${ncroot}/${path} ${nextcloud.out}/${path}
    '');
    unbindcmd = (path: ''
      /run/current-system/sw/bin/umount ${nextcloud.out}/${path}
    '');
    dirs = [ "config" "data" "apps"];
    in
  {
    before = [ "nginx.service" ];
    requiredBy = [ "nginx.service" ];
    script = lib.concatMapStrings bindcmd dirs;
    preStop = lib.concatMapStrings unbindcmd dirs;
    unitConfig = {
      StopWhenUnneeded = true;
    };
    serviceConfig = {
      RemainAfterExit = true;
      Type = "oneshot";
    };
  };
  };
}
