require 'socket'
require 'thread'
require_relative 'common'

module FTP
	class ProcessPerConnection
		include Common

		def run

			Thread.abort_on_exception = true

			loop do
				@client = @control_socket.accept
				Thread.new do
					respond "220 OHAI"
					handler = CommondHandler.new(self)

					loop do
						request = @client.gets(CRLF)
						if request
							respond handler.handle(request)
						else
							@client.close
							break
						end
					end
				end
			end
		end
	end
end

server = FTP::ProcessPerConnection.new(4481)
server.run