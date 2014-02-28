# SQL toolkit [![Build Status](https://travis-ci.org/wvanbergen/sql_toolkit.png)](https://travis-ci.org/wvanbergen/sql_toolkit)

A toolkit to work with SQL queries, mostly for building test suites around
applications that use complex SQL queries. It includes:

- A SQL syntax parser, with abstract syntax tree manipulation tools.
- Stubbing tools to replace tables and subqueries in queries with static data.

The main use case for this library is building test suites for applications with
a complex database, for which it is infeasible to load fixtures data, due to 
performance or permission issues.

Personally, I have used it to test complicated view definitions for data
modeling purposes. Also, I have used it to speed up tests by replace the parts in 
a SQL query that would require disk access by a static stub.

The SQL syntax that is supported by the parser is ANSI SQL, with some support 
for PostgreSQL and Vertica extensions.

## Installation

Add this line to your application's Gemfile:

    gem 'sql_toolkit'

And run `bundle install`.

## Usage

Testing a complex query using stubs:

``` ruby
# Say we have this view definition, to get a list of your customers
# and whether they had at least one sale last month:
view_definition = <<-SQL
    SELECT c.name, COUNT(s.sale_id) >= 1 AS active
      FROM customers c 
      LEFT JOIN sales s ON s.customer_id = c.customer_id
        AND s.timestamp >= NOW() - INTERVAL '1 MONTH'
      GROUP BY c.customer_id
SQL

# To test this definition for different datasets in the
# customers and sales table, we would have to load different
# fixture sets, which would be hard and slow. Let's stub them 
# out instead.

query = SQLToolkit.parse(view_definition)

customers = SQLToolkit::SourceStub.new(:customer_id, :name)
customers << [1, "Willem"]

single_sale = SQLToolkit::SourceStub.new(:sale_id, :customer_id, :timestamp)
single_sale << [1, 1, Time.now]

# Replace the c and s source (the customers and sales tables) with our stubs
stubbed_query = query.stub('c', customers).stub('s', single_sale)

# Now, run the resulting query against your test DB to assert the right behavior.
result = db.query(stubbed_query.sql)
assert_equal 1, result.rows.length 
assert_equal true, result.rows[0][:active]

# Now let's try it with a sale that should not be counted.
old_sale = SQLToolkit::SourceStub.new(:sale_id, :customer_id, :timestamp)
old_sale << [1, 1, Time.now - 2.months]
stubbed_query = query.stub('c', customers).stub('s', old_sale)

result = db.query(stubbed_query.sql)
assert_equal 1, result.rows.length
assert_equal false, result.rows[0][:active]

# Finally, let's try it with an unrelated sale
no_sale = SQLToolkit::SourceStub.new(:sale_id, :customer_id, :timestamp)
no_sale << [1, 2, Time.now] # use a different customer_id
stubbed_query = query.stub('c', customers).stub('s', no_sale)

result = db.query(stubbed_query.sql)
assert_equal 1, result.rows.length 
assert_equal false, result.rows[0][:active] # is this going to pass?
```

This way, you can easily quickly test the behavior of your SQL queries, with
different sets of source data, without having to load different sets of
fixtures. This is a lot faster and you won't need data loading permissions
to run these tests.

### SourceStub

You don't have to use a `SQLToolkit::SourceStub` object when calling 
`query.stub(name, stub)`; any SQL query that the library can parse will be 
accepted. A source stub will simply generate a SQL query by joining
a static SELECT query for every row using UNION ALL:

``` ruby
customers = SQLToolkit::SourceStub.new(:customer_id, :name)
customers << [1, "Willem"]
customers << [2, "Aaron"]
customers.sql

# SELECT 1 AS customer_id, 'Willem' AS name
# UNION ALL
# SELECT 2 AS customer_id, 'Aaron' AS name
```

## Contributing

1. Fork it, and create your feature branch (`git checkout -b my-new-feature`)
2. Implement your changes and make sure there is test coverage for them.
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new pull request, and ping @wvanbergen.
