# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

$LOAD_PATH << File.dirname(__FILE__)
require 'wait_time'
require 'exclusion'
require 'recorder'
require 'version'
require 'queue'

class String
  attr_accessor :http_status
  attr_accessor :http_headers
end
