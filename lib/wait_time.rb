# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

#==============================================
#Class to encapsulate the crawl delay being used.
#Clamps the value to a maximum amount and implements
#an exponential backoff function for responding to
#rate limit requests
#==============================================

module Spider

  class WaitTime
    
    MAX_WAIT = 180
    DEFAULT_WAIT = 2
    REDUCE_WAIT = 300

    def initialize(period=nil)
      unless period.nil?
        @wait = (period > MAX_WAIT ? MAX_WAIT : period)
      else
        @wait = DEFAULT_WAIT
      end
    end

    def back_off
      if @wait.zero?
        @wait = DEFAULT_WAIT 
      else
        waitval = @wait * 2 
        @wait = (waitval > MAX_WAIT ? MAX_WAIT : waitval)
      end
    end

    def wait
      sleep(@wait)
    end

    def reduce_wait
      sleep(REDUCE_WAIT)
      back_off
    end
 
    def value
      @wait
    end
  end
end
