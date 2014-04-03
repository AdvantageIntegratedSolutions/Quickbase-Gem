#Ruby Quickbase Gem for Humans

This gem is designed to be a concise, clear and maintainable collection of common Quickbase API calls used in ruby development. It implements a subset of the total Quickbase API.

##Example

##API Documentation
###New Connection

```ruby
qb_api = Advantage::QuickbaseAPI.new( :app_domain, :username, :password )
```

###Do Query Count
**do\_query\_count( db_id, query=nil )** => **Record Count**

```ruby
today = Date.today.strftime( '%Y-%m-%d' )
num_records = qb_api.do_query_count( 'abcd1234', "{1.EX.'#{today}'}" )
````

###Do Query
**do\_query( db\_id, query\_options )** => **JSON records**
Query Options expects a hash containing any of the following options:

* `query` - typical Quickbase query string. ex: `"{3.EX.'123'}"`
* `qid` - report or query id to load (should not be used with `query` or `qname`)
* `qname` - report or query name to load (should not be used with `query` or `qid`)
* `clist` - a list (Array or period-separated string) of fields to return
* `slist` - a list (Array or period-separated string) of fields to sort by
* `options` - string of additional options. ex: `"num-200.skp-#{records_processed}"`


```ruby
records = qb_api.do_query( 'bdjwmnj33', query: "{3.EX.'123'}", clist: [3, 6, 10] )
```