require "treetop"

module SQLToolkit
  extend self

  RESERVED_SQL_KEYWORDS = [
    'select', 'from', 'where', 'group', 'order', 'having', 
    'limit', 'offset', 'as', 'by', 'with', 'distinct',
    'left', 'right', 'inner', 'full', 'outer', 'join', 'on', 'using', 'natural'
  ]

  def parser
    @parser ||= begin
      Treetop.load(File.expand_path('./sql_toolkit/sql.treetop', File.dirname(__FILE__)))
      SQLToolkit::SQLParser.new
    end
  end

  def parse(sql)
    parser.parse(sql.downcase)
  end

  def used_relations(sql)
    ast = parse(sql) or raise "Could not pare SQL query"
    find_nodes(ast, SQLToolkit::SQL::TableReference).map(&:text_value).uniq
  end

  def sources(sql)
    ast = parse(sql) or raise "Could not pare SQL query"
    find_nodes(ast, SQLToolkit::SQL::Source)
  end

  def source_aliases(sql)
    sources(sql).map(&:variable_name).uniq
  end

  protected

  def find_nodes(ast, ext_module)
    return [] if ast.elements.nil?
    results = ast.elements.map do |element|
      find_nodes(element, ext_module)
    end.flatten
      
    results.unshift(ast) if ast.extension_modules.include?(ext_module)
    return results
  end
end

require "sql_toolkit/version"
require "sql_toolkit/sql"
