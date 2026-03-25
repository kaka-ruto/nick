require "digest"
require "stringio"
require "zip"

def seed_default_account!
  Account.find_or_create_by!(name: "Chapterwan")
end

def seed_system_user!
  User.find_or_create_by!(email_address: "owner@chapterwan.local") do |user|
    user.name = "Chapterwan Owner"
    user.username = "chapterwan-owner"
    user.role = "administrator"
    user.password = SecureRandom.hex(24)
  end
end

def seed_api_key_for!(user)
  ApiKey.active.find_by(user: user, name: "seed-bootstrap", scopes: ApiKey::SCOPES) || ApiKey.issue!(user: user, name: "seed-bootstrap", scopes: ApiKey::SCOPES).first
end

def zip_directory(path)
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

def seed_chapterwan_manual!(user:, api_key:)
  source_dir = Rails.root.join("books/chapterwan-manual")
  return unless source_dir.exist?

  existing = Book.find_by(book_uid: "chapterwan-manual")
  return if existing&.published_revision.present?

  source_bundle = zip_directory(source_dir)
  source_sha256 = Digest::SHA256.hexdigest(source_bundle)
  upload = Upload.create!(
    api_key: api_key,
    user: user,
    book: existing,
    book_uid: "chapterwan-manual",
    base_revision_id: existing&.import_revision,
    source_sha256: source_sha256,
    parser_version: Upload::PARSER_VERSION,
    status: :received
  )

  upload.source_bundle.attach(
    io: StringIO.new(source_bundle),
    filename: "chapterwan-manual.zip",
    content_type: "application/zip"
  )

  upload.update!(status: :validating)
  parser_result = Uploads::MarkdownParser.call(content: source_bundle, filename: "chapterwan-manual.zip")
  upload.update!(
    status: :parsed,
    warnings: [],
    plan: {
      book: parser_result.book_attributes,
      units: parser_result.units
    }
  )

  upload.update!(status: :applying)
  Uploads::Apply.call(upload: upload, publish: true)

  book = upload.reload.book
  book.update!(everyone_access: true, pricing_type: :free, published: true)
  book.update_access(editors: [ user.id ], readers: [ user.id ])
end

seed_default_account!
seed_user = seed_system_user!
seed_key = seed_api_key_for!(seed_user)
seed_chapterwan_manual!(user: seed_user, api_key: seed_key)
