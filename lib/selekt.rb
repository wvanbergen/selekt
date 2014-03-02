require "treetop"
require "date"

module Selekt
  extend self

  RESERVED_SQL_KEYWORDS = [
    'select', 'from', 'where', 'group', 'order', 'having', 'union', 'all',
    'limit', 'offset', 'as', 'by', 'with', 'distinct',
    'left', 'right', 'inner', 'full', 'outer', 'join', 'on', 'using', 'natural',
    'case', 'when', 'then', 'else', 'end', 'interval',
    'over', 'partition', 'range', 'rows', 'window'
  ]

  class ParseError < StandardError; end
  class StubError < StandardError; end

  def parser
    @parser ||= begin
      Treetop.load(File.expand_path('./selekt/sql.treetop', File.dirname(__FILE__)))
      Selekt::SQLParser.new
    end
  end

  def parse(sql)
    Selekt::Query.new(sql)    
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
      when DateTime, Time; quote(val.strftime('%F %X')) + '::timestamp'
      when Date; quote(val.strftime('%F')) + '::date'
      else raise "Don't know how to quote #{val.inspect}!"
    end
  end
end

require "selekt/version"
require "selekt/sql"
require "selekt/query"
require "selekt/source_stub"
