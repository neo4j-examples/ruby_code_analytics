require 'pathname'

require 'record_execution'


ASTNode.delete_all
TracePointEntry.delete_all
RubyObject.delete_all
RubyFile.delete_all


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
