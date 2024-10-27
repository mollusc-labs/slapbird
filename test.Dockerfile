FROM perl:PERL_VERSION
RUN perl -V
COPY . .
COPY .env.test .env
RUN cpan -I App::cpanminus Test::Harness
RUN cpanm -n -f Module::Pluggable
RUN cpanm -n --installdeps . --cpanfile cpanfile # Install deps from cpanfile without testing them

CMD ["prove", "-Ilib", "t/"]
