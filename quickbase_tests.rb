#! /usr/bin/env ruby


# README
# To use, create a config/credentials.yml file with 2 lines:
#  username: your_username
#  password: your_password


require 'yaml'
# require 'quickbase'
require_relative 'lib/quickbase'

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


print "find:... "
result = quickbase.find( 'bcyfufihg', 3 )
puts result.inspect

print "do_query: unstructured query... "
result = quickbase.do_query( 'bcyfufihg', query: '{3.EX."1000"}', fmt: '' )
puts result

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

print "import_from_csv with a hash... "
new_records = quickbase.import_from_csv( 'bhxa5rfap', [{6 => "CSV Import 1"}, {6 => ["CSV Import 2"]}] )
puts new_records.inspect

print "import_from_csv with empty data... "
new_records = quickbase.import_from_csv( 'bhxa5rfap', [] )
puts new_records.inspect

print "purge records... "
result = quickbase.purge_records( 'bhxa5rfap' )
puts result

print "import_from_csv with fucked data... "
new_records += quickbase.import_from_csv( 'bhxa5rfap', [["CSV Import\n\n1"], ["CSV & <Import> 2"]], [6] )
puts new_records.inspect

puts 'cleaning up... '
new_records.each do |rid|
  print "  deleting #{rid}... "
  result = quickbase.delete_record( 'bhxa5rfap', rid )
  puts result
end

#USERS
puts "get_user_info"
result = quickbase.get_user_info("kithensel@gmail.com")
puts result

puts "get_user_role"
result = quickbase.get_user_role("bcyfufihf", "57527431.cnhu")
puts result

puts "add_user_to_role"
result = quickbase.add_user_to_role("bcyfufihf", "57527431.cnhu", "39")
puts result

puts "remove_user_from_role"
result = quickbase.remove_user_from_role("bixwcdpqw", "57543186.chkp", "12")
puts result

puts "change_user_role"
result = quickbase.change_user_role("bcyfufihf", "57527431.cnhu", "39", "18")
puts result

puts "provision_user"
result = quickbase.provision_user("bcyfufihf", "kithensel@gmail.com", "39")
puts result

puts "get_app_access"
result = quickbase.get_app_access()
puts result

puts "deactivate_users"
result = quickbase.deactivate_users("120612", ["kithensel@gmail.com"])
puts result

puts "reactivate_users"
result = quickbase.reactivate_users("120612", ["kithensel@gmail.com"])
puts result

puts "deny_users"
result = quickbase.deny_users("120612", ["kithensel@gmail.com"])
puts result

puts "undeny_users"
result = quickbase.undeny_users("120612", ["kithensel@gmail.com"])
puts result

puts "find_db_by_name"
result = quickbase.find_db_by_name("Images")
puts result

puts "get_db_info"
result = quickbase.get_db_info("bcyfufihf")
puts result

puts "get_role_info"
result = quickbase.get_role_info("bixwcdpqw")
puts result

puts "get_users_access"
result = quickbase.get_users_access("bcyfufihf")
puts result

puts "remove_access"
result = quickbase.remove_access("bixwcdpqw", "kithensel@gmail.com")
puts result
