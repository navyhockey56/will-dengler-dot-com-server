# frozen_string_literal: true

require 'logger'

module WillDenglerServer
  def self.log=(logger)
    raise 'Invalid logger' unless [:info, :error, :debug].all? { |type| logger.respond_to? type }

    @log = logger
  end

  def self.log
    @log ||= Logger.new(STDOUT);
  end

  def self.log_error(e)
    self.log.error "An error occurred: #{e.class} - #{e.message}\n#{e.backtrace.join("\n\t")}"
  end
end
