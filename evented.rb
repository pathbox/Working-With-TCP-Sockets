require 'socket'
require_relative 'common'

module FTP
	class Evented
		CHUNK_SIZE = 1024 * 16
		include Common

		class Connection
			include Common

			attr_reader :client
			def initialize(io)
				@client = io
				@request, @response = "", ""
				@handler = CommondHandler.new(self)

				@response = "220 OHAI" + CRLF
				on_writable
			end

			def on_data(data)
				@request << data

				if @request.end_with(CRLF)
					@response = @handler.handle(@request) + CRLF
					@request = ""
				end
			end

			def on_writable
				bytes = client.write_nonblock(@response)
				@response.slice!(0, bytes)
			end

			def monitor_for_reading?
				true
			end

			def monitor_for_writing?
				!(@response.empty?)
			end

			def run
				@handles= {}

				loop do
					to_read = @handles.values.select(&:monitor_for_reading?).map(&:client)
					to_write = @handles.values.select(&:monitor_for_writing?).map(&:client)

					readables, writables = IO.select(to_read + [@control_socket], to_write)
					readables.each do |socket|
						if socket == @control_socket
							connection = Connection.new(io)
							@handles[io.fileno] = connection
						else
							connection = @handles[socket.fileno]
							begin
								data = socket.read_nonblock(CHUNK_SIZE)
								connection.on_data(data)
							rescue Errno::EAGAIN
							rescue EOFError
								@handles.delete(socket.fileno)
							end
						end
					end
					writables.each do |socket|
						connection = @handles[socket.fileno]
						connection.on_writable
					end
				end
			end
		end
	end
end

server = FTP::Evented.new(4481)
server.run