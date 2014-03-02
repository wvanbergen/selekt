require 'test_helper'

class SelektTest < Minitest::Test

  def test_safe_identifier
    assert_equal 'test', Selekt.safe_identifier('test')
    assert_equal %q["test'"], Selekt.safe_identifier(%q[test'])
    assert_equal %q["""test"""], Selekt.safe_identifier(%q["test"])
  end
end
