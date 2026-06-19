FROM nginx:1.29-alpine
LABEL maintainer="abhijitdinda228@gmail.com"
LABEL project="nginx-webserver"
LABEL version="1.0.0"
LABEL description="Static web server serving HTML, CSS, JS, images and PDFs"
RUN rm -rf /usr/share/nginx/html/*
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./website /usr/share/nginx/html/
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

