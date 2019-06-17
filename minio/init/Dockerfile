FROM minio/mc

COPY entrypoint.sh /entrypoint.sh
COPY init.sh /init.sh

RUN set -x \
  && chmod +x /entrypoint.sh \
  && chmod +x /init.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/init.sh" ]
