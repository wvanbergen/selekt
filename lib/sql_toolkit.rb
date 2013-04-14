require "polyglot"
require "treetop"

module SQLToolkit
  extend self

  def parser
    @parser ||= SQLToolkit::SQLParser.new
  end

  def parse(sql)
    parser.parse(sql.downcase)
  end

  RESERVED_SQL_KEYWORDS = [
    'select', 'from', 'where', 'group', 'order', 'having', 
    'limit', 'offset', 'as', 'by', 'with', 
    'left', 'right', 'inner', 'full', 'outer', 'join', 'on', 'using', 'natural'
  ]
end

require "sql_toolkit/version"
require "sql_toolkit/sql"
