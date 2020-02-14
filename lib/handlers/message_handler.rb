# frozen_string_literal: true

require 'simple-pg'

module WillDenglerServer
  class MessageHandler < SimplePG::TableHandler

    TABLE ||= SimplePG::Table.new('messages', [
      SimplePG::Column.new(
        name: 'email',
        type: SimplePG::Column::Types.VARCHAR(100),
        validators: SimplePG::Column::Validators.validate_email!
      ),
      SimplePG::Column.new(
        name: 'message',
        type: SimplePG::Column::Types.VARCHAR(5000),
        modifiers: [
          SimplePG::Column::Modifiers::NOT_NULL
        ]
      )
    ])

    def initialize
      super TABLE

      @default_order_by = 'id'
    end

  end
end
