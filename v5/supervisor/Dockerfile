FROM invoiceninja/invoiceninja:5

USER root

RUN apk add --no-cache supervisor \
  && mkdir /var/log/supervisord /var/run/supervisord \
  && chown $INVOICENINJA_USER:www-data /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /

USER $INVOICENINJA_USER

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
