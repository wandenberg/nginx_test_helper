require 'spec_helper'
require 'nginx_test_helper/rspec_utils'

describe "rspec_utils" do

  it "should include NginxTestHelper module on RSpec tests" do
    expect(self.class.included_modules).to include(NginxTestHelper)
  end

  context "when defining the 'be_in_the_interval' matcher" do
    context "and checking if the number is in the interval" do
      it "should be true when the actual value is equal to lower bound" do
        expect { expect(10).to be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should be true when the actual value is equal to upper bound" do
        expect { expect(12).to be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should be true when the actual value is between lower and upper bounds" do
        expect { expect(11).to be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should be false when the actual value is smaller than lower bound" do
        expect { expect(9).to be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 9 would be in the interval from 10 to 12")
      end

      it "should be false when the actual value is greater than upper bound" do
        expect { expect(13).to be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 13 would be in the interval from 10 to 12")
      end

      it "should accept float numbers" do
        expect { expect(10.4).to be_in_the_interval(10.3,12.5) }.to_not raise_error
        expect { expect(12.4).to be_in_the_interval(10.3,12.5) }.to_not raise_error
      end
    end

    context "and checking if the number is out the interval" do
      it "should be false when the actual value is equal to lower bound" do
        expect { expect(10).not_to be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 10 would not be in the interval from 10 to 12")
      end

      it "should be false when the actual value is equal to upper bound" do
        expect { expect(12).not_to be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 12 would not be in the interval from 10 to 12")
      end

      it "should be false when the actual value is between lower and upper bounds" do
        expect { expect(11).not_to be_in_the_interval(10,12) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 11 would not be in the interval from 10 to 12")
      end

      it "should be true when the actual value is smaller than lower bound" do
        expect { expect(9).not_to be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should be true when the actual value is greater than upper bound" do
        expect { expect(13).not_to be_in_the_interval(10,12) }.to_not raise_error
      end

      it "should accept float numbers" do
        expect { expect(10.2).not_to be_in_the_interval(10.3,12.5) }.to_not raise_error
        expect { expect(12.6).not_to be_in_the_interval(10.3,12.5) }.to_not raise_error
      end
    end

    it "should has a friendly description" do
      expect(be_in_the_interval(10.3,12.5).description).to eql("be in the interval from 10.3 to 12.5")
    end
  end

  context "when defining the 'match_the_pattern' matcher" do
    context "and checking if the text match the pattern" do
      it "should be true when the actual value match the expression" do
        expect { expect("some text").to match_the_pattern(/EX/i) }.to_not raise_error
      end

      it "should be false when the actual value does not match the expression" do
        expect { expect("some text").to match_the_pattern(/EX/) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 'some text' would match the pattern '/EX/'")
      end
    end

    context "and checking if the text not match the pattern" do
      it "should be true when the actual value match the expression" do
        expect { expect("some text").not_to match_the_pattern(/EX/i) }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "expected that 'some text' would not match the pattern '/EX/i'")
      end

      it "should be false when the actual value does not match the expression" do
        expect { expect("some text").not_to match_the_pattern(/EX/) }.to_not raise_error
      end
    end

    it "should has a friendly description" do
      expect(match_the_pattern(/EX/i).description).to eql("match the pattern '/EX/i'")
    end
  end
end
