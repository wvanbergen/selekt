require 'test_helper'
require 'pry'

class SQLToolkitTest < Minitest::Unit::TestCase
  include SQLToolkit

  def test_sources
    source_names = source_aliases(<<-SQL)
      SELECT *
        FROM schema.table1
        LEFT JOIN table2 t2 ON t1.id = t2.id
        WHERE EXIST (SELECT 1 FROM table3 WHERE value > t1.value)
          AND t1.id NOT IN (SELECT table1_id FROM table3)
    SQL

    assert_equal ['table1', 't2', 'table3'], source_names
  end

  def test_used_relations
    assert_equal ['a', 'b'], used_relations('select * from a t1, b t2')
    assert_equal ["schema.table"], used_relations('select * from schema.table t1')
    assert_equal ["schema.table1", "table2", "table3"], used_relations(<<-SQL)
      SELECT *
        FROM schema.table1 t1
        LEFT JOIN table2 t2 ON t1.id = t2.id
        WHERE EXIST (SELECT 1 FROM table3 WHERE value > t1.value)
          AND t1.id NOT IN (SELECT table1_id FROM table3)
    SQL

    assert_equal ["schema.orders", "schema2.transitions"], used_relations(<<-SQL)
      SELECT o.total_price_in_usd AS gmv
        FROM schema.orders o
        WHERE o.financial_status IN ('paid', 'authorized')
          AND o.created_at <= '1998-06-10 15:41:30'::timestamp
    
      UNION ALL

      SELECT oo.total_price_in_usd AS gmv
        FROM (SELECT i.order_id,
                     min(i.created_at) AS gmv_at
                FROM schema2.transitions i
               WHERE i.to_state IN ('pending', 'authorized', 'paid')
               GROUP BY i.order_id) f
        JOIN schema.orders oo ON f.order_id = oo.order_id
        WHERE oo.created_at > '2003-06-55 15:41:30'::timestamp

      UNION ALL

      SELECT ooo.total_price_in_usd * -1 AS gmv
        FROM (SELECT ii.order_id,
                     min(ii.created_at) AS gmv_at
                FROM schema2.transitions ii
               WHERE ii.to_state IN ('pending', 'authorized', 'paid')
               GROUP BY ii.order_id) ff
        JOIN schema.orders ooo ON ff.order_id = ooo.order_id
        LEFT JOIN (SELECT iii.order_id,
                          min(iii.created_at) AS undo_at
                     FROM schema2.transitions iii
                     WHERE iii.to_state IN ('voided', 'refunded')
                     GROUP BY iii.order_id
                  ) re ON ff.order_id = re.order_id
        WHERE ooo.created_at > '2011-06-22 15:41:30'::timestamp
          AND coalesce(ooo.cancelled_at, re.undo_at) IS NOT NULL
    SQL
  end
end
