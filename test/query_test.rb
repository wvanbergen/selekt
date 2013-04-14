require 'test_helper'

class QueryTest < Minitest::Unit::TestCase

  def test_sql_roundtrip
    query = 'select * from table'
    assert_equal query, SQLToolkit.parse(query).sql
  end

  def test_sources
    source_names = SQLToolkit.parse(<<-SQL).source_names
      SELECT *
        FROM schema.table1
        LEFT JOIN table2 t2 ON t1.id = t2.id
        WHERE EXIST (SELECT 1 FROM table3 WHERE value > t1.value)
          AND t1.id NOT IN (SELECT table1_id FROM table3 t3)
    SQL

    assert_equal ['table1', 't2', 'table3', 't3'], source_names
  end

  def test_stubbing_sources
    query = SQLToolkit.parse('select * from t1')
    assert_equal "select * from (select 1) AS t1", query.stub('t1', 'select 1').sql

    t1_stub = SQLToolkit::SourceStub.new(:field_1, :field_2)
    t1_stub << ['test', 123]
    t1_stub << ['test', 456]
    t1_stub << ['test', 789]

    assert_equal query.stub(:t1, t1_stub).sql, "select * from (SELECT 'test' AS field_1, 123 AS field_2\nUNION ALL\nSELECT 'test', 456\nUNION ALL\nSELECT 'test', 789) AS t1"
  end

  def test_relations
    assert_equal ['a', 'b'], SQLToolkit.parse('select * from a t1, b t2').relations.map(&:table_name)

    query = SQLToolkit.parse('select * from schema.table t1 INNER JOIN schema.table t2 ON 1=1')
    assert_equal ["schema"], query.relations.map(&:schema_name)
    assert_equal ["table"], query.relations.map(&:table_name)
    
    query = SQLToolkit.parse(<<-SQL)
      SELECT *
        FROM schema."table1" t1
        LEFT JOIN table2 t2 ON t1.id = t2.id
        WHERE EXIST (SELECT 1 FROM table3 WHERE value > t1.value)
          AND t1.id NOT IN (SELECT table1_id FROM table3)

      UNION

      SELECT *
        FROM table5 t5
        LEFT JOIN (
          SELECT * FROM schema.table6
        ) AS t6 ON t6.id = t5.id
    SQL
    assert_equal ["schema.table1", "table2", "table3", "table5", "schema.table6"], query.relations.map(&:to_s)
  end
end
