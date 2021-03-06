# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

require 'bloomer'
require 'exclusion'

module Spider
  class VisitQueue

    IterationExit = Class.new(Exception)

    attr_accessor :visit_count
    attr_accessor :robot_txt

    def initialize(robots = nil, agent = nil, finish = nil)
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
          next unless url_okay(url)
          yield url.clone if block_given?
          @visited.add(url)
          @visit_count += 1
        end
      rescue IterationExit
      end

      @finalize.call if @finalize
    end

    def push_front(urls)
      add_url(urls) { |u| @pending.push(u) }
    end

    def push_back(urls)
      add_url(urls) { |u| @pending.unshift(u) }
    end

    def mark(urls)
      urls = [urls] unless urls.is_a? Array
      urls.each { |u| @visited.add(u) }
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
      @visited =  Bloomer.new(10_000, 0.001)
    end

    def url_okay(url)
      return false if @visited.include?(url)
      return false if @robot_txt && @robot_txt.excluded?(url)
      true
    end

    private

    def add_url(urls)
      urls = [urls] unless urls.is_a? Array
      urls.compact!

      urls.each do |url|
        yield url unless @visited.include?(url) || @pending.include?(url)
      end
    end
  end
end
