### BUILD DOCKER IMAGE ###
  docker build -t pbxcentos .

### DOCKER VOLUMES ###
  docker volume create --name phpsession && docker volume create --name etc_asterisk && docker volume create --name var_mysql && docker volume create --name var_admin && docker volume create --name modules_asterisk

### DOCKER RUN IMAGE ###
  docker run --name freepbx -v etc_asterisk:/etc/asterisk -v phpsession:/var/lib/php/session -v var_mysql:/var/lib/mysql -v var_admin:/var/www/html/ -v modules_asterisk:/usr/lib64/asterisk/modules/ --net=host -d -t --restart=always --privileged pbxcentos
