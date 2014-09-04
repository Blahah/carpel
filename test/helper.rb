require 'simplecov'
require 'coveralls'
require 'rubystats'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'minitest/autorun'
begin; require 'turn/autorun'; rescue LoadError; end
require 'shoulda/context'
require 'carpel'

Turn.config.format = :pretty
Turn.config.trace = 5
