require 'thread'

module ActivePublisher
  module Connection
    CONNECTION_MUTEX = ::Mutex.new
    NETWORK_RECOVERY_INTERVAL = 1.freeze

    def self.connected?
      connection.try(:connected?)
    end

    def self.connection
      CONNECTION_MUTEX.synchronize do
        return @connection if @connection
        @connection = create_connection
      end
    end

    def self.disconnect!
      CONNECTION_MUTEX.synchronize do
        if @connection && @connection.connected?
          @connection.close
        end

        @connection = nil
      end
    rescue Timeout::Error
      # No-op ... this happens sometimes on MRI disconnect
    end

    # Private API
    def self.create_connection
      if ::RUBY_PLATFORM == "java"
        connection = ::MarchHare.connect(connection_options)
      else
        connection = ::Bunny.new(connection_options)
        connection.start
        connection
      end
    end
    private_class_method :create_connection

    def self.connection_options
      {
        :automatically_recover         => true,
        :continuation_timeout          => ::ActivePublisher.configuration.timeout * 1_000.0, #convert sec to ms
        :heartbeat                     => ::ActivePublisher.configuration.heartbeat,
        :hosts                         => ::ActivePublisher.configuration.hosts,
        :network_recovery_interval     => NETWORK_RECOVERY_INTERVAL,
        :pass                          => ::ActivePublisher.configuration.password,
        :port                          => ::ActivePublisher.configuration.port,
        :recover_from_connection_close => true,
        :tls                           => ::ActivePublisher.configuration.tls,
        :tls_ca_certificates           => ::ActivePublisher.configuration.tls_ca_certificates,
        :tls_cert                      => ::ActivePublisher.configuration.tls_cert,
        :tls_key                       => ::ActivePublisher.configuration.tls_key,
        :user                          => ::ActivePublisher.configuration.username,
        :verify_peer                   => ::ActivePublisher.configuration.verify_peer,
        :vhost                         => ::ActivePublisher.configuration.virtual_host,
      }
    end
    private_class_method :connection_options
  end
end
