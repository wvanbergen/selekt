require "treetop"

module SQLToolkit
  extend self

  RESERVED_SQL_KEYWORDS = [
    'select', 'from', 'where', 'group', 'order', 'having', 
    'limit', 'offset', 'as', 'by', 'with', 'distinct',
    'left', 'right', 'inner', 'full', 'outer', 'join', 'on', 'using', 'natural',
    'case', 'when', 'then', 'else', 'end',
    'over', 'partition', 'range', 'rows', 'window'
  ]

  class ParseError < StandardError; end

  def parser
    @parser ||= begin
      Treetop.load(File.expand_path('./sql_toolkit/sql.treetop', File.dirname(__FILE__)))
      SQLToolkit::SQLParser.new
    end
  end

  def parse(sql)
    SQLToolkit::Query.new(sql)    
  end
end

require "sql_toolkit/version"
require "sql_toolkit/sql"
require "sql_toolkit/query"
