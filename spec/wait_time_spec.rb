# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

require File.dirname(__FILE__) + '/../lib/spiderkit'

module Spider
  describe WaitTime do

    it 'should have a getter for the value' do
      wait = described_class.new(100)
      expect(wait.value).to eq(100)
    end

    it 'should clamp the wait time argument to three minutes' do
      wait = described_class.new(1000)
      expect(wait.value).to eq(180)
    end

    it 'should have a default wait time' do
      wait = described_class.new
      expect(wait.value).to eq(2)
    end
  
    describe '#back_off' do
      it 'if wait is zero, should set default wait time' do
        wait = described_class.new(0)
        wait.back_off
        expect(wait.value).to eq(2)
      end

      it 'should double the wait time every time called' do
        wait = described_class.new(10)
        wait.back_off
        expect(wait.value).to eq(20)
        wait.back_off
        expect(wait.value).to eq(40)
        wait.back_off
        expect(wait.value).to eq(80)
      end

      it 'should not double beyond the maximum value' do
        wait = described_class.new(90)
        wait.back_off
        expect(wait.value).to eq(180)
        wait.back_off
        expect(wait.value).to eq(180)
      end
    end
  end
end
