require 'em-websocket'
require 'json'

def parse_path(path)
  data = path.split("/")
  data.delete("")

  {
    :channel => data[0],
    :event => data[1]
  }
end

EventMachine.run do

  @channels = {}

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 1234) do |ws|
    puts "WebSocket server starting"

    ws.onopen do |handshake|
      puts "Welcome to Palladium"
      
      socket_data = parse_path handshake.path

      @channels[socket_data[:channel]] = EM::Channel.new

      sid = @channels[socket_data[:channel]].subscribe { |msg| ws.send msg }

      ws.onmessage do |msg|
        message = JSON.parse(msg) rescue {}
        puts "Receiving a message from #{socket_data[:channel]}:#{socket_data[:event]}"

        response = {
          :channel => socket_data[:channel],
          :event => socket_data[:event],
          :data => msg
        }

        @channels[socket_data[:channel]].push(response.to_json)
      end

      ws.onclose do
        puts "Au revoir!"
      end
    end

  end
end