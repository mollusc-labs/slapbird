# Stage 1: Build the Hugo site
FROM hugomods/hugo:latest AS hugo-builder

# Set the working directory
WORKDIR /src

# Copy hugo-book theme
RUN git clone http://github.com/alex-shpak/hugo-book.git ./themes/hugo-book

# Copy the Hugo site source files
COPY . .

# Build the site
RUN hugo

# Stage 2: Set up Apache to serve the built site
FROM httpd:alpine

# Copy the built Hugo site from the previous stage
COPY --from=hugo-builder /src/public/ /usr/local/apache2/htdocs/

# Copy custom Apache virtual host configuration
COPY apache.conf /usr/local/apache2/conf/extra/apache.conf

# Include the custom configuration in the main Apache config
RUN echo 'Include conf/extra/apache.conf' >> /usr/local/apache2/conf/httpd.conf

# Update Apache to listen on port 5555
# RUN sed -i 's/Listen 80/Listen 5555/' /usr/local/apache2/conf/httpd.conf
