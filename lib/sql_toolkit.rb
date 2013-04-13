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
    'select', 'from', 'where', 'group', 'order', 'having', 'as', 'with', 'by', 'limit', 'offset'
  ]
end

require "sql_toolkit/version"
require "sql_toolkit/sql"
