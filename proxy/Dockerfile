FROM nginx

RUN rm /etc/nginx/nginx.conf
ADD ./setup.sh /setup.sh

ENTRYPOINT [ "/bin/bash", "/setup.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]
