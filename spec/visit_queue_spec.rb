# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

require File.dirname(__FILE__) + '/../lib/spiderkit'

def get_visit_order(q)
  order = []

  q.visit_each do |t|
    order << t
  end

  order
end


module Spider

  describe VisitQueue do
    before(:each) do
      @queue = described_class.new
      @queue.push_front('divider')
    end

    it 'should allow appending to front of the queue' do
      @queue.push_front('two')
      @queue.push_front('one')

      order = get_visit_order(@queue)
      expect(order).to eq %w(one two divider)
    end

    it 'should allow appending to the back of the queue' do
      @queue.push_back('one')
      @queue.push_back('two')

      order = get_visit_order(@queue)
      expect(order).to eq %w(divider one two)
    end

    it 'should allow appending array of urls to front of the queue' do
      @queue.push_front(%w(two one))
      order = get_visit_order(@queue)
      expect(order).to eq %w(one two divider)
    end

    it 'should allow appending array of urls to back of the queue' do
      @queue.push_back(%w(one two))
      order = get_visit_order(@queue)
      expect(order).to eq %w(divider one two)
    end

    it 'should not allow appending nil to the queue' do
      expect(@queue.size).to eq 1

      @queue.push_back(nil)
      @queue.push_front(nil)
      @queue.push_back([nil, nil, nil])
      @queue.push_front([nil, nil, nil])

      expect(@queue.size).to eq 1
    end

    it 'should visit urls appended during iteration' do
      @queue.push_front(%w(one two))
      extra_urls = %w(three four five)
      order = []

      @queue.visit_each do |t|
        order << t
        @queue.push_back(extra_urls.pop)
      end

      expect(order).to eq %w(two one divider five four three)
    end
    
    it 'should ignore appending if url has already been visited' do
      @queue.visit_each
      expect(@queue.empty?).to be true
      @queue.push_back('divider')
      @queue.push_front('divider')
      @queue.push_back(%w(divider divider))
      @queue.push_front(%w(divider divider))
      expect(@queue.empty?).to be true
    end

    it 'should not insert urls already in the pending queue' do
      @queue.push_back(%w(one two three))
      expect(@queue.size).to eq 4
      @queue.push_back(%w(one two three))    
      expect(@queue.size).to eq 4
    end

    it 'should track number of urls visited' do
      expect(@queue.visit_count).to eq 0
      @queue.push_back(%w(one two three four))
      @queue.visit_each
      expect(@queue.visit_count).to eq 5
    end

    it 'should not visit urls blocked by robots.txt' do
rtext = <<-REND
  User-agent: *
  disallow: two
  disallow: three
  disallow: four 
REND

      rtext_queue = described_class.new(rtext)
      rtext_queue.push_front(%w(one two three four five six)) 
      order = get_visit_order(rtext_queue)
      expect(order).to eq %w(six five one)
    end

    it 'should execute a finalizer if given' do
      flag = false
      final = Proc.new { flag = true }
      queue = described_class.new(nil, nil, final)
      queue.visit_each
      expect(flag).to be true
    end

    it 'should execute the finalizer even when breaking the loop' do
      flag = false
      final = Proc.new { flag = true }
      queue = described_class.new(nil, nil, final)
      queue.push_back((1..20).to_a)
      queue.visit_each { queue.stop if queue.visit_count >= 1 }
      expect(queue.visit_count).to eq 1
      expect(flag).to be true
    end

    it 'should allow you to clear the visited list' do
      @queue.push_front(%w(one two three))
      order = get_visit_order(@queue)
      expect(order).to eq %w(three two one divider)
      expect(@queue.visit_count).to eq 4

      @queue.push_front(%w(one two three))     
      order = get_visit_order(@queue)
      expect(order).to be_empty
      expect(@queue.visit_count).to eq 4

      @queue.clear_visited    
      @queue.push_front(%w(one two three))
      order = get_visit_order(@queue)
      expect(order).to eq %w(three two one)
      expect(@queue.visit_count).to eq 7 
    end

  end

end
