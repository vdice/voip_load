FROM ubuntu:14.04

RUN apt-get update 
RUN apt-get install -y emacs24 ruby1.9.1-dev build-essential
RUN sudo gem install selenium 
RUN selenium install
RUN sudo gem install selenium-webdriver 

ADD ./scripts/ /home/root/scripts

EXPOSE 4444 5999

ENTRYPOINT ["/home/root/scripts/loadme.rb"]
