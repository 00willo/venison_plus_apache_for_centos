server {
    server_name mydomain.com www.mydomain.com;
    root /home/sudoer/mydomain.com/public;
    index index.php index.html;
    charset UTF-8;
    default_type text/html;

    access_log /var/log/nginx/mydomain.com-access.log;
    error_log /var/log/nginx/mydomain.com-error.log;

    include /etc/nginx/conf/proxy_cache_rules;

    #The Block Below Makes Nginx Server Static Assets Without Consulting Apache first. 
    #Extra directives for these static assets can be added within this block, or you can leave it empty
    #If Apache needs to apply handlers to any of these assets, remove them from the list

    location ~* ^.+\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|html|htm)$
    {
    
    }

     location / {
       include proxy_params;
       include proxy_cache_rules;
       include proxy_cache;
       proxy_pass http://localhost:7080;
    }


    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        access_log off;
		log_not_found off;
    }

	location ~ /\. {
		deny all;
		access_log off;
		log_not_found off;
	}

    location /nginx_status {
        stub_status on;
        access_log off;
    }

    location ~ /purge(/.*) {
	    proxy_cache_purge php_cache "$scheme$request_method$host$1";
	}

    # Ensure requests for pagespeed optimized resources go to the pagespeed handler and no extraneous headers get set
   location ~ "\.pagespeed\.([a-z]\.)?[a-z]{2}\.[^.]{10}\.[^.]+" {
      add_header "" "";
   }
   location ~ "^/ngx_pagespeed_static/" { }
   location ~ "^/ngx_pagespeed_beacon$" { }
   location /ngx_pagespeed_statistics { allow 127.0.0.1; deny all; }
   location /ngx_pagespeed_message { allow 127.0.0.1; deny all; }

    include /home/sudoer/mydomain.com/pagespeed.conf;
}
