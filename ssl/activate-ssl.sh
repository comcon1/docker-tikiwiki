#!/bin/bash

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
regen_ssl=0

function show_help() {
cat << EOF
After running docker-compose, you can modify the container by activating SSL.

    ./activate-ssl.sh [OPTIONS]
       -r  ...  regenerate self-signed SSL key
       -c  ...  container name, e.g. *docker-tikiwiki_tiki_1*
       -d  ...  domain name, e.g. *tiki.example.com*

If the key was already generated please copy files:

 domain-name.crt, domain-name.key 
 
.. and run this activator without regenerating keys.

Enjoy SSL ;)
EOF
}

while getopts "h?rcd" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    r)  regen_ssl=1
        ;;
    c)  container=$OPTARG
        ;;
    d)  domain=$OPTARG
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

# self-generation of the key-pair
if [[ $regen_ssl = 1 ]]; then
   openssl req -new -newkey rsa:4096 -x509 -sha256 \
        -days 365 -nodes \
        -out $domain.crt \
        -keyout $domain.key
fi

# copy certificates and correct paths
docker cp $domain.crt $container:/etc/ssl/certs
docker exec $container chown root: /etc/ssl/certs/$domain.crt
docker cp $domain.key $container:/etc/ssl/private
docker exec $container chown root: /etc/ssl/private/$domain.key
docker exec $container chmod 400 /etc/ssl/private/$domain.key

# change domain name in apache configs
sed -i "s/tiki.example.com/$domain/g" *.conf
# copy apache configs
docker cp default-ssl.conf $container:/etc/apache2/sites-available/default-ssl.conf
docker cp 000-default.conf $container:/etc/apache2/sites-available/000-default.conf

# turn on modules & apply changes
docker exec $container a2enmod ssl
docker exec $container a2ensite default-ssl
docker exec $container service apache2 restart

