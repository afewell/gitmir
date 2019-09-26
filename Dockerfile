#
# Modified Ubuntu Dockerfile
#
# was originally based on https://github.com/dockerfile/ubuntu
#

# Pull base image.
FROM httpd:2.4

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y curl git nano jq && \
  rm -rf /var/lib/apt/lists/*

# Add files.
ADD root/.gitmir0.10.sh /usr/local/bin/gitmir
ADD root/.feederFile.json /root/feederFile.json
ADD root/.start.sh /root/start.sh
ADD root/.httpd.conf /usr/local/apache2/conf/httpd.conf
ADD root/.callGitmir.cgi /usr/local/apache2/cgi-bin/callGitmir.cgi
RUN curl https://pksninja-bucket.s3.us-east-2.amazonaws.com/gitmir-github-api -o /root/.token
ADD root/.index.html /usr/local/apache2/htdocs/index.html

#Set gitmir as executable
RUN chmod 755 /usr/local/bin/gitmir
RUN chmod 755 /root/start.sh
RUN chmod 755 /usr/local/apache2/cgi-bin/callGitmir.cgi
RUN chmod -R 755 /usr/local/apache2/htdocs
RUN chmod -R 755 /root
RUN chmod -R 755 /usr/local/apache2/cgi-bin
RUN chown -R daemon:daemon /usr/local/apache2/htdocs/
RUN chown -R daemon:daemon /usr/local/apache2/cgi-bin/

EXPOSE 80

CMD /root/start.sh
