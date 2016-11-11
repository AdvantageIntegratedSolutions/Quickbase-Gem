#AIS QuickBase Ruby Gem

[![Gem Version](https://badge.fury.io/rb/advantage_quickbase.svg)](http://badge.fury.io/rb/advantage_quickbase)

This gem is designed to be a concise, clear and maintainable collection of common Quickbase API calls used in ruby development. It implements a subset of the total Quickbase API.

##Example
```ruby
require 'quickbase'

# Create a new API connection

qb_api = AdvantageQuickbase::API.new( domain, username, password, app_token, ticket, user_token )

# Load all of the Books in our table
query_options = { query: "{6.EX.'Book'}", clist: [7] }
books = qb_api.do_query( 'books_db_id', query_options )

puts books.inspect
# => [ {"7" => "Lord of the Flies"}, {"7" => "The Giver"} ]
```

##API Documentation
###New Connection

```ruby
qb_api = Advantage::QuickbaseAPI.new( domain, username, password, app_token, ticket, user_token )
```
###Find
**find(db\_id, record\_id, query\_options)** => **[json] record**

`query_options` expects a hash containing any (or none) of the following options:

* `clist` - a list (Array or period-separated string) of fields to return
* `fmt` - defaults to "structured"; use `fmt: ''` to set api responses to unstructured


```ruby
#Load the record that has a Record ID 8 from the books table
book = qb_api.find( 'books_db_id', 8, clist: [3, 7] )

puts book.inspect
# => {"3" => "8", "7" =>"The Giver"}
```

###Get DB Var
**get\_db\_var( app_id, variable_name )** => **[string] Variable Value**
```ruby
value = qb_api.get_db_var( 'abcd1234', 'test' )
````

###Set DB Var
**set\_db\_var( app_id, variable_name, value=nil )** => **[bool] Success?**
```ruby
qb_api.set_db_var( 'abcd1234', 'test', 'value' )
````

###Do Query Count
**do\_query\_count( db_id, query=nil )** => **[int] Record Count**

```ruby
today = Date.today.strftime( '%Y-%m-%d' )
num_records = qb_api.do_query_count( 'abcd1234', "{1.EX.'#{today}'}" )
````

###Do Query
**do\_query( db\_id, query\_options )** => **[json] records**

`query_options` expects a hash containing any (or none) of the following options:

* `query` - typical Quickbase query string. ex: `"{3.EX.'123'}"`
* `qid` - report or query id to load (should not be used with `query` or `qname`)
* `qname` - report or query name to load (should not be used with `query` or `qid`)
* `clist` - a list (Array or period-separated string) of fields to return
* `slist` - a list (Array or period-separated string) of fields to sort by
* `fmt` - defaults to "structured"; use `fmt: ''` to set api responses to unstructured
* `options` - string of additional options. ex: `"num-200.skp-#{records_processed}"`


```ruby
records = qb_api.do_query( 'bdjwmnj33', query: "{3.EX.'123'}", clist: [3, 6, 10] )
```

###Add Record
**add\_record( db\_id, new\_data )** => **[int] New Record Id**

```ruby
new_data = { 6 => 'Book', 7 => 'My New Title', 8 => 'John Smith'}
new_record_id = qb_api.add_record( 'abcd1234', new_data )
````

###Edit Record
**edit\_record( db\_id, record\_id, new\_data )** => **[bool] Success?**

```ruby
new_data = { 7 => 'My Second Title', 8 => 'John Smith'}
call_successful = qb_api.edit_record( 'abcd1234', 136, new_data )
````

###Delete Record
**delete\_record( db\_id, record\_id )** => **[bool] Success?**

```ruby
call_successful = qb_api.delete_record( 'abcd1234', 136 )
````

###Purge Records
**purge\_records( db\_id, options )** => **[int] Records Deleted**

`options` expects a hash containing any of the following options:

* `query` - typical Quickbase query string. ex: `"{3.EX.'123'}"`
* `qid` - report or query id to load (should not be used with `query` or `qname`)
* `qname` - report or query name to load (should not be used with `query` or `qid`)


```ruby
records_deleted = qb_api.purge_records( 'abcd1234', {qid: 6} )
````

###Get Schema
Get the complete schema of the whole quickbase app


**get_schema( db_id )**

```ruby
app_schema = qb_api.get_schema( 'abcd1234' )
````

###Import From CSV
**import\_from\_csv( db\_id, data, column\_field\_ids )** => **[json] New Record Ids**

```ruby
new_data = [
  ['Book', 'Lord of the Flies', 'William Golding'],
  ['Book', 'A Tale of Two Cities', 'Charles Dickens'],
  ['Book', 'Animal Farm', 'George Orwell']
]
record_ids = qb_api.import_from_csv( 'abcd1234', new_data, [6, 7, 8] )
````


###Create App Token
Create an app token that gives you access to that Quickbase app


**create\_app\_token(db\_id, description, page\_token)**

* `db_id` - database id
* `description` - description of what the token is for
* `page_token` - token hidden in the page DOM


```ruby
app_token = qb_api.create_app_token( 'abcd1234', 'Access all the books in the database', 'TugHxxkil9t6Kdebac' )
````
