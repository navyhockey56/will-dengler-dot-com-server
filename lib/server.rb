# frozen_string_literal: true
require 'sinatra'

require_relative 'logging'
require_relative 'endpoints/message_endpoints'

#########################
# Phone
WillDenglerServer.log.info 'Spinning up endpoints/message_endpoints'
use WillDenglerServer::MessageEndpoints

