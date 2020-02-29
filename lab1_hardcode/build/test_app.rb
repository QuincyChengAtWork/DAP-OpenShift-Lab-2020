#!/usr/bin/env ruby

require 'sinatra'
require 'conjur-api'
require 'cgi'
require 'json'
require 'mysql2'

enable :logging

helpers do
  def username
    raise "Expecting CONJUR_AUTHN_API_KEY to be blank" if ENV['CONJUR_AUTHN_API_KEY']
    ENV['CONJUR_AUTHN_LOGIN'] or raise "No CONJUR_AUTHN_LOGIN"
  end

  def sqlpassword
#    ENV['MySQLPassword'] or raise "No MySQLPassword defined in variable"
    ENV['MySQLPassword'] or conjur_api.resource("cyberark:variable:Vault/DBDemo/MySQL-APP/cityapp/password").value or raise "Error no password or variable defined"
  end

  def sqlusername
    ENV['MySQLUsername'] or raise "No MySQLUsername defined in variable"
  end

  def conjur_api
    # Ideally this would be done only once.
    # But for testing, it means that if the login fails, the pod is stuck in a bad state
    # and the tests can't be performed.
    Conjur.configuration.apply_cert_config!
    token = JSON.parse(File.read("/run/conjur/access-token"))
    Conjur::API.new_from_token(token)
  end

#  Mysqlclient = Mysql2::Client.new(host: 'mysqldb01.cyberark.local',
#                                 username: 'cityappA',
#                                 password: 'e]4zoYAW6F,4avx',
#                                 database: 'world')

#  def get_city
#    Mysqlclient.query('SELECT Name,CountryCode,District,Population FROM city ORDER BY RAND() LIMIT 1')
#  end



end

get '/' do
  begin
#    sqlpassword = conjur_api.resource("cyberark:variable:Vault/DBDemo/MySQL-APP/cityapp/password").value
#    sqlusername = conjur_api.resource("cyberark:variable:Vault/DBDemo/MySQL-APP/cityapp/username").value
#    sqlpassword = ENV['MySQLPassword']
#    sqlusername = ENV['MySQLUserName']
#    mydata = get_city

    Mysqlclient = Mysql2::Client.new(host: 'mysqldb01.cyberark.local',
                                 username: sqlusername,
                                 password: sqlpassword,
                                 database: 'world')

    randomcity = Mysqlclient.query('SELECT city.Name as City,country.name as Country,city.District,city.Population FROM city,country WHERE city.CountryCode = country.Code ORDER BY RAND() LIMIT 1').to_a[0]


#    "username: #{sqlusername} and password: #{sqlpassword} <br> Random city - #{randomcityto_a[0]['Name']} is a city in #{randomcityto_a[0]['District']  has population } <br>"
    "Connecting to database using username: #{sqlusername} and password: #{sqlpassword} \n<br> <br>\n<b>#{randomcity['City']}</b> is a city in #{randomcity['District']}, #{randomcity['Country']} with a population of #{randomcity['Population']}\n<br>"
  rescue
    $stderr.puts $!
    $stderr.puts $!.backtrace.join("\n")
    halt 500, "Error: #{$!}"
  end
end

