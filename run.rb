require 'parser/current'
require 'pathname'

require 'record_execution'


ASTNode.delete_all
TracePointEntry.delete_all
RubyObject.delete_all
RubyFile.delete_all


record_execution do
  bee = 'buzz'

  def add_random(i, max = 50)
    i + rand(max)
  end

  class Foo
    def bar
      'baz'
    end

    def self.class_bar
      a = 'fizz'

      a + 'buzz'
    end
  end

  lamb = lambda { 1 + 2 }

  puts add_random(rand(10))

  begin
    raise "Test error"
  rescue => e
    puts e.message
  end

  add_random(4).to_param
  Foo.new.bar
end
