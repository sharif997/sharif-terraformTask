#!/bin/bash
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y wget

setenforce 0
sed -i 's/disabled/permissive/g' /etc/selinux/config


#installing nginx,configure it and start it as service
yum -y install nginx


cat <<\EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;


    include /etc/nginx/conf.d/*.conf;
    server {
        listen       80;
        server_name  example.com;
        root         /var/www/html/example.com;
        index index.php index.html index.htm;

        include /etc/nginx/default.d/*.conf;
        location / {
                 try_files $uri $uri/ =404;
        }
        error_page 404 /404.html;
        location = /50x.html {
                 root /var/www/html/example.com;
        }
        location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index   index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        }
        error_page 404 /404.html;

        }
    }

EOF

systemctl enable nginx
systemctl start nginx


#installing php and start it as service
yum install -y php-mysqlnd php-dom php-simplexml php-xml php-xmlreader php-curl php-exif php-ftp php-gd php-iconv  php-json php-mbstring php-posix php-sockets php-tokenizer
yum -y install php-cli php-fpm php-json php-opcache php-mbstring php-xml php-gd php-curl
systemctl enable php-fpm
systemctl start php-fpm


#installing wordpress,configure it with the correct database information
mkdir -p /var/www/html/example.com
wget http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
mv wordpress/* /var/www/html/example.com
chown -R nginx: /var/www/html/example.com
cat <<\EOF > /var/www/html/example.com/wp-config.php
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', 'admin' );

/** Database password */
define( 'DB_PASSWORD', 'admin1234' );

/** Database hostname */
define( 'DB_HOST', ' place your host link here :3306' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'TR% _W.`|HuK=ws8eX#=%hj_O%#A!A8C:c,d,-mf-W}Ptb[)5Gz!TVlkaJg]1/(s' );
define( 'SECURE_AUTH_KEY',  '88N@:IR#UaJ@7@Y7t~Y(9nL_5!@7X1NH1a0|1#5X(^%]TvEb:OF!S),K|]wr;N1m' );
define( 'LOGGED_IN_KEY',    'c=4yh!Ez:^DJr!`I;o^B6,$^-,MKit!s(sRTG/Z+3~]nb}]YVJ;YF8gu@+.vVl3#' );
define( 'NONCE_KEY',        '#sdusoZ{!?W;3Wo>)lyE-Tzj3Qh0KH%4pFLy.Ed7;F;m,$I0,yQo1_(=X%49$B}=' );
define( 'AUTH_SALT',        'w0gddA#0Bt8}=R@9#qx66Zjy[,?Y/.U/~X#,X.8J|OD|jJt[O$EQx_V$EA|4~cey' );
define( 'SECURE_AUTH_SALT', 'x7.Ypf}n?p/QaQty|N97THP>bO]$hO <Ri@H=4=zl[2qAhl8Gqv~2r]!f#@BCNMQ' );
define( 'LOGGED_IN_SALT',   'ZY)I!a*ejer,#Sx)s,A)q#y^xyDfAdw2BdWxLf&.%a^X}8>!P^DD?CcX&W5a40p}' );
define( 'NONCE_SALT',       'I~O:!J*78^@P+Y_<jduf;HZ*05T+6o!m]S=2,I*5>/QF(oV1}P1`<m;[N[{ey(%&' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* Add any custom values between this line and the "stop editing" line. */



/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOF
