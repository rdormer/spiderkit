# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

#==============================================
# This is the class that parses robots.txt and implements the exclusion
# checking logic therein.  Works by breaking the file up into a hash of 
# arrays of directives for each specified user agent, and then parsing the
# directives into internal arrays and iterating through the list to find a
# match.  Urls are matched case sensitive, everything else is case insensitive.
# The root url is treated as a special case by using a token for it.
#==============================================
require 'cgi'

module Spider

  class ExclusionParser 
   
    attr_accessor :wait_time

    DISALLOW = "disallow"
    DELAY = "crawl-delay"
    ALLOW = "allow"
  
    MAX_DIRECTIVES = 1000
    NULL_MATCH = "*!*"
  
    def initialize(text, agent=nil, status=200)
      @skip_list = []
      @agent_key = agent
  
      return if text.nil? || text.length.zero?
  
      if [401, 403].include? status
        @skip_list << [NULL_MATCH, true]
        return
      end
  
      begin
        config = parse_text(text)
        grab_list(config)
      rescue
      end
    end
  
    # Check to see if the given url is matched by any rule
    # in the file, and return it's associated status
  
    def excluded?(url)
      url = safe_unescape(url)
      @skip_list.each do |entry|
        return entry.last if url.include? entry.first
        return entry.last if entry.first == NULL_MATCH
      end
  
      false
    end

    def allowed?(url)
      !excluded?(url)
    end

    private
  
    # Method to process the list of directives for a given user agent.
    # Picks the one that applies to us, and then processes it's directives
    # into the skip list by splitting the strings and taking the appropriate
    # action. Stops after a set number of directives to avoid malformed files
    # or denial of service attacks
  
    def grab_list(config)
      section = (config.include?(@agent_key) ? 
        config[@agent_key] : config['*'])
  
      if(section.length > MAX_DIRECTIVES)
        section.slice!(MAX_DIRECTIVES, section.length)
      end
  
      section.each do |pair|
        key, value = pair.split(':')
  
        next if key.nil? || value.nil? || 
          key.empty? || value.empty?
        
        key.downcase!
        key.lstrip!
        key.rstrip!
  
        value.lstrip!
        value.rstrip!
  
        disallow(value) if key == DISALLOW
        delay(value) if key == DELAY
        allow(value) if key == ALLOW 
      end
    end
  
    # Top level file parsing method - makes sure carriage returns work,
    # strips out any BOM, then loops through each line and opens up a new
    # array of directives in the hash if a user-agent directive is found.
  
    def parse_text(text)
      current_key = ""
      config = {}
  
      text.gsub!("\r", "\n")
      text = text.force_encoding("UTF-8")
      text.gsub!("\xEF\xBB\xBF".force_encoding("UTF-8"), '')

      text.each_line do |line|
        line.lstrip!
        line.rstrip!
        line.gsub! /#.*/, ''
  
        if line.length.nonzero? && line =~ /[^\s]/
  
          if line =~ /User-agent:\s+(.+)/i
            previous_key = current_key
            current_key = $1.downcase
            config[current_key] = [] unless config[current_key]

            # If we've seen a new user-agent directive and the previous
            # one is empty then we have a cascading user-agent string.
            # copy the new user agent array ref so both user agents are identical.

	    if(config.has_key?(previous_key) && config[previous_key].size.zero?)
              config[previous_key] = config[current_key]
            end

          else
            config[current_key] << line
          end
        end
      end
  
      config
    end 
  
    def disallow(value)
      token = (value == "/" ? NULL_MATCH : value.chomp('*'))
      @skip_list << [safe_unescape(token), true]
    end
  
    def allow(value)
      token = (value == "/" ? NULL_MATCH : value.chomp('*'))
      @skip_list << [safe_unescape(token), false]
    end
  
    def delay(value)
      @wait_time = WaitTime.new(value.to_i)
    end
  
    def safe_unescape(target)
      t = target.gsub /%2f/, '^^^'
      t = CGI.unescape(t)
      t.gsub /\^\^\^/, '%2f'
    end
  end
end
