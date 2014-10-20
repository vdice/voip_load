#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'net/http'
require 'optparse'

ACCESS_NUMBER = "8667401260"
ACCESS_CODE = "2698043"
DEFAULT_WEB_APP_HOST = "http://web:80"
DEFAULT_INSTANCE_NUM = 1
SELENIUM_HUB_URLS = ["http://client:4444/wd/hub"]
CHROME_SWITCHES = %w[ --use-fake-device-for-media-stream --use-fake-ui-for-media-stream ]
CALL_BUTTON_ENABLED_TIMEOUT = 10


def is_integer(arg)
  return arg =~ /\A\d+\z/
end

def is_present(arg)
  return !(arg.nil?)
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage:  [options]"

  opts.on('-n', '--number NUMBER', 'number of clients to load') do |v|
    options[:number] = v 
  end
  opts.on('-w', '--webapp WEBAPP', 'web app url') do |v| 
    options[:webapp] = v
  end

end.parse!

instance_num = is_integer(options[:number]) ? Integer(options[:number]) : DEFAULT_INSTANCE_NUM
web_app_host = is_present(options[:webapp]) ? options[:webapp] : DEFAULT_WEB_APP_HOST

puts 'Using instance number = %d' % instance_num
puts 'Using web app host = %s' % web_app_host

web_app_url = web_app_host + "/#/?an=#{ACCESS_NUMBER}&ac=#{ACCESS_CODE}"
web_app_url_talk = web_app_url + "&mode=testAudio"


$drivers = []

http = Net::HTTP.new(@host, @port)
http.read_timeout = 1000

# run test
count = 0
for hub in SELENIUM_HUB_URLS
  (1..instance_num).each do |n|
    driver = Selenium::WebDriver.for(:chrome, :url => hub, :switches => CHROME_SWITCHES)
    driver.navigate.to web_app_url_talk
    
    callButton = driver.find_element(:id, 'callButton')
    count = count + 1
    wait = Selenium::WebDriver::Wait.new(:timeout => CALL_BUTTON_ENABLED_TIMEOUT)
    puts "Test Passed: Call Button #%d enabled" % [count] if wait.until {
      callButton.enabled?
    }

    sleep 2
    callButton.click()
    
    $drivers.push(driver)
  end
end

def shutdown
  puts 'Shutting down'
  for driver in $drivers 
    driver.quit()
  end
  exit
end

def waitForSigTerm
  trap('SIGTERM') {shutdown}
  trap('INT') {shutdown}
  loop {sleep 300000}
end  

waitForSigTerm
