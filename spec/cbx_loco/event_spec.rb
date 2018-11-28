require "spec_helper"

describe CbxLoco::Event do
  let(:event_action) { double }
  let(:event_instance) { CbxLoco::Event.new }

  before do
    allow(event_action).to receive(:call)
  end

  describe "#on" do
    it "should add a task" do
      expect(event_instance.tasks).to be_empty
      event_instance.on(:some_event) { event_action.call }
      expect(event_instance.tasks).to_not be_empty
    end
  end

  describe "#emit" do
    it "should call the event" do
      event_instance.on(:some_event) { event_action.call }
      event_instance.emit(:some_event)
      expect(event_action).to have_received(:call)
    end
  end
end
