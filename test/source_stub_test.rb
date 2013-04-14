require 'test_helper'

class SourceStubTest < Minitest::Unit::TestCase

  def test_row_size_check
    ss = SQLToolkit::SourceStub.new(:a, :b)
    assert_raises(SQLToolkit::StubError) { ss.add_row [1] }
    assert_raises(SQLToolkit::StubError) { ss.add_row [1,2,3] }
    assert_equal 0, ss.rows.size

    ss.add_row [1,2]
    assert_equal 1, ss.rows.size    
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