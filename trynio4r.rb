require 'nio4r'

server = TCPServer.new("127.0.0.1", 4481)

selector = NIO::Selector.new

3.times do
	client = server.accept
	_monitor = selector.register(client, :r)
end

ready = selector.select