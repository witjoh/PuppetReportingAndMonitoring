require 'json'
require 'net/http'
require 'uri'

last_manhosts = 0
last_manresources = 0
last_avgresources = 0
numberofresources = 0
numberofhosts = 0
avgresources = 0

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '5s', :first_in => 0, :allow_overlapping => false do | puppet |

# the times in puppetdb are stored in UTC
# Time.now returns then in CEST.  So we need to convert that to UTC
utc_time          = Time.now.gmtime
time_past         = (utc_time - 10080)
zombie_time       = (utc_time - 10080*4)
ftime_now         = utc_time.strftime("%FT%T")
ftime_past        = time_past.strftime("%FT%T")
ftime_zombie      = zombie_time.strftime("%FT%T")
last_manhosts     = numberofhosts
last_manresources = numberofresources
last_avgresources = avgresources

puppetdb = '192.168.10.150'

@failedhosts = []
@deadhosts   = []
@zombiehosts = []
@failed      = 0
@changed     = 0
@pending     = 0
@deadcount   = 0
@zombiecount = 0
@failedtext  = ''
@deadtext    = ''
@zombietext  = ''

nodes = JSON.parse(Net::HTTP.get_response(URI.parse("http://#{puppetdb}:8080/v3/nodes/")).body)
numberofhosts = JSON.parse(Net::HTTP.get_response(URI.parse("http://#{puppetdb}:8080/v3/metrics/mbean/com.puppetlabs.puppetdb.query.population:type=default,name=num-nodes")).body)["Value"]
numberofresources = JSON.parse(Net::HTTP.get_response(URI.parse("http://#{puppetdb}:8080/v3/metrics/mbean/com.puppetlabs.puppetdb.query.population:type=default,name=num-resources")).body)["Value"]
avgresources = JSON.parse(Net::HTTP.get_response(URI.parse("http://#{puppetdb}:8080/v3/metrics/mbean/com.puppetlabs.puppetdb.query.population:type=default,name=avg-resources-per-node")).body)["Value"].round

nodes.each do |node|
  uri = URI.parse("http://#{puppetdb}:8080/v3/event-counts/")
  uri.query = URI.encode_www_form(:query => %Q'["and", ["=", "certname", "#{node['name']}"],["<", "timestamp", "#{ftime_now}"],[">", "timestamp", "#{ftime_past}"],["=", "latest-report?", "true"]]', :'summarize-by' => 'certname', :'count-by' => 'resource')

  events = JSON.parse(Net::HTTP.get_response(uri).body)
  events.each do |event|
    if event['failures'] > 0
      @failedhosts << event['subject']['title']
      @failed += 1
    elsif event['noops'] > 0
      @pending += 1
    elsif event['successes'] > 0
      @changed += 1
    end
  end
end

# look for those nodes which does not have run a proper pupper session more then a week ago

nodes.each do |node|
  uri = URI.parse("http://#{puppetdb}:8080/v3/event-counts/")
  uri.query = URI.encode_www_form(:query => %Q'["and", ["=", "certname", "#{node['name']}"],["<", "timestamp", "#{ftime_past}"],["=", "latest-report?", "true"]]', :'summarize-by' => 'certname', :'count-by' => 'resource')

  events = JSON.parse(Net::HTTP.get_response(uri).body)
  events.each do |event|
    @deadhosts << event['subject']['title']
    @deadcount += 1
  end
end

nodes.each do |node|
  uri = URI.parse("http://#{puppetdb}:8080/v3/event-counts/")
  uri.query = URI.encode_www_form(:query => %Q'["and", ["=", "certname", "#{node['name']}"],["<", "timestamp", "#{ftime_zombie}"],["=", "latest-report?", "true"]]', :'summarize-by' => 'certname', :'count-by' => 'resource')

  events = JSON.parse(Net::HTTP.get_response(uri).body)
  events.each do |event|
    @zombiehosts << event['subject']['title']
    @zombiecount += 1
  end
end

send_event('pupfailed', {value: @failed})
send_event('puppending', {value: @pending})
send_event('pupchanged', {value: @changed})
send_event('deadcount', {value: @deadcount})
send_event('zombiecount', {value: @zombiecount})
send_event('manhosts', {current: numberofhosts, last: last_manhosts})
send_event('manresources', {current: numberofresources, last: last_manresources})
send_event('avgresources', {current: avgresources, last: last_avgresources})

@failedhosts.each do |host|
  @failedtext << "#{host} \n"
end

#send_event('failedhosts', {text: @failedtext})

@deadhosts.each do |host|
  @deadtext << "#{host} \n"
end
#send_event('deadhosts', {text: @deadtext})

@zombiehosts.each do |host|
  @zombietext << "#{host} \n"
end
#send_event('zombiehosts', {text: @zombietext})

end


