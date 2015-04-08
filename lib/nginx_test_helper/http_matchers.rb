module NginxTestHelper
  module HttpMatchers
    class BeHttpStatus
      def initialize(expected)
        @expected = expected
        @should_has_content = nil
      end

      def matches?(target)
        @target = target
        ret = @target.response_header.status.eql?(@expected)
        ret = @should_has_content ? has_content? : !has_content? unless (@should_has_content.nil? || !ret)
        ret = @target.response_header.content_length == @length unless (@length.nil? || !ret)
        ret = @target.response == @body unless (@body.nil? || !ret)
        ret
      end
      alias == matches?

      def without_body
        @should_has_content = false
        self
      end

      def with_body(body=nil)
        @body = body
        @should_has_content = true
        self
      end

      def with_body_length(length)
        @length = length
        self
      end

      def failure_message
        "expected that the '#{request.method}' to '#{request.uri}' to #{description}"
      end
      alias :failure_message_for_should :failure_message

      def failure_message_when_negated
        "expected that the '#{request.method}' to '#{request.uri}' not to #{description}"
      end
      alias :failure_message_for_should_not :failure_message_when_negated

      def description
        about_content = ""
        returned_values = " but returned with status '#{@target.response_header.status}'"
        if @body.nil? && @length.nil? && @should_has_content.nil?
          returned_values += " and content_length equals to #{@target.response_header.content_length.to_i}"
        elsif @body.nil? && @length.nil?
          about_content += " and #{@should_has_content ? "with body" : "without body"}"
          returned_values += " and #{@should_has_content ? "without body" : "with body"}"
        elsif @body.nil?
          about_content += " and content length #{@length}"
          returned_values += " and #{@target.response_header.content_length} of length"
        else
          about_content += " and body '#{@target.response}'"
          returned_values += " and #{@body} as content"
        end
        "be returned with status '#{@expected}'#{about_content}#{returned_values}"
      end

      private
      def has_content?
        @target.response_header.content_length.to_i > 0
      end

      def request
        @target.respond_to?(:req) ? @target.req : @target
      end
    end

    def be_http_status(expected)
      BeHttpStatus.new(expected)
    end
  end
end
