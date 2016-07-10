# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

require 'bloom-filter'
require 'exclusion'

module Spider

  class VisitQueue
 
    class IterationExit < Exception; end

    attr_accessor :visit_count
    attr_accessor :robot_txt

    def initialize(robots=nil, agent=nil, finish=nil)
      @robot_txt = ExclusionParser.new(robots, agent) if robots
      @finalize = finish
      @visit_count = 0
      clear_visited
      @pending = []
    end 

    def visit_each
      begin
        until @pending.empty?
          url = @pending.pop
          if url_okay(url) 
            yield url if block_given?
            @visited.insert(url)
            @visit_count += 1
          end
        end 
      rescue IterationExit
      end
  
      @finalize.call if @finalize
    end 
    
    def push_front(urls)
      add_url(urls) {|u| @pending.push(u)}
    end 
  
    def push_back(urls)
      add_url(urls) {|u| @pending.unshift(u)}
    end 

    def size
      @pending.size
    end

    def empty?
      @pending.empty?
    end

    def stop
      raise IterationExit
    end

    def clear_visited
      @visited = BloomFilter.new(size: 10_000, error_rate: 0.001)
    end
  
    private

    def url_okay(url)
      return false if @visited.include?(url)
      return false if @robot_txt && @robot_txt.excluded?(url)
      true
    end
  
    def add_url(urls)
      urls = [urls] unless urls.is_a? Array
      urls.compact!
  
      urls.each do |url|
        unless @visited.include?(url)
          yield url
        end 
      end
    end
  end
end
