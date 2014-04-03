#Ruby Quickbase Gem for Humans

This gem is designed to be a concise, clear and maintainable collection of common Quickbase API calls used in ruby development. It implements a subset of the total Quickbase API.

##Example
```ruby
# Create a new API connection
qb_api = Advantage::QuickbaseAPI.new( 'ais', 'username', 'password' )

# Load all of the Books in our table
books = qb_api.do_query( 'books_db_id', query: "{6.EX.'Book'}", clist: [7] )

puts books.inspect
# => [ {"7" => 'Lord of the Flies'}, {"7" => 'The Giver'} ]
```

##API Documentation
###New Connection

```ruby
qb_api = Advantage::QuickbaseAPI.new( :app_domain, :username, :password )
```

###Do Query Count
**do\_query\_count( db_id, query=nil )** => **[int] Record Count**

```ruby
today = Date.today.strftime( '%Y-%m-%d' )
num_records = qb_api.do_query_count( 'abcd1234', "{1.EX.'#{today}'}" )
````

###Do Query
**do\_query( db\_id, query\_options )** => **[json] records**

`query_options` expects a hash containing any of the following options:

* `query` - typical Quickbase query string. ex: `"{3.EX.'123'}"`
* `qid` - report or query id to load (should not be used with `query` or `qname`)
* `qname` - report or query name to load (should not be used with `query` or `qid`)
* `clist` - a list (Array or period-separated string) of fields to return
* `slist` - a list (Array or period-separated string) of fields to sort by
* `options` - string of additional options. ex: `"num-200.skp-#{records_processed}"`


```ruby
records = qb_api.do_query( 'bdjwmnj33', query: "{3.EX.'123'}", clist: [3, 6, 10] )
```

###Add Record
**add\_record( db\_id, new\_data )** => **[int] New Record Id**

```ruby
new_data = { 6 => 'Book', 7 => 'My New Title' 8 => 'John Smith'}
new_record_id = qb_api.add_record( 'abcd1234', new_data )
````

###Edit Record
**edit\_record( db\_id, record\_id, new\_data )** => **[bool] Success?**

```ruby
new_data = { 7 => 'My Second Title' 8 => 'John Smith'}
call_successful = qb_api.edit_record( 'abcd1234', 136, new_data )
````

###Delete Record
**delete\_record( db\_id, record\_id )** => **[bool] Success?**

```ruby
call_successful = qb_api.delete_record( 'abcd1234', 136 )
````

###Import From CSV
**import\_form\_csv( db\_id, data, columns )** => **[json] New Record Ids**

```ruby
new_data = [
  ['Book', 'Lord of the Flies', 'William Golding'],
  ['Book', 'A Tale of Two Cities', 'Charles Dickens'],
  ['Book', 'Animal Farm', 'George Orwell']
]
record_ids = qb_api.import_from_csv( 'abcd1234', new_data, [6, 7, 8] )
````
