# frozen_string_literal: true

# The errors used by this project
module WillDenglerServer
  module Exceptions
    class WillDenglerServerException < StandardError
    end

    # Raise when a message cannot be created
    class FailedToCreateMessage < WillDenglerServerException
      def initialize
        super 'Failed to create message'
      end
    end


    # Raise this when someone tries to access an endpoint they don't have
    # permission to.
    class Unauthorized < WillDenglerServerException
    end

    # Raise this when the request body cannot be read.
    class FailedToReadRequest < WillDenglerServerException
    end

  end
end
