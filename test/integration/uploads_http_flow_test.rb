require "test_helper"
require "json"
require "net/http"
require "rackup/handler/webrick"
require "securerandom"
require "zip"

class UploadsHttpFlowTest < ActiveSupport::TestCase
  HOST = "127.0.0.1".freeze
  PORT = 9887

  test "zip bundle is uploaded and accepted through local HTTP API" do
    _, token = ApiKey.issue!(user: users(:david), name: "uploads-http", scopes: [ "books:write", "books:publish" ])

    with_local_server do
      VCR.use_cassette("uploads/http_zip_success") do
        zip_data = build_zip_from_directory(Rails.root.join("books/chapterwan-manual"))

        create_response = post_upload(zip_data:, token:, idempotency_key: "http-upload-create")
        assert_equal "201", create_response.code

        created_body = JSON.parse(create_response.body)
        upload_payload = created_body.fetch("upload")
        assert_equal "accepted", upload_payload.fetch("status")
        assert_equal 10, upload_payload.dig("result", "units_count")
        assert_equal "Chapterwan Manual", upload_payload.dig("plan", "book", "title")

        show_response = get_upload(id: upload_payload.fetch("id"), token:, idempotency_key: "http-upload-show")
        assert_equal "200", show_response.code

        shown_body = JSON.parse(show_response.body)
        shown_upload = shown_body.fetch("upload")
        assert_equal "accepted", shown_upload.fetch("status")
        assert_equal 10, shown_upload.dig("plan", "units")&.size

        book_id = shown_upload.fetch("book_id")
        revisions_response = get_revisions(book_id:, token:, idempotency_key: "http-upload-revisions")
        assert_equal "200", revisions_response.code
        revisions_payload = JSON.parse(revisions_response.body)
        assert_equal 1, revisions_payload.fetch("revisions").size

        revision_id = revisions_payload.fetch("revisions").first.fetch("id")
        source_response = get_revision_source(book_id:, revision_id:, token:, idempotency_key: "http-upload-source")
        assert_equal "200", source_response.code
        source_payload = JSON.parse(source_response.body)
        assert_match "chapterwan-manual.zip", source_payload.dig("source", "filename")
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

    def post_upload(zip_data:, token:, idempotency_key:)
      uri = URI("http://#{HOST}:#{PORT}/api/uploads")
      request = Net::HTTP::Post.new(uri)

      body, boundary = multipart_body(zip_data:)
      request["Authorization"] = "Bearer #{token}"
      request["Idempotency-Key"] = idempotency_key
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = body

      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end

    def get_upload(id:, token:, idempotency_key:)
      uri = URI("http://#{HOST}:#{PORT}/api/uploads/#{id}")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Idempotency-Key"] = idempotency_key

      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end

    def multipart_body(zip_data:)
      boundary = "----chapterwan-#{SecureRandom.hex(10)}"
      body = +""
      body << "--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"publish\"\r\n\r\n"
      body << "true\r\n"
      body << "--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"source_bundle\"; filename=\"chapterwan-manual.zip\"\r\n"
      body << "Content-Type: application/zip\r\n\r\n"
      body << zip_data
      body << "\r\n--#{boundary}--\r\n"
      [ body, boundary ]
    end

    def get_revisions(book_id:, token:, idempotency_key:)
      uri = URI("http://#{HOST}:#{PORT}/api/books/#{book_id}/revisions")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Idempotency-Key"] = idempotency_key
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end

    def get_revision_source(book_id:, revision_id:, token:, idempotency_key:)
      uri = URI("http://#{HOST}:#{PORT}/api/books/#{book_id}/revisions/#{revision_id}/source")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Idempotency-Key"] = idempotency_key
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
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
