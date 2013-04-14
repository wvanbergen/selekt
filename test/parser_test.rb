require 'test_helper'

class ParserTest < Minitest::Unit::TestCase

  include SQLToolkit

  def test_projections
    assert parse(%q[    select 1, 'test', id, "id"  ])  
    assert parse('select *')
    assert parse('select table.*, other')
    assert parse('select schema.table.*')
    assert parse('select distinct schema.table.*')
    assert parse('select min(table)')
    assert parse('select count(*)')
    assert parse('select count(distinct *)')
    assert parse('select count(distinct id)')
    assert parse('select count(1) AS number_of_records')
  end

  def test_set_operations
    assert "select * from t1 union select * from t2"
    assert "select * from t1 union all select * from t2 union all select * from t3"
  end

  def test_sources
    assert parse('select * from t1')
    assert parse('select * from table1 "t1"')
    assert parse('select * from schema.table1 as t1')
    assert parse('select * from table_1 as "first table", table_2 as "second table"')
  end

  def test_joins
    assert parse('select * from table t1 join table t2 on t1.a = t2.a')
    assert parse('select * from t1 full outer join t2 using (country, state)')
    assert parse(<<-SQL)
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
    assert parse('select a from (select b) as b_alias')
    assert parse('select a from ( select b from (select c) as c_alias ) as b_alias')
  end

  def test_arithmetic_operators
    assert parse("select 'a' + 'b'")
    assert parse("select 'a' || ('b' || 'c') || 'd'")
    assert parse('select 1 + 2 - (3 * 4)::float / 5 % 6')
  end

  def test_comparison_operators
    assert parse('select 1 > 2')
    assert parse('select 1 + 2 > 2')
    assert !parse('select 1 > 2 > 3')
    assert parse('select a > b')
  end

  def test_boolean_tests
    assert parse('select column IS NOT TRUE')
    assert parse('select column IS NULL')
  end

  def test_function_calls
    assert parse('select MIN(column), now(), complicated_stuff(1, 4 + 2)')
  end

  def test_in_construct
    assert parse('select 1 IN (1,2,3)')
  end

  def test_exist_construct
    assert parse('select exist(select 1)')
    assert parse('select not exist (select 1)')
  end

  def test_boolean_operators
    assert parse('select (a > b AND b > c) OR a IS NULL OR c IS NULL')
    assert parse('select a >= 10 and b <= 0')
  end

  def test_where
    assert parse("select * from t1 where a = 'test' and b >= 10")
    assert parse('select a where (false)')
  end  

  def test_group_by_and_having
    assert parse('select a, b, min(c) min_c group by a, b')
    assert parse('select a, b, min(c) min_c group by a, b having a >= 10 and min_c')
  end

  def test_limit_offset
    assert parse('select * from table limit 10')
    assert parse('select * from table limit 10 offset 50')
  end

  def test_comments
    assert parse("select 1 -- comment\n")
    assert parse("select -- comment\n-- more comments \n 1")
    assert parse(<<-SQL)
      select 1,2,3,4 -- ... and so on
        from my_first_table,
             my_second_table
      -- EOQ
    SQL
  end

  def test_complicated_query
    assert parse(<<-SQL)

      SELECT o.total_price_in_usd AS gmv,
             o.created_at AS gmv_at
        FROM schema.orders o
        WHERE o.financial_status IN ('paid', 'authorized')
          AND o.created_at <= '1998-06-10 15:41:30'::timestamp
    
      UNION ALL

      SELECT oo.total_price_in_usd AS gmv,
             f.gmv_at
        FROM (SELECT i.order_id,
                     min(i.created_at) AS gmv_at
                FROM internal.order_financial_status_transitions i
               WHERE i.to_state IN ('pending', 'authorized', 'paid')
               GROUP BY i.order_id) f
        JOIN warehouse.orders oo ON f.order_id = oo.order_id
        WHERE oo.created_at > '2003-06-55 15:41:30'::timestamp

      UNION ALL

      SELECT ooo.total_price_in_usd * -1 AS gmv,
             coalesce(ooo.cancelled_at, re.undo_at) AS gmv_at
        FROM (SELECT ii.order_id,
                     min(ii.created_at) AS gmv_at
                FROM internal.transitions ii
               WHERE ii.to_state IN ('pending', 'authorized', 'paid')
               GROUP BY ii.order_id) ff
        JOIN warehouse.orders ooo ON ff.order_id = ooo.order_id
        LEFT JOIN (SELECT iii.order_id,
                          min(iii.created_at) AS undo_at
                     FROM internal.order_financial_status_transitions iii
                     WHERE iii.to_state IN ('voided', 'refunded')
                     GROUP BY iii.order_id
                  ) re ON ff.order_id = re.order_id
        WHERE ooo.created_at > '2011-06-22 15:41:30'::timestamp
          AND coalesce(ooo.cancelled_at, re.undo_at) IS NOT NULL
    SQL
  end
end
