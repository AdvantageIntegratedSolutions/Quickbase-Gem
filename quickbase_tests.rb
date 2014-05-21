#! /usr/bin/env ruby


# README
# To use, create a config/credentials.yml file with 2 lines:
#  username: your_username
#  password: your_password


require 'yaml'
# require 'quickbase'
require_relative 'lib/quickbase'
require 'QuickbaseClient'

login_info = YAML.load_file( 'config/credentials.yml' )

puts login_info.inspect

print "Connect to Quickbase... "
quickbase = AdvantageQuickbase::API.new( 'ais', login_info['username'], login_info['password'] )
puts "complete."


puts "get_schema  Table ... "
result = quickbase.get_schema( 'bcyfufihg' )
result.each do |key, value|
  if key == :fields
    puts "fields => #{value.length} fields"
  else
    puts "#{key} => #{value}"
  end
end

puts "\nget_schema  App ... "
result = quickbase.get_schema( 'bcyfufihf' )
result.each do |key, value|
  if key == :tables
    puts "tables => #{value.length} tables"
  else
    puts "#{key} => #{value}"
  end
end


print "do_query_count: nil query... "
result = quickbase.do_query_count( 'bcyfufihg', nil )
puts result.inspect


print "do_query_count: basic query... "
expected_records = quickbase.do_query_count( 'bcyfufihg', '{3.GTE."1000"}' )
puts expected_records.inspect


print "do_query: basic query... "
result = quickbase.do_query( 'bcyfufihg', query: '{3.GTE."1000"}' )
puts result.length == expected_records


print "add_record... "
new_record_id = quickbase.add_record( 'bhxa5rfap', {6 => "First Gem Record"} )
puts "rid = #{new_record_id}"

print "edit_record... "
result = quickbase.edit_record( 'bhxa5rfap', new_record_id, {6 => "First Updated Record"} )
puts result

print "delete_record... "
result = quickbase.delete_record( 'bhxa5rfap', new_record_id )
puts result

print "import_from_csv... "
new_records = quickbase.import_from_csv( 'bhxa5rfap', [["CSV Import 1"], ["CSV Import 2"]], [6] )
puts new_records.inspect

puts 'cleaning up... '
new_records.each do |rid|
  print "  deleting #{rid}... "
  result = quickbase.delete_record( 'bhxa5rfap', rid )
  puts result
end
