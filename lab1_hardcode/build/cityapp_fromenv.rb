#!/usr/bin/env ruby

require 'sinatra'
require 'cgi'
require 'json'
require 'mysql2'

enable :logging

# ==============================================
# Database Username and Password order - 1) Read from Environment variable 2) Fetch from Conjur using Ruby API
# 1) DBUsername and DBPassword = Environment Variable
# 2) DBUserName_CONJUR_VAR and DBPassword_CONJUR_VAR - variable reference in Conjur
# ==============================================

helpers do

  def dbport
    ENV['DBPort'] or "3306"
  end

  def dbaddress
    ENV['DBAddress'] or raise "Error: no Database Address defined"
  end

  def dbname
    ENV['DBName'] or raise "Error: no Database Name defined"
  end

  def dbusername
    ENV['DBUsername'] or raise "Error: no Username defined"
  end

  def dbpassword
    ENV['DBPassword'] or raise "Error: no Password defined"
  end
end

get '/' do
  begin
    mysqlclient = Mysql2::Client.new(host: dbaddress,
                                 username: dbusername,
                                 password: dbpassword,
                                 database: dbname)
    randomcity = mysqlclient.query('SELECT city.Name as City,country.name as Country,city.District,city.Population FROM city,country WHERE city.CountryCode = country.Code ORDER BY RAND() LIMIT 1').to_a[0]
    mysqlclient.close

    "<title> Random World Cities! </title>\n<br><br>\n<p style=\"font-size:30px\"><b>#{randomcity['City']}</b> is a city in #{randomcity['District']}, #{randomcity['Country']} with a population of #{randomcity['Population']}\n<br><br><br><p>\n<small>Connected to database #{dbname} on #{dbaddress}:#{dbport} using username: #{dbusername} and password: #{dbpassword}</small>\n"

  rescue
    $stderr.puts $!
    $stderr.puts $!.backtrace.join("\n")
    halt 500, "Error: #{$!}"
  end
end
