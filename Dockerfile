FROM ruby:2.1.2

RUN gem install selenium 
RUN selenium install
RUN gem install selenium-webdriver 

ADD ./scripts/ /home/root/scripts

EXPOSE 4444 5999

ENTRYPOINT ["/home/root/scripts/loadme.rb"]
