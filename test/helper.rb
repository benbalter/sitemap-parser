# frozen_string_literal: true

require 'bundler/setup'
require 'tempfile'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sitemap-parser'
