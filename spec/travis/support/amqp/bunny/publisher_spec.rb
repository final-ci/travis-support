require 'spec_helper'

if RUBY_PLATFORM != 'java'

  describe Travis::Amqp::Publisher do
    let(:test_class) do
      Class.new do
        def publish(data, metadata)
          @data = data
          @metadata = metadata
        end

        attr_reader :data, :metadata
      end
    end

    describe 'Proper data handling' do
      let(:exchange) { test_class.new }
      let(:publisher) { Travis::Amqp::Publisher.new 'foo' }
      it 'passes data as json into an exchange' do
        publisher.stubs(:exchange).returns(exchange)
        publisher.publish({ foo: 'foo' }, { foo1: 'foo2'})
        expect(exchange.data).to eq (MultiJson.encode({foo: 'foo'}))
      end
    end

    describe 'Proper metadata handling' do
      let(:exchange) { test_class.new }
      let(:publisher) { Travis::Amqp::Publisher.new 'foo' }

      before do
        publisher.stubs(:exchange).returns(exchange)
      end

      it 'passes default routing_key into an exchange' do
        publisher.publish({ foo: 'foo' }, { foo1: 'foo2'})
        exchange.metadata.should have_key(:routing_key)
        expect(exchange.metadata[:routing_key]).to eq 'foo'
      end

      it 'when :routing_key overridden, the new routing_key is passed into an exchange' do
        publisher.publish({ foo: 'foo' }, { routing_key: 'foo2' })
        exchange.metadata.should have_key(:routing_key)
        expect(exchange.metadata[:routing_key]).to eq 'foo2'
      end

      it 'passes :message_id key into an exchange automatically' do
        publisher.publish({ foo: 'foo' }, { routing_key: 'foo2' })
        exchange.metadata.should have_key(:message_id)
      end

      it 'passes :type key into an exchange' do
        publisher.publish({ foo: 'foo' }, { type: 'foo2' })
        exchange.metadata.should have_key(:type)
        expect(exchange.metadata[:type]).to eq 'foo2'
      end

      describe 'when :properties key is specified' do
        it 'key is removed before passing into an exchange' do
          publisher.publish({ foo: 'foo' }, { properties: { a: 'b' } })
          exchange.metadata.should_not have_key(:properties )
        end

        it 'content of properties sub-hash is re-merged before passing into an exchange' do
          publisher.publish({ foo: 'foo' }, { properties: { a: 'b' } })
          exchange.metadata.should have_key(:a)
        end

        it 'properties sub-hash overrides exist keys before passing into exchange' do
          publisher.publish({ foo: 'foo' }, { type: 'a', properties: { type: 'b' } })
          exchange.metadata.should have_key(:type)
          expect(exchange.metadata[:type]).to eq 'b'
        end
      end
    end

#     let(:connection) { Travis::Amqp.connection }
#     let(:message)    { queue.pop(:nowait => false) }
#     let(:publisher)  { Travis::Amqp::Publisher.new('reporting') }
#     let!(:queue) do
#       queue = connection.queue('reporting', :durable => true, :exclusive => false)
#       exchange = connection.exchange('reporting.jobs.1', :durable => true, :type => :topic, :auto_delete => false)
#       queue.bind(exchange, :key => 'reporting')
#       queue
#     end
#
#     before do
#       Travis::Amqp.config = { :host => '127.0.0.1' }
#     end
#
#     it "encodes the data as json" do
#       publisher.publish({})
#       message.should_not == nil
#       message[:payload].should == "{}"
#     end
#
#     it "defaults to a direct type" do
#       publisher.type.should == "direct"
#     end
#
#     it "increments a counter when a message is published" do
#       expect {
#         publisher.publish({})
#       }.to change {
#         Metriks.meter('travis.amqp.messages.published.reporting').count
#       }
#     end
#
#     it "increments a counter when a message fails to be published" do
#       MultiJson.stubs(:encode).raises(StandardError)
#       expect {
#         publisher.publish({})
#       }.to change {
#         Metriks.meter('travis.amqp.messages.published.failed.reporting').count
#       }
#     end
  end
end
