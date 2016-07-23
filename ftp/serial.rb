require 'socket'
require_relative 'common'

module FTP
	class Serial
		include Common

		def run
			loop do
				@client = @control_socket.accept
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

server = FTP::Serial.new(4481)
server.run

# ftp -a -v 127.0.0.1 4481