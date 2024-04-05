FROM perl:5-slim AS deps
COPY . /slapbird
WORKDIR /slapbird
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y cpanminus libssl-dev libpq-dev gcc build-essential
RUN bin/install_deps

FROM deps
ENV SLAPBIRD_PRODUCTION=1
CMD ["perl", "app.pl", "prefork", "-m", "production"]
