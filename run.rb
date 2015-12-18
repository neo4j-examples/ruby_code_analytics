require 'pathname'
require 'record_execution'

puts 'Deleting ASTNodes from the database...'
ASTNode.delete_all
puts 'Deleting TracePointEntries from the database...'
TracePointEntry.delete_all
puts 'Deleting RubyObjects from the database...'
RubyObject.delete_all
puts 'Deleting RubyFiles from the database...'
RubyFile.delete_all

puts 'Recording execution...'
record_execution do
  def add_random(i, max = 50)
    i + rand(max)
  end

  class Foo
    def bar
      'baz'
    end

    def self.class_bar
      a = 'fizz'

      a + Fizz.buzz + add_random(4).to_s
    end
  end

  class Fizz
    def self.buzz
      'buzz'
    end
  end

  begin
    raise "Test error"
  rescue => e
    puts e.message
  end

  Foo.class_bar
  Foo.new.bar
end
