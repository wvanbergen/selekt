require 'test_helper'

class ParserTest < Minitest::Unit::TestCase

  def assert_parses(sql)
    q = SQLToolkit.parse(sql) rescue nil
    assert_instance_of SQLToolkit::Query, q, "Expected the provided string to parse as valid SQL"
  end

  def test_basic_syntax_flexibility
    assert_parses('select c1')
    assert_parses('SELECT c1')
    assert_parses('SeLeCT c1')
    assert_parses('  select    c1 , c2,    c3,c4   ')
  end

  def test_literals
    assert_parses 'select true, false, null'
    assert_parses "select 'test', 'test''with''quotes'"
    assert_parses 'select 1, -1, 1.2, .001, -1.2, -.001'
    assert_parses 'select c1 AS """Cool"" column", "c2"'
  end

  def test_projections
    assert_parses('select 1, \'test\', id, "id"')
    assert_parses('select *')
    assert_parses('select table.*, other, "fields"')
    assert_parses('select schema.table.*')
    assert_parses('select distinct schema.table.*')
    assert_parses('select min(table)')
  end

  def test_set_operations
    assert "select * from t1 union select * from t2"
    assert "select * from t1 union all select * from t2 union all select * from t3"
  end

  def test_sources
    assert_parses('select * from t1')
    assert_parses('select * from table1 "t1"')
    assert_parses('select * from schema.table1 as t1')
    assert_parses('select * from table_1 as "first table", table_2 as "second table"')
  end

  def test_joins
    assert_parses('select * from table t1 join table t2 on t1.a = t2.a')
    assert_parses('select * from t1 full outer join t2 using (country, state)')
    assert_parses(<<-SQL)
      SELECT *
        FROM table1 AS t1
        JOIN table2 AS t2 on t1.id = t2.id
        INNER JOIN (
          SELECT 1 AS id
        ) t3 ON t3.id = t1.id
        LEFT JOIN table4 t4 on t1.id = t4.id AND NOT t1.fraud
    SQL
  end

  def test_subquery
    assert_parses('select a from (select b) as b_alias')
    assert_parses('select a from ( select b from (select c) as c_alias ) as b_alias')
    assert_parses <<-SQL
      select * from (SELECT 'test' AS field_1, 123 AS field_2
      UNION ALL
      SELECT 'test', 456
      UNION ALL
      SELECT 'test', 789) AS t1
    SQL
  end

  def test_arithmetic_operators
    assert_parses("select 'a' + 'b'")
    assert_parses("select 'a' || ('b' || 'c') || 'd'")
    assert_parses('select 1 + 2 - (3 * 4)::float / 5 % 6')
  end

  def test_comparison_operators
    assert_parses('select 1 > 2')
    assert_parses('select 1 + 2 > 2')
    assert_parses('select a > b')
    assert_raises(SQLToolkit::ParseError) { SQLToolkit.parse('select 1 > 2 > 3') }
  end

  def test_boolean_tests
    assert_parses('select column IS NOT TRUE')
    assert_parses('select column IS NULL')
  end

  def test_function_calls
    assert_parses('select MIN(column), now(), complicated_stuff(1, 4 + 2)')
    assert_parses('select count(*)')
    assert_parses('select count(distinct *)')
    assert_parses('select count(distinct id)')
    assert_parses('select count(1)')
  end

  def test_over_clause
    assert_parses "SELECT ROW_NUMBER() OVER (ORDER BY a, b DESC)"
    assert_parses "SELECT ROW_NUMBER() OVER (PARTITION BY id ORDER BY time)"
    assert_parses "SELECT ROW_NUMBER() OVER (PARTITION BY id1, id2 ORDER BY time, event_id)"
    assert_parses "SELECT ROW_NUMBER() OVER w AS index WINDOW w AS (ORDER BY timestamp)"
  end

  def test_in_construct
    assert_parses('select 1 IN (1,2,3)')
  end

  def test_exist_construct
    assert_parses('select exist(select 1)')
    assert_parses('select not exist (select 1)')
  end

  def test_case_expression
    assert_parses 'select CASE column WHEN 1 THEN TRUE WHEN 2 THEN TRUE ELSE FALSE END'
    assert_parses 'select CASE column WHEN 1 THEN TRUE END'
    assert_parses 'select CASE WHEN column = 1 THEN TRUE ELSE FALSE END'
    assert_parses 'select CASE WHEN column <= 10 THEN TRUE WHEN column > 10 THEN FALSE END'
  end

  def test_interval_expression
    assert_parses "select NOW() + interval '10 day'"
    assert_parses "select NOW() + interval column"
  end

  def test_boolean_operators
    assert_parses('select (a > b AND b > c) OR a IS NULL OR c IS NULL')
    assert_parses('select a >= 10 and b <= 0')
  end

  def test_where
    assert_parses("select * from t1 where a = 'test' and b >= 10")
    assert_parses('select a where (false)')
  end

  def test_group_by_and_having
    assert_parses('select a, b, min(c) min_c group by a, b')
    assert_parses('select a, b, min(c) min_c group by a, b having a >= 10 and min_c')
  end

  def test_order_by
    assert_parses('select * from table order by field > 10')
    assert_parses('select * from table order by field1, field2')
    assert_parses('select * from table order by field ASC')
    assert_parses('select * from table order by field DESC NULLS FIRST')
  end

  def test_limit_offset
    assert_parses('select * from table limit 10')
    assert_parses('select * from table limit 10 offset 50')
  end

  def test_comments
    assert_parses("select 1 -- comment\n")
    assert_parses("select -- comment\n-- more comments \n 1")
    assert_parses(<<-SQL)
      select 1,2,3,4 -- ... and so on
        from my_first_table,
             my_second_table
      -- EOQ
    SQL
  end
end
