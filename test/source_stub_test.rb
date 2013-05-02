require 'test_helper'

class SourceStubTest < Minitest::Unit::TestCase

  def test_row_size_check
    ss = SQLToolkit::SourceStub.new(:a, :b)
    assert_raises(SQLToolkit::StubError) { ss.add_row [1,2,3] }
    assert_equal 0, ss.rows.size

    ss.add_row [1,2]
    assert_equal 1, ss.rows.size

    ss.add_row [1]
    assert_equal 2, ss.rows.size
  end

  def test_add_row_as_hash
    s1 = SQLToolkit::SourceStub.new(:a, :b)
    s2 = SQLToolkit::SourceStub.new(:a, :b)

    s1.push [1, 2]
    s2.push a: 1, b: 2

    assert_equal s1, s2
  end

  def test_add_row_as_hash_with_nil_values
    s1 = SQLToolkit::SourceStub.new(:a, :b)
    s2 = SQLToolkit::SourceStub.new(:a, :b)

    s1.push [nil, 1]
    s2.push b: 1

    assert_equal s1, s2
  end  

  def test_add_rows
    s1 = SQLToolkit::SourceStub.new(:a, :b)
    s1.add_rows([
      [1],
      { b: 2 }
    ])

    assert_equal [1, nil], s1.rows[0]
    assert_equal [nil, 2], s1.rows[1]
  end

  def test_sql_generation
    ss = SQLToolkit::SourceStub.new(:a, :b)
    ss.add_row [nil, 2]
    assert_equal "SELECT NULL AS a, 2 AS b", ss.sql
    ss.add_row ['test', 10]
    ss.add_row ['test2', 123]
    assert_equal "SELECT NULL AS a, 2 AS b\nUNION ALL\nSELECT 'test', 10\nUNION ALL\nSELECT 'test2', 123", ss.sql
  end
end