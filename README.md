#Ruby Quickbase Gem for Humans

This gem is designed to be a concise, clear and maintainable collection of common Quickbase API calls used in ruby development. It implements a subset of the total Quickbase API.

##Example

##API Documentation
###New Connection

```ruby
qb\_api = Advantage::QuickbaseAPI.new( :app_domain, :username, :password )
```

###Do Query Count
**do\_query\_count( db_id, query=nil )**

```ruby
today = Date.today.strftime( '%Y-%m-%d' )
num\_records = qb\_api.do\_query\_count( 'abcd1234', "{1.EX.'#{today}'}" )
````

###Do Query
**do\_query( db\_id, query\_options )**

```ruby

```