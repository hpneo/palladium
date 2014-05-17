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

EM.run do

  @channels = {}

  EM::WebSocket.start(:host => "0.0.0.0", :port => "1234") do |ws|
    puts "WebSocket server starting"

    socket_data = nil

    ws.onopen do
      socket_data = parse_path(ws.instance_variable_get('@handler'.to_sym).request["path"])
      @channels[socket_data[:channel]] = EM::Channel.new
      puts "Welcome to Palladium. Listening: #{socket_data[:channel]}"

      @channels[socket_data[:channel]].subscribe do |message|
        ws.send(message)
      end
    end

    ws.onmessage do |message|
      puts message
      message = JSON.parse(message) rescue {}
      puts "Receiving a message from #{socket_data[:channel]}:#{socket_data[:event]}:"

      response = {
        :channel => socket_data[:channel],
        :event => socket_data[:event],
        :data => message
      }

      @channels[socket_data[:channel]].push(response.to_json)
    end

    ws.onclose do
      puts "Au revoir!"
    end
  end
end