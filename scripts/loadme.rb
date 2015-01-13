#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'net/http'
require 'optparse'

DEFAULT_ACCESS_NUMBER = "8667401260"
DEFAULT_ACCESS_CODE = "TESTING"
DEFAULT_WEB_APP_HOST = "http://web:80"
DEFAULT_INSTANCE_NUM = 1
SELENIUM_HUB_URLS = ["http://hub:4444/wd/hub"]
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

  opts.on('-t', '--talk', 'clients will send audio if set') do |v|
    options[:talk] = v 
  end
  opts.on('-n', '--number NUMBER', 'number of clients to load') do |v|
    options[:number] = v 
  end
  opts.on('--accessNumber ACCESS_NUMBER', "default: #{DEFAULT_ACCESS_NUMBER}") do |v| 
    options[:accessNumber] = v
  end
  opts.on('--accessCode ACCESS_CODE', "default: #{DEFAULT_ACCESS_CODE}") do |v| 
    options[:accessCode] = v
  end
  opts.on('--webapp WEBAPP', "default: #{DEFAULT_WEB_APP_HOST}") do |v| 
    options[:webapp] = v
  end
  opts.on('--freeswitchServers FREESWITCH_SERVERS', 'comma-separated list') do |v| 
    options[:freeswitchservers] = v
  end
  opts.on('--turnServers TURN_SERVERS', 'comma-separated list') do |v| 
    options[:turnservers] = v
  end

end.parse!

instance_num = is_integer(options[:number]) ? Integer(options[:number]) : DEFAULT_INSTANCE_NUM
web_app_host = is_present(options[:webapp]) ? options[:webapp] : DEFAULT_WEB_APP_HOST
access_number = is_present(options[:accessNumber]) ? options[:accessNumber] : DEFAULT_ACCESS_NUMBER
access_code = is_present(options[:accessCode]) ? options[:accessCode] : DEFAULT_ACCESS_CODE
freeswitch_servers = is_present(options[:freeswitchservers]) ? options[:freeswitchservers] : nil
turn_servers = is_present(options[:turnservers]) ? options[:turnservers] : nil

puts "Using instance number = #{instance_num}"

web_app_url = web_app_host + "/voip-client/#/?an=#{access_number}&ac=#{access_code}"
web_app_url << "&freeswitchServers=#{freeswitch_servers}" if freeswitch_servers
web_app_url << "&turnServers=#{turn_servers}" if turn_servers
web_app_url << "&mode=testAudio" if options[:talk]

puts "Using web app url = #{web_app_url}"

$drivers = []

http = Net::HTTP.new(@host, @port)
http.read_timeout = 1000

# run test
count = 0
for hub in SELENIUM_HUB_URLS
  (1..instance_num).each do |n|
    driver = Selenium::WebDriver.for(:chrome, :url => hub, :switches => CHROME_SWITCHES)
    driver.navigate.to web_app_url
    
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
