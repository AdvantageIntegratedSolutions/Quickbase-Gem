#Ruby Quickbase Gem for Humans

[![Gem Version](https://badge.fury.io/rb/advantage_quickbase.svg)](http://badge.fury.io/rb/advantage_quickbase)

This gem is designed to be a concise, clear and maintainable collection of common Quickbase API calls used in ruby development. It implements a subset of the total Quickbase API.

##Example
```ruby
# Create a new API connection
qb_api = AdvantageQuickbase::API.new( 'domain', 'username', 'password' )

# Load all of the Books in our table
query_options = { query: "{6.EX.'Book'}", clist: [7] }
books = qb_api.do_query( 'books_db_id', query_options )

puts books.inspect
# => [ {"7" => "Lord of the Flies"}, {"7" => "The Giver"} ]
```

##API Documentation
###New Connection

```ruby
qb_api = Advantage::QuickbaseAPI.new( :app_domain, :username, :password )
```
###Find
Find that singular Quickbase record and return as a json object


**find(db\_id, record\_id, query\_options)** => **[json] record**

###Create App Token
Create an app token that gives you access to that Quickbase app


**create\_app\_token(db\_id, description, page\_token)**

* `db_id` - database id
* `description` - description of what the token is for
* `page_token` - token hidden in the page DOM

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
