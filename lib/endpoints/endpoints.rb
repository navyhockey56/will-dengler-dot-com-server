# frozen_string_literal: true

require 'base64'
require 'sinatra/base'
require 'rack/ssl'
require 'webrick/https'

require_relative '../exceptions'
require_relative '../logging'
require_relative '../handlers/message_handler'

# The parent class for all endpoints. Provides basic configuration and
# helper methods.
module WillDenglerServer
  class Endpoints < Sinatra::Base
    use Rack::SSL

    # Defines the ADMIN role
    ROLE_ADMIN = 'ADMIN'

    # Creates the 'self' role ~ The user returned through
    # basic auth must have the given ID.
    def ROLE_SELF(id)
      id.to_i
    end

    ####################################
    # Start CORS Configurations

    configure do
      enable :cross_origin
      use Rack::CommonLogger, WillDenglerServer.log
    end

    options "*" do
      response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
      # NOTE: You've temporarily added header "PURCHASE_PASSWORD". Remove this once you have billing working.
      response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization, PURCHASE_PASSWORD"
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Strict-Transport-Security"] = "max-age=31536000;"
      200
    end

    before do
       content_type :json
       headers({
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST', 'PUT', 'DELETE']
      })
    end

    # End CORS Configurations
    ####################################

    # Performs a basic auth check. Errors whenever: no authorization
    # header is found; a malformed header is supplied; no user can be found;
    # or the user's password is incorrect.
    #
    # If `roles` are supplied, then the authorizing user must contain a permission matching
    # one of the `roles` provided or an unathorized will be raised.
    # => `ROLE_SELF(id)` does not correspond to a permssion. Instead the authorizing user's ID is matched
    #     against the supplied `id`.
    #
    # @param [Array] *role - The roles that are allowed to access this endpoint.
    # @return [WillDenglerServer::ExpandedUserEntity] The authorized user.
    #
    # @raise [WillDenglerServer::Exceptions::Unauthorized] If the authorization is invalid or fails.
    def authorize!
      auth = fetch_header('HTTP_AUTHORIZATION')
      basic_auth_pattern = /^basic \S{3,}$/i

      # Consider removing the basic auth pattern since
      # it may not match all valid headers

      # Check that the auth exists and is properly formatted
      if auth.empty? || !auth.match(basic_auth_pattern)
        WillDenglerServer.log.debug "Malformed authorization header - unrecognized format - #{auth}"
        raise WillDenglerServer::Exceptions::Unauthorized
      end

      # Fetch the encoded authorization from the header
      encoded_auth = auth.split(' ').last
      # Decode the authorization
      decoded_auth = Base64.decode64(encoded_auth).split(':')

      # Make sure the encoded data is the proper format
      unless decoded_auth.count == 2
        WillDenglerServer.log.debug 'Malformed authorization header - data is not properly encoded'
        raise WillDenglerServer::Exceptions::Unauthorized
      end

      email = decoded_auth.first
      password = decoded_auth.last

      unless email == ENV['ADMIN_EMAIL'] && password == ENV['ADMIN_PASSWORD']
        raise WillDenglerServer::Exceptions::Unauthorized
      end

      true
    rescue WillDenglerServer::Exceptions::Unauthorized
      raise
    rescue StandardError => e
      WillDenglerServer.log_error e
      raise WillDenglerServer::Exceptions::Unauthorized, e
    end

    # Parses the request's body into a JSON
    def read_message
      message = JSON.parse(request.body.read, symbolize_names: true)
    rescue StandardError => e
      raise WillDenglerServer::Exceptions::FailedToReadRequest
    end

    # Creates a return message
    def return_message(message, status = 200)
      [status, JSON.pretty_generate({
        message: message,
        status: status
      })]
    end

    # Logs the given error and creates a return message
    def log_error_and_return(error, message: nil, status: 500)
      WillDenglerServer.log_error error

      return_message(message.to_s.empty? ? error.message : message, status)
    end

    # Retrieves a query parameter
    def fetch_param(name, to_i: false)
       param = params[name].to_s.downcase
       param.empty? ? nil : (to_i ? param.to_i : param.to_s)
    end

    # Retrieves a header
    def fetch_header(name)
      request.env[name].to_s
    end

    # Convience method for handling common errors and returning
    # an appropriate HTTP response/status.
    #
    # @param [StandardError] ex - The error to handle
    # @param [Array] errors (Optional) - Any additional errors that you want to
    #                                    be handled outside of the default set.
    def handle_error(ex, errors = [])
      # A list of error classes with which message/status
      # to respond with if the current error matches the class.
      #
      # Also allows for `:causes` which will perform a similar search
      # on the exception's cause to allow for more fine-grained error
      # handling.
      errors += [
        {
          class: WillDenglerServer::Exceptions::FailedToReadRequest,
          message: 'Failed to parse message',
          status: 400
        },
        {
          class: WillDenglerServer::Exceptions::Unauthorized,
          message: 'Unauthorized',
          status: 422
        },
        {
          class: SimplePG::Exceptions::FailedToCreateEntity,
          message: 'An error occured while creating an Entity',
          status: 500,
          causes: [
            {
              class: SimplePG::Exceptions::UniqueViolation,
              message: 'Uniqueness violation encountered',
              status: 409
            }
          ]
        },
        {
          class: KeyError,
          message: ex.message,
          status: 422
        }
      ]

      # Locate the matching error
      matching_error = errors.find { |error| ex.is_a? error[:class] }

      # Exit with a generic 500 if a match couldn't be found
      return return_message('An unexpected error occured', 500) unless matching_error

      # If there are causes, then check if any of them match the
      # errors cause. If so, use the cause hash instead of the parent
      if matching_error[:causes]
        matching_cause = matching_error[:causes].find { |error| ex.cause.is_a? error[:class] }
        matching_error = matching_cause if matching_cause
      end

      # Return the error with the appropraite message/status
      return_message(matching_error[:message], matching_error[:status])
    end

    def message_handler
      @@_message_handler ||= WillDenglerServer::MessageHandler.new
    end

  end
end
