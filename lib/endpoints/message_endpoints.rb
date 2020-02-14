# frozen_string_literal: true

require_relative '../exceptions'
require_relative 'endpoints'

# This class is responsible for defining the endpoints associated with phones.
#
# Endpoints:
# => POST /phone
# => POST /phone/purchase
# => GET  /phones
# => GET  /phones/available
#
module WillDenglerServer
  class MessageEndpoints < Endpoints

    #############################################
    # POST /message
    # Creates a message from a user on the website
    #
    # Roles:
    # => SELF
    #
    # Body:
    # => JSON
    #
    # JSON Params:
    # => email
    #    The email of the person creating a message
    # => message
    #    The message content
    #
    post '/message' do
      message = read_message

      email = message.fetch(:email, nil)
      email = nil if email.to_s.empty?

      message_handler.create_entity(
        email:     email,
        message:   message.fetch(:message),
      ).to_json

    rescue StandardError => e
      WillDenglerServer.log_error e
      handle_error(e)
    end

    #############################################
    # GET /messages
    # Performs a query on the messages in the system
    #
    # Query Params:
    # => (Optional) {ADMIN, SELF} phoneId
    #     Retrieves the phone with the given ID.
    # => (Optional) {ADMIN, SELF} userId
    #     Retrieves the phones for the user with the given ID.
    # => (NO PARAMS) {ADMIN}
    #     Retrieves every phone in the system.
    #
    get '/messages' do
      authorize!

      message_handler.query.to_json
    rescue StandardError => e
      WillDenglerServer.log_error e
      handle_error(e)
    end

  end
end