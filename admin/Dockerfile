FROM perl:5.40
COPY . .
RUN cpan -I App::cpanminus
RUN cpanm -n --installdeps . --cpanfile cpanfile
CMD ["plackup", "--port", "9999", "admin.pl"]
