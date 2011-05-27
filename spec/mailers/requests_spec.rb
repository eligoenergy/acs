require "spec_helper"

describe Requests do
  describe "request_receipt" do
    let(:mail) { Requests.request_receipt }

    it "renders the headers" do
      mail.subject.should eq("Request receipt")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

  describe "notify_manager_of_pending_request" do
    let(:mail) { Requests.notify_manager_of_pending_request }

    it "renders the headers" do
      mail.subject.should eq("Notify manager of pending request")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

  describe "notify_help_desk" do
    let(:mail) { Requests.notify_help_desk }

    it "renders the headers" do
      mail.subject.should eq("Notify help desk")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
