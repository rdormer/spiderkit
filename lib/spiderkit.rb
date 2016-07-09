# Author::    Robert Dormer (mailto:rdormer@gmail.com)
# Copyright:: Copyright (c) 2016 Robert Dormer
# License::   MIT

$: << File.dirname(__FILE__)
require 'wait_time'
require 'exclusion'
require 'urltree'
require 'version'
require 'queue'

class String
  attr_accessor :http_status
end
