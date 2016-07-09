# Spiderkit

Spiderkit - Lightweight library for spiders and bots

## Installation

Add this line to your application's Gemfile:

    gem 'spiderkit'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spiderkit

##Well Behaved Spiders

Which is not to say you can't write ill-behaved spiders with this gem, but you're kind of a jerk if you do, and I'd really rather you didn't!  A well behaved spider will do a few simple things:

* It will download and obey robots.txt
* It will avoid repeatedly re-visiting pages
* It will wait in between requests / avoid agressive spidering
* It will honor rate-limit return codes
* It will send a valid User-Agent string

This library is written with an eye towards rapidly prototyping spiders that will do all of these things, plus whatever else you can come up with.

## Usage

Using Spiderkit, you implement your spiders and bots around the idea of a visit queue.  Urls (or any object you like) are added to the queue, and the queue is set to iterating. It obeys a few simple rules:

* You can add any kind of object you like
* You can add more objects to the queue as you iterate through it
* Once an object is iterated over, it's removed from the queue
* Once an object is iterated over, it's string value is added to an already-visited list, at which point you can't add it again.
* The queue will stop once it's empty, and optionally execute a final Proc that you pass to it
* The queue will not fetch web pages or anything else on it's own - that's part of what *you* implement.

A basic example:

```ruby

mybot = Spider::VisitQueue.new
mybot.push_front('http://someurl.com')

mybot.visit_each do |url|
  #fetch the url
  #pull out the links as linklist
  
  mybot.push_back(linklist)
end
```

A slightly fancier example:

```ruby
#download robots.txt as variable txt
#user agent is "my-bot/1.0"

finalizer = Proc.new { puts "done"}

mybot = Spider::VisitQueue.new(txt, "my-bot/1.0", finalizer)
```

As urls are fetched and added to the queue, any links already visited will be dropped transparently.  You have the option to push objects to either the front or rear of the queue at any time.  If you do push to the front of the queue while iterating over it, the things you push will be the next items visited, and vice versa if you push to the back:

```ruby

mybot.visit_each do |url|
  #these will be visited next
  mybot.push_front(nexturls)

  #these will be visited last
  mybot.push_back(lasturls)
end

```

The already visited list is implemented as a Bloom filter, so you should be able to spider even fairly large domains (and there are quite a few out there) without re-visiting pages.

Finally, you can forcefully stop spidering at any point:

```ruby

mybot.visit_each do |url|
  mybot.stop
end

```

The finalizer, if any, will still be executed after stopping iteration.

## Robots.txt

Spiderkit also includes a robots.txt parser that can either work standalone, or be passed as an argument to the visit queue.  If passed as an argument, urls that are excluded by the robots.txt will be dropped transparently.

```
#fetch robots.txt as variable txt

#create a stand alone parser
robots_txt = Spider::ExclusionParser.new(txt)

robots_txt.excluded?("/") => true
robots_txt.excluded?("/admin") => false
robots_txt.allowed?("/blog") => true

#pass text directly to visit queue
mybot = Spider::VisitQueue(txt)
```

Note that you pass the robots.txt directly to the visit queue - no need to new up the parser yourself.  The VisitQueue also has a robots_txt accessor that you can use to access and set the exclusion parser while iterating through the queue:

```ruby
mybot.visit_each |url|
  #download a new robots.txt from somewhere
  mybot.robot_txt = Spider::ExclusionParser.new(txt)
end
``` 

## Wait Time

Ideally a bot should wait for some period of time in between requests to avoid crashing websites (less likely) or being blacklisted (more likely).  A WaitTime class is provided that encapsulates this waiting logic, and logic to respond to rate limit codes and the "crawl-delay" directives found in some robots.txt files.  Times are in seconds.

You can create it standalone, or get it from an exclusion parser:

```ruby

#download a robots.txt with a crawl-delay 40

robots_txt = Spider::ExclusionParser.new(txt)
delay = robots_txt.wait_time
delay.value => 40

#receive a rate limit code, double wait time
delay.back_off

#actually do the waiting part
delay.wait

#in response to some rate limit codes you'll want
#to sleep for a while, then back off
delay.reduce_wait


#after one call to back_off and one call to reduce_wait
delay.value => 160

```

By default a WaitTime will specify an initial value of 2 seconds.  You can pass a value to new to specify the wait seconds, although values larger than the max allowable value will be set to the max allowable value (3 minutes / 180 seconds).

 
## Contributing

Bug reports, patches, and pull requests warmly welcomed at http://github.com/rdormer/spiderkit
