# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

#See:
#http://www.robotstxt.org/orig.html
#http://www.robotstxt.org/norobots-rfc.txt

require File.dirname(__FILE__) + '/../lib/spiderkit'

module Spider

  describe ExclusionParser do

    describe "General file handling" do
      it "should ignore comments" do
        txt = <<-eos
          user-agent: *
          allow: /
          #disallow: / 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be false 
      end

      it "should ignore comments starting with whitespace" do
        txt = <<-eos
          user-agent: *
          allow: /
             #disallow: / 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be false 
      end

      it "should cleanly handle winged comments" do
        txt = <<-eos
          user-agent: *
          allow: / #disallow: / 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be false 
      end

      it "should ignore unrecognized headers" do
        txt = <<-eos
          user-agent: *
          allow: /
          whargarbl: /
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be false 
      end 

      it "should completely ignore an empty file" do
        @bottxt = described_class.new('')
        expect(@bottxt.excluded?('/')).to be false 
        expect(@bottxt.excluded?('/test')).to be false 
      end

      it "should stop processing after 1000 directives" do
        txt = <<-eos
          user-agent: *
	eos

        (1..1002).each {|x| txt += "disallow: /#{x}--\r\n"}
        @bottxt = described_class.new(txt)

        #remember, we're doing start-of-string matching here,
        #so we need a delimiter or else 100 matches 1001, 1002...

        expect(@bottxt.excluded?('/1--')).to be true 
        expect(@bottxt.excluded?('/100--')).to be true 
        expect(@bottxt.excluded?('/1000--')).to be true 
        expect(@bottxt.excluded?('/1001--')).to be false 
        expect(@bottxt.excluded?('/1002--')).to be false 
      end

      it "should die cleanly on html" do
         txt = <<-eos
           <html>
		<head></head>
		<body></body>
	   </html>
	 eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be false
      end

      it "should drop byte order marks" do
        txt = <<-eos
	  \xEF\xBB\xBF
          user-agent: *
          disallow: /
	eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true
      end

      it "should be open if no user agent matches and there is no default" do
        txt = <<-eos
          user-agent: test1 
          disallow: /
          user-agent: test2
          disallow: /
	eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be false       
      end

      it "should handle nil text" do
        @bottxt = described_class.new(nil)
        expect(@bottxt.excluded?('/')).to be false       
      end

      it "should default to deny-all if unauthorized" do
        txt = <<-eos
          user-agent: *
          allow: /
        eos

        txt.http_status = 401
        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true

        txt.http_status = 403
        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true
      end
    end

    describe "General directive handling" do
      it "should split on CR" do
        txt = "user-agent: *\rdisallow: /"
        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true
      end

      it "should split on NL" do
        txt = "user-agent: *\ndisallow: /"
        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true
      end

      it "should split on CR/NL" do
        txt = "user-agent: *\r\ndisallow: /"
        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true
      end

      it "should be whitespace insensitive" do
        txt = <<-eos
          user-agent: *
          allow:	/tmp
            disallow: /
	eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true
        expect(@bottxt.excluded?('/tmp')).to be false
      end

      it "should match directives case insensitively" do
        txt = <<-eos
          user-agent: *
          DISALLOW: /test1
          ALLOW: /test2
          CRAWL-DELAY: 60
	eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/test1')).to be true
        expect(@bottxt.excluded?('/test2')).to be false
      end
    end

    describe "User agent handling" do
      it "should do a case insensitive agent match" do
        txt1 = <<-eos
          user-agent: testbot
          disallow: /
        eos
       
        txt2 = <<-eos
          user-agent: TESTbot 
          disallow: /
        eos

        txt3 = <<-eos
          user-agent: TESTBOT
          disallow: /
        eos

        @bottxt1 = described_class.new(txt1, 'testbot')
        @bottxt2 = described_class.new(txt2, 'testbot')
        @bottxt3 = described_class.new(txt3, 'testbot')

        expect(@bottxt1.excluded?('/')).to be true
        expect(@bottxt2.excluded?('/')).to be true
        expect(@bottxt3.excluded?('/')).to be true
      end
      
      it "should handle default user agent" do
        txt = <<-eos
          user-agent: *
          disallow: /test
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/test')).to be true
      end

      it "should use only the first of multiple default user agents" do
        txt = <<-eos
          user-agent: *
          disallow: /

          user-agent: *
          allow: /
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true
      end

      it "should give precedence to a matching user agent over default" do
        txt = <<-eos
          user-agent: testbot
          disallow: / 

          user-agent: *
          disallow: 
        eos
 
        @bottxt = described_class.new(txt, 'testbot')
        expect(@bottxt.excluded?('/')).to be true
      end

      xit "should allow cascading user-agent strings"
    end

    describe "Disallow directive" do
      it "should allow all urls if disallow is empty" do
        txt = <<-eos
          user-agent: *
          disallow: 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be false
        expect(@bottxt.excluded?('test')).to be false
        expect(@bottxt.excluded?('/test')).to be false
      end

      it "should blacklist any url starting with the specified string" do
        txt = <<-eos
          user-agent: *
          disallow: /tmp 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/tmp')).to be true
        expect(@bottxt.excluded?('/tmp1234')).to be true
        expect(@bottxt.excluded?('/tmp/stuff')).to be true
        expect(@bottxt.excluded?('/tmporary')).to be true

        expect(@bottxt.excluded?('/nottmp')).to be false
        expect(@bottxt.excluded?('tmp')).to be false
      end

      it "should blacklist all urls if root is specified" do
        txt = <<-eos
          user-agent: *
          disallow: / 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/')).to be true
        expect(@bottxt.excluded?('/nottmp')).to be true
        expect(@bottxt.excluded?('/test')).to be true
        expect(@bottxt.excluded?('nottmp')).to be true
        expect(@bottxt.excluded?('test')).to be true
      end

      it "should match urls case sensitively" do
        txt = <<-eos
          user-agent: *
          disallow: /tmp 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/tmp')).to be true
        expect(@bottxt.excluded?('/TMP')).to be false
        expect(@bottxt.excluded?('/Tmp')).to be false
      end

      it "should decode url encoded characters" do
        txt = <<-eos
          user-agent: *
          disallow: /a%3cd.html
        eos
 
        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/a%3cd.html')).to be true 
        expect(@bottxt.excluded?('/a%3Cd.html')).to be true 

        txt = <<-eos
          user-agent: *
          disallow: /a%3Cd.html
        eos
 
        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/a%3cd.html')).to be true 
        expect(@bottxt.excluded?('/a%3Cd.html')).to be true 
      end

      it "should not decode %2f" do
        txt = <<-eos
          user-agent: *
          disallow: /a%2fb.html
        eos
 
        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/a%2fb.html')).to be true 
        expect(@bottxt.excluded?('/a/b.html')).to be false 

        txt = <<-eos
          user-agent: *
          disallow: /a/b.html
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/a%2fb.html')).to be false 
        expect(@bottxt.excluded?('/a/b.html')).to be true 
      end

      it "should override allow if it comes first" do
        txt = <<-eos
          user-agent: *
          disallow: /tmp 
          allow: /tmp
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/tmp')).to be true
      end
    end
  
    describe "Allow directive" do
      it "should override disallow if it comes first" do
        txt = <<-eos
          user-agent: *
          allow: /tmp
          disallow: /tmp 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/tmp')).to be false
      end

      it "should override disallow root if it comes first" do
        txt = <<-eos
          user-agent: *
          allow: /tmp
          allow: /test
          disallow: / 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/tmp')).to be false
        expect(@bottxt.excluded?('/test')).to be false
        expect(@bottxt.excluded?('/other1')).to be true
        expect(@bottxt.excluded?('/other2')).to be true
      end

      it "allowing root should blacklist nothing" do
        txt = <<-eos
          user-agent: *
          allow: / 
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.excluded?('/tmp')).to be false
        expect(@bottxt.excluded?('/test')).to be false
        expect(@bottxt.excluded?('/zzz')).to be false
      end
    end

    describe "Crawl-Delay directive" do
      it "should set the crawl delay" do
        txt = <<-eos
          user-agent: *
          crawl-delay: 100
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.wait_time.value).to eq 100
      end

      it "should limit wait time to 180 seconds" do
        txt = <<-eos
          user-agent: *
          crawl-delay: 1000
        eos

        @bottxt = described_class.new(txt)
        expect(@bottxt.wait_time.value).to eq 180
      end
    end

    describe "RFC Examples" do
      it "#1" do
        txt = <<-eos
          User-agent: *
          Disallow: /org/plans.html
          Allow: /org/
          Allow: /serv
          Allow: /~mak
          Disallow: /
       eos

       @bottxt = described_class.new(txt)
       expect(@bottxt.excluded?('/')).to be true
       expect(@bottxt.excluded?('/index.html')).to be true
       expect(@bottxt.excluded?('/server.html')).to be false
       expect(@bottxt.excluded?('/services/fast.html')).to be false
       expect(@bottxt.excluded?('/services/slow.html')).to be false
       expect(@bottxt.excluded?('/orgo.gif')).to be true
       expect(@bottxt.excluded?('/org/about.html')).to be false
       expect(@bottxt.excluded?('/org/plans.html')).to be true 
       expect(@bottxt.excluded?('/%7Ejim/jim.html ')).to be true 
       expect(@bottxt.excluded?('/%7Emak/mak.html')).to be false
      end

      it "#2" do
        txt = <<-eos
          User-agent: *
          Disallow: /
       eos

       @bottxt = described_class.new(txt)
       expect(@bottxt.excluded?('/')).to be true
       expect(@bottxt.excluded?('/index.html')).to be true
       expect(@bottxt.excluded?('/server.html')).to be true
       expect(@bottxt.excluded?('/services/fast.html')).to be true
       expect(@bottxt.excluded?('/services/slow.html')).to be true
       expect(@bottxt.excluded?('/orgo.gif')).to be true
       expect(@bottxt.excluded?('/org/about.html')).to be true
       expect(@bottxt.excluded?('/org/plans.html')).to be true 
       expect(@bottxt.excluded?('/%7Ejim/jim.html ')).to be true 
       expect(@bottxt.excluded?('/%7Emak/mak.html')).to be true
      end

      it "#3" do
        txt = <<-eos
          User-agent: *
          Disallow: 
       eos

       @bottxt = described_class.new(txt)
       expect(@bottxt.excluded?('/')).to be false
       expect(@bottxt.excluded?('/index.html')).to be false
       expect(@bottxt.excluded?('/server.html')).to be false
       expect(@bottxt.excluded?('/services/fast.html')).to be false
       expect(@bottxt.excluded?('/services/slow.html')).to be false
       expect(@bottxt.excluded?('/orgo.gif')).to be false
       expect(@bottxt.excluded?('/org/about.html')).to be false
       expect(@bottxt.excluded?('/org/plans.html')).to be false 
       expect(@bottxt.excluded?('/%7Ejim/jim.html ')).to be false 
       expect(@bottxt.excluded?('/%7Emak/mak.html')).to be false
      end
    end
  end
end
