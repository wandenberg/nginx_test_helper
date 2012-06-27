if defined?(RSpec)
  RSpec.configure do |config|
    config.include NginxTestHelper
  end

  RSpec::Matchers.define :be_in_the_interval do |min, max|
    match do |actual|
      (actual >= min) && (actual <= max)
    end

    failure_message_for_should do |actual|
      "expected that #{actual} would be in the interval from #{min} to #{max}"
    end

    failure_message_for_should_not do |actual|
      "expected that #{actual} would not be in the interval from #{min} to #{max}"
    end

    description do
      "be in the interval from #{min} to #{max}"
    end
  end

  RSpec::Matchers.define :match_the_pattern do |pattern|
    match do |actual|
      actual.match(pattern)
    end

    failure_message_for_should do |actual|
      "expected that '#{actual}' would match the pattern '#{pattern.inspect}'"
    end

    failure_message_for_should_not do |actual|
      "expected that '#{actual}' would not match the pattern '#{pattern.inspect}'"
    end

    description do
      "match the pattern '#{pattern.inspect}'"
    end
  end
end
