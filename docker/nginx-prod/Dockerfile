FROM nginx:latest
ADD ./docker/nginx-prod/sites-enabled/scas /etc/nginx/conf.d/scas.conf

# ADD ./docker/dashboard.pem /etc/dashboard.pem

ARG SELF_SIGNED_SSL

RUN if [ "$SELF_SIGNED_SSL" = "true" ]; then \
    openssl req -x509 -nodes -days 3650 -subj "/C=CA/ST=QC/O=Company, Inc./CN=localhost" -addext "subjectAltName=DNS:localhost" -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt && \
    cat /etc/ssl/certs/nginx-selfsigned.crt /etc/ssl/private/nginx-selfsigned.key > /etc/dashboard.pem; \
    fi
