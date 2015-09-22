# docker-zimbra
Zimbra Server

Example:  

    docker run \
      -d \
      -h mail.example.org \
      --name mail \
      --dns 8.8.8.8 \
      -p 25:25 \
      -p 110:110 \
      -p 143:143 \
      -p 389:389 \
      -p 456:456 \
      -p 587:587 \
      -p 993:993 \
      -p 995:995 \
      -p 7025:7025 \
      -p 7071:7071 \
      -p 7780:7780 \
      -p 9071:9071 \
      -p 80:80 \
      -p 443:443 \
      -p 10022:22 \
      --env="PASSWORD=testpass" \
      --env="HOSTNAME=mail" \
      --env="DOMAIN=example.org" \
      --env="ATOM_SUPPORT=true" \
      polinux/zimbra``
