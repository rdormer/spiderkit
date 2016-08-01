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

Since you need to implement page fetching on your own (using any of a number of high quality gems or libararies), you'll also need to implement the associated error checking, network timeout handling, and sanity checking that's involved.  If you handle redirects by pushing them onto the queue, however, then you'll at least get a little help where redirect loops are concerned.

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
# download robots.txt as variable txt
# user agent for robots.txt is "my-bot"

finalizer = Proc.new { puts "done"}
mybot = Spider::VisitQueue.new(txt, "my-bot", finalizer)
```

As urls are fetched and added to the queue, any links already visited will be dropped transparently.  You have the option to push objects to either the front or rear of the queue at any time.  If you do push to the front of the queue while iterating over it, the things you push will be the next items visited, and vice versa if you push to the back:

```ruby
mybot.visit_each do |url|
  # these will be visited next
  mybot.push_front(nexturls)

  # these will be visited last
  mybot.push_back(lasturls)
end
```

The already visited list is implemented as a Bloom filter, so you should be able to spider even fairly large domains (and there are quite a few out there) without re-visiting pages.  You can get a count of pages you've already visited at any time with the visit_count method.

If you need to clear the visited list at any point, use the clear_visited method:

```ruby
mybot.visit_each do |url|
  mybot.clear_visited
end
```

After which you can push urls onto the queue regardless of if you visited them before clearing.  However, the queue will still refuse to visit them once you've done so again.  Note also that the count of visited pages will *not* reset.

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
# fetch robots.txt as variable txt

# create a stand alone parser
robots_txt = Spider::ExclusionParser.new(txt)

robots_txt.excluded?("/") => true
robots_txt.excluded?("/admin") => false
robots_txt.allowed?("/blog") => true

# pass text directly to visit queue
mybot = Spider::VisitQueue(txt)
```

Note that you pass the robots.txt directly to the visit queue - no need to new up the parser yourself.  The VisitQueue also has a robots_txt accessor that you can use to access and set the exclusion parser while iterating through the queue:

```ruby
mybot.visit_each |url|
  #d ownload a new robots.txt from somewhere
  mybot.robot_txt = Spider::ExclusionParser.new(txt)
end
``` 

If you don't pass an agent string, then the parser will take it's configuration from the default agent specified in the robots.txt.  If you want your bot to respond to directives for a given user agent, just pass the agent to either the queue when you create it, or the parser:

```ruby
# visit queue that will respond to any robots.txt
# with User-agent: mybot in them
mybot = Spider::VisitQueue(txt, 'mybot')

#same thing as a standalone parser
myparser = Spider::ExclusionParser.new(txt, 'mybot')
```

Note that user agent string passed in to your exclusion parser and the user agent string sent along with HTTP requests are not necessarily one and the same, although the user agent contained in robots.txt will usually be a subset of the HTTP user agent.

For example:

Googlebot/2.1 (+http://www.google.com/bot.html)

should respond to "googlebot" in robots.txt.  By convention, bots and spiders usually have the name 'bot' somewhere in their user agent strings. 

Finally, as a sanity check / to avoid DoS honeypots with malicious robots.txt files, the exclusion parser will process a maximum of one thousand non-whitespace lines before stopping. 

## Wait Time

Ideally a bot should wait for some period of time in between requests to avoid crashing websites (less likely) or being blacklisted (more likely).  A WaitTime class is provided that encapsulates this waiting logic, and logic to respond to rate limit codes and the "crawl-delay" directives found in some robots.txt files.  Times are in seconds.

You can create it standalone, or get it from an exclusion parser:

```ruby
# download a robots.txt with a crawl-delay 40

robots_txt = Spider::ExclusionParser.new(txt)
delay = robots_txt.wait_time
delay.value => 40

# receive a rate limit code, double wait time
delay.back_off

# actually do the waiting part
delay.wait

# in response to some rate limit codes you'll want
# to sleep for a while, then back off
delay.reduce_wait


# after one call to back_off and one call to reduce_wait
delay.value => 160
```

By default a WaitTime will specify an initial value of 2 seconds.  You can pass a value to new to specify the wait seconds, although values larger than the max allowable value will be set to the max allowable value (3 minutes / 180 seconds).

## Recording Requests

For convenience, an HTTP request recorder is provided, and is highly useful for helping write regression and integration tests.  It accepts a block of code that returns a string containing the response data.  The String class is monkey-patched to add http_status and http_headers accessors for ease of transporting other request data (yes, I know, monkey patching is evil).  Information assigned to these accessors will be saved as well by the recorder, but their use is not required.  The recorder class will manage the marshaling and unmarshaling of the request data behind the scenes, saving requests identified by their URL as a uniquely hashed file name with YAML-ized and Base64 encoded data in it.  This is similar to VCR, and you can certainly use that instead.  However, I personally ran into some troubles integrating it into some spiders I was writing, so I came up with this as a simple, lightweight alternative that works well with the rest of the Spiderkit.

The recorder will not play back request data unless enabled, and it will not save request data unless recording is turned on.  This is done with the **activate!** and **record!** methods, respectively.  You can stop recording with the **pause!** method and stop playback with the **deactivate!** method.

A simple spider for iterating pages and recording them might look like this:

```ruby
require 'spiderkit'
require 'open-uri'

mybot = Spider::VisitQueue.new
mybot.push_front('http://someurl.com')

Spider::VisitRecorder.config('/save/path')
Spider::VisitRecorder.activate!
Spider::VisitRecorder.record!

mybot.visit_each do |url|

  data = Spider::VisitRecorder.recall(url) do
    puts "fetch #{url}"
    open(url).read
  end
 
  # extract links from data and push onto the
  # spider queue
end
```

After the first time the pages are spidered and saved, any subsequent run would simply replay the recorded data.  You would find the saved request files in the working directory.  The path that requests are saved to can be altered using the **config** method:

```ruby
Spider::VisitRecorder.config('/some/test/path')
```
 
## Contributing

Bug reports, patches, and pull requests warmly welcomed at http://github.com/rdormer/spiderkit
