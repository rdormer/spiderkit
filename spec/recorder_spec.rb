# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

require File.dirname(__FILE__) + '/../lib/spiderkit'

module Spider
  describe VisitRecorder do

    describe 'when active' do
      before(:each) do
        described_class.activate!
        described_class.record!
        @url = "http://test.domain.123"
      end
  
      it 'should add http_status to string' do
        expect("".respond_to? :http_status).to be true
      end

      it 'should add http_headers to string' do
        expect("".respond_to? :http_headers).to be true
      end

      it 'should execute the block argument if recording data' do
        run_data = ''
        buffer = StringIO.new
        allow(buffer).to receive(:size?).and_return(0)
        allow(File).to receive(:open).and_return(buffer)
        described_class.recall(@url) { |u| run_data = 'ran' }
        expect(run_data).to eq 'ran'
      end

      describe 'saved information' do
        before(:each) do
          @buffer = StringIO.new
          allow(File).to receive(:open).and_return(@buffer)
          allow(@buffer).to receive(:size?).and_return(0)

          @data = described_class.recall(@url) do |u|
            rval = "this is the test body"
            rval.http_headers = "test headers"
            rval.http_status = 200
            rval
          end

          @buffer.rewind
        end

        it 'should save and return headers' do
          expect(@data.http_headers).to eq "test headers"
          data = YAML.load(@buffer.read)
          expect(data[:headers]).to eq Base64.encode64("test headers")
        end
  
        it 'should save the request url' do
          data = YAML.load(@buffer.read)
          expect(data[:url]).to eq @url
        end

        it 'should save response code' do
          data = YAML.load(@buffer.read)
          expect(data[:response]).to eq 200
        end

        it 'should save and return the response data' do
          expect(@data).to eq "this is the test body"
          data = YAML.load(@buffer.read)
          expect(data[:data]).to eq Base64.encode64("this is the test body")
        end

        it 'should bypass the block argument if playing back data' do
          run_flag = false
          described_class.recall(@url) { |u| run_flag = true }
          expect(run_flag).to be false
        end
      end

      describe 'file operations' do
        before(:each) do
          @path = "test_path/"
          @buffer = StringIO.new
          @fname = Digest::MD5.hexdigest(@url)
          allow(File).to receive(:open).and_return(@buffer)
          expect(File).to receive(:size?).and_return(0)
          described_class.config('/')
        end

        it 'name file as md5 hash of url with query' do
          expect(File).to receive(:open).with('/' + @fname, 'w')
          described_class.recall(@url) { |u| 'test data' }
        end

        it 'should not overwrite existing files' do
          File.size?
          expect(File).to receive(:size?).and_return(1234)
          expect(File).to receive(:open).with('/' + @fname, 'r')
          described_class.recall(@url) { |u| 'test data' }
        end
      end
    end

    describe 'when not active' do
      before(:all) do
        described_class.pause!
        described_class.deactivate!
      end

      it 'should not record unless activated and recording enabled' do
        expect(File).to_not receive(:size?)
        expect(File).to_not receive(:open)
      end

      it 'should pass the return of the block through' do
        expect(described_class.recall(@url) { |u| 'test data' }).to eq 'test data'
      end

      it 'should not playback if not active' do
        data = {data: Base64.encode64('test data should not appear')}.to_yaml
        @buffer = StringIO.new(data)
        allow(File).to receive(:open).and_return(@buffer)
        result = described_class.recall(@url) { |u| 'test data' }
        expect(result).to_not eq 'test data should not appear'
        expect(result).to eq 'test data'
      end
    end
  end
end
