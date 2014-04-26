require 'spec_helper'
require 'nginx_test_helper/rspec_utils'

describe "rspec_utils" do

  it "should include NginxTestHelper module on RSpec tests" do
    self.class.included_modules.should include(NginxTestHelper)
  end

  context "when defining the 'be_in_the_interval' matcher" do
    context "and checking if the number is in the interval" do
      it "should be true when the actual value is equal to lower bound" do
        expect { 10.should be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should be true when the actual value is equal to upper bound" do
        expect { 12.should be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should be true when the actual value is between lower and upper bounds" do
        expect { 11.should be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should be false when the actual value is smaller than lower bound" do
        expect { 9.should be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 9 would be in the interval from 10 to 12")
      end

      it "should be false when the actual value is greater than upper bound" do
        expect { 13.should be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 13 would be in the interval from 10 to 12")
      end

      it "should accept float numbers" do
        expect { 10.4.should be_in_the_interval(10.3,12.5) }.to_not raise_error
        expect { 12.4.should be_in_the_interval(10.3,12.5) }.to_not raise_error
      end
    end

    context "and checking if the number is out the interval" do
      it "should be false when the actual value is equal to lower bound" do
        expect { 10.should_not be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 10 would not be in the interval from 10 to 12")
      end

      it "should be false when the actual value is equal to upper bound" do
        expect { 12.should_not be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 12 would not be in the interval from 10 to 12")
      end

      it "should be false when the actual value is between lower and upper bounds" do
        expect { 11.should_not be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 11 would not be in the interval from 10 to 12")
      end

      it "should be true when the actual value is smaller than lower bound" do
        expect { 9.should_not be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should be true when the actual value is greater than upper bound" do
        expect { 13.should_not be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should accept float numbers" do
        expect { 10.2.should_not be_in_the_interval(10.3,12.5) }.to_not raise_error
        expect { 12.6.should_not be_in_the_interval(10.3,12.5) }.to_not raise_error
      end
    end

    it "should has a friendly description" do
      be_in_the_interval(10.3,12.5).description.should eql("be in the interval from 10.3 to 12.5")
    end
  end

  context "when defining the 'match_the_pattern' matcher" do
    context "and checking if the text match the pattern" do
      it "should be true when the actual value match the expression" do
        expect { "some text".should match_the_pattern(/EX/i) }.to_not raise_error
      end

      it "should be false when the actual value does not match the expression" do
        expect { "some text".should match_the_pattern(/EX/) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 'some text' would match the pattern '/EX/'")
      end
    end

    context "and checking if the text not match the pattern" do
      it "should be true when the actual value match the expression" do
        expect { "some text".should_not match_the_pattern(/EX/i) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 'some text' would not match the pattern '/EX/i'")
      end

      it "should be false when the actual value does not match the expression" do
        expect { "some text".should_not match_the_pattern(/EX/) }.to_not raise_error
      end
    end

    it "should has a friendly description" do
      match_the_pattern(/EX/i).description.should eql("match the pattern '/EX/i'")
    end
  end
end
