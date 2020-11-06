
RUN chmod 700 start.sh

# plumber dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update -q \
 && apt-get install -qy --no-install-recommends \
      libsodium-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# install plumber
RUN /usr/bin/R --no-save --slave -e "install.packages('plumber', clean=TRUE, verbose=FALSE)"

# on build, copy application files
ONBUILD COPY . /app

# on build, for installing additional dependencies etc.
ONBUILD RUN if [ -f "/app/onbuild" ]; then bash /app/onbuild; fi;

# on build, for backward compatibility, look for /app/Aptfile and if it exists, install the packages contained
ONBUILD RUN if [ -f "/app/Aptfile" ]; then export DEBIAN_FRONTEND=noninteractive && apt-get update -q && cat Aptfile | xargs apt-get -qy install && apt-get clean && rm -rf /var/lib/apt/lists/*; fi;

# on build, for backward compatibility, look for /app/init.R and if it exists, execute it
ONBUILD RUN if [ -f "/app/init.R" ]; then /usr/bin/R --no-init-file --no-save --slave -f /app/init.R; fi;

# on build, packrat restore packages
# NOTE: packrat itself is packaged in this same structure so will be bootstrapped here
ONBUILD RUN if [ -f "/app/packrat/init.R" ]; then /usr/bin/R --no-init-file --no-save --slave -f /app/packrat/init.R --args --bootstrap-packrat; fi;

# on build, renv restore packages
ONBUILD RUN if [ -f "/app/renv/activate.R" ]; then /usr/bin/R --no-save --slave -e 'renv::restore()'; fi;

FROM Adsata/heroku-docker-r

# ONBUILD will copy application files into the container
#  and execute init.R (if it exists) and restore packrat packages (if they exist)

# provide the port for Plumber, so that running/testing outside of Heroku is possible
# Heroku will override the PORT value at runtime
ENV PORT=8080

ENTRYPOINT ["/usr/local/src/start.sh"]
# override the base image CMD to run Plumber
CMD ["plumber.R"]

ARG BASE_IMAGE

FROM $BASE_IMAGE
