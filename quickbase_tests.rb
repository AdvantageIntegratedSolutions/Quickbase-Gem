#! /usr/bin/env ruby

require 'yaml'
require_relative 'quickbase'

login_info = YAML.load_file( 'credentials.yml' )

puts login_info.inspect

print "Connect to Quickbase... "
quickbase = Advantage::QuickbaseAPI.new( 'ais', login_info['username'], login_info['password'] )
puts "complete."

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
