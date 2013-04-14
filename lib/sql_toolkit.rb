require "treetop"

module SQLToolkit
  extend self

  RESERVED_SQL_KEYWORDS = [
    'select', 'from', 'where', 'group', 'order', 'having', 'union', 'all',
    'limit', 'offset', 'as', 'by', 'with', 'distinct',
    'left', 'right', 'inner', 'full', 'outer', 'join', 'on', 'using', 'natural',
    'case', 'when', 'then', 'else', 'end',
    'over', 'partition', 'range', 'rows', 'window'
  ]

  class ParseError < StandardError; end
  class StubError < StandardError; end

  def parser
    @parser ||= begin
      Treetop.load(File.expand_path('./sql_toolkit/sql.treetop', File.dirname(__FILE__)))
      SQLToolkit::SQLParser.new
    end
  end

  def parse(sql)
    SQLToolkit::Query.new(sql)    
  end

  def safe_identifier(id)
    id =~ /\A[a-z][a-z0-9_]*\z/i ? id : '"' + id.gsub('"', '""') + '"'
  end

  def quote(val)
    case val
      when NilClass; 'NULL'
      when TrueClass; 'TRUE'
      when FalseClass; 'FALSE'
      when Numeric; val.to_s
      when String; "'" + val.gsub("'", "''") + "'"
      else raise "Don't know how to quote #{val.inspect}!"
    end
  end
end

require "sql_toolkit/version"
require "sql_toolkit/sql"
require "sql_toolkit/query"
require "sql_toolkit/source_stub"
