require 'neolytics'

puts 'Deleting ASTNodes from the database...'
ASTNode.delete_all
puts 'Deleting TracePointEntries from the database...'
TracePointEntry.delete_all
puts 'Deleting RubyObjects from the database...'
RubyObject.delete_all
puts 'Deleting RubyFiles from the database...'
RubyFile.delete_all

require 'nokogiri'

puts 'Recording execution...'
neo4j_session = Neo4j::Session.current
Neolytics.record_execution(neo4j_session) do
  def foo
    "returned string"
  end

  def bar(arg)
    puts arg
  end
  puts 'inside record_execution block'
  #doc = Nokogiri::HTML(open('http://stackoverflow.com/').read)

  #doc.xpath('//meta')

  def blah
    if 1 == 2 and true != false
      bar
    end
  end

  bar(foo)
end
