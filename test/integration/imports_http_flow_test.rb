require "test_helper"
require "json"
require "net/http"
require "rackup/handler/webrick"
require "securerandom"
require "zip"

class ImportsHttpFlowTest < ActiveSupport::TestCase
  HOST = "127.0.0.1".freeze
  PORT = 9887

  test "zip bundle is imported and applied through local HTTP API" do
    _, token = ApiKey.issue!(user: users(:david), name: "imports-http", scopes: [ "books:write", "books:publish" ])

    with_local_server do
      VCR.use_cassette("imports/http_zip_apply_success") do
        zip_data = build_zip_from_directory(Rails.root.join("books/the-chapterwan-manual"))

        create_response = post_import(zip_data:, token:, idempotency_key: "http-import-create")
        assert_equal "201", create_response.code

        created_body = JSON.parse(create_response.body)
        import_payload = created_body.fetch("import")
        assert_equal "applied", import_payload.fetch("status")
        assert_equal 4, import_payload.dig("result", "units_count")
        assert_equal "The Chapterwan Manual", import_payload.dig("plan", "book", "title")

        show_response = get_import(id: import_payload.fetch("id"), token:, idempotency_key: "http-import-show")
        assert_equal "200", show_response.code

        shown_body = JSON.parse(show_response.body)
        shown_import = shown_body.fetch("import")
        assert_equal "applied", shown_import.fetch("status")
        assert_equal 4, shown_import.dig("plan", "units")&.size
      end
    end
  end

  private
    def with_local_server
      server = nil

      thread = Thread.new do
        Rackup::Handler::WEBrick.run(
          Rails.application,
          Host: HOST,
          Port: PORT,
          AccessLog: [],
          Logger: WEBrick::Log.new($stderr, WEBrick::Log::FATAL)
        ) do |instance|
          server = instance
        end
      end

      Timeout.timeout(10) do
        sleep(0.05) while server.nil?
      end

      yield
    ensure
      server&.shutdown
      thread&.join
    end

    def post_import(zip_data:, token:, idempotency_key:)
      uri = URI("http://#{HOST}:#{PORT}/api/imports")
      request = Net::HTTP::Post.new(uri)

      body, boundary = multipart_body(zip_data:)
      request["Authorization"] = "Bearer #{token}"
      request["Idempotency-Key"] = idempotency_key
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = body

      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end

    def get_import(id:, token:, idempotency_key:)
      uri = URI("http://#{HOST}:#{PORT}/api/imports/#{id}")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Idempotency-Key"] = idempotency_key

      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end

    def multipart_body(zip_data:)
      boundary = "----chapterwan-#{SecureRandom.hex(10)}"
      body = +""
      body << "--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"apply\"\r\n\r\n"
      body << "true\r\n"
      body << "--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"source_file\"; filename=\"the-chapterwan-manual.zip\"\r\n"
      body << "Content-Type: application/zip\r\n\r\n"
      body << zip_data
      body << "\r\n--#{boundary}--\r\n"
      [ body, boundary ]
    end

    def build_zip_from_directory(path)
      io = StringIO.new

      Zip::OutputStream.write_buffer(io) do |zip|
        Dir.glob(path.join("**/*")).sort.each do |file|
          next if File.directory?(file)

          relative = Pathname(file).relative_path_from(path).to_s
          zip.put_next_entry(relative)
          zip.write(File.binread(file))
        end
      end

      io.string
    end
end
