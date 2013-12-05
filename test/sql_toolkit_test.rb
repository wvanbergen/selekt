require 'test_helper'

class SQLToolkitTest < Minitest::Test

  def test_safe_identifier
    assert_equal 'test', SQLToolkit.safe_identifier('test')
    assert_equal %q["test'"], SQLToolkit.safe_identifier(%q[test'])
    assert_equal %q["""test"""], SQLToolkit.safe_identifier(%q["test"])
  end
end
