# frozen_string_literal: true

require 'dotenv'
require 'simple-pg'
require_relative '../lib/logging'

if (dir = ENV['DIR'])
  Dotenv.load File.join(dir, '.env')
  LOG_TO = ENV['LOG_TO'].to_s

  # Convert the relative path into an absolute path
  LOG_TO = File.join(dir, LOG_TO) if !LOG_TO.empty? && !LOG_TO.start_with?('/')
else
  Dotenv.load '.env'
  LOG_TO = ENV['LOG_TO'].to_s
end

# Setup the logging
LOG_TO = ENV['LOG_TO'].to_s
DEBUG = ENV['DEBUG'].to_s == 'true'

WillDenglerServer.log = Logger.new(LOG_TO.empty? ? STDOUT : LOG_TO)
WillDenglerServer.log.level = DEBUG ? Logger::DEBUG : Logger::INFO

SimplePG.log = WillDenglerServer.log
