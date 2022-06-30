require 'iiif/presentation'
require 'mimemagic'
require 'vips'

PRES_API_URL  = 'https://raw.githubusercontent.com/nyu-dss/serverless-iiif-rijks-test/main/presentation'
IMAGE_API_URL = 'https://twt4gwyokx4jxgo2tcptgtn4v40qajbb.lambda-url.us-east-1.on.aws/iiif/2'
target_dir    = "presentation"

FileUtils.mkdir_p target_dir

files = Dir.glob("#{NEW_SRC}/**/*").select { |f| File.file? f }
files.each do |f|
  image = Vips::Image.new_from_file f
  mime  = MimeMagic.by_magic(File.open(f)).to_s
  id    = File.basename(f).gsub(File.extname(f), '')
  seed  = {
    '@id'   => "#{PRES_API_URL}/#{id}/manifest.json",
    'label' => id
  }

  manifest            = IIIF::Presentation::Manifest.new seed

  canvas              = IIIF::Presentation::Canvas.new
  canvas['@id']       = "#{PRES_API_URL}/canvas/#{id}.json"
  canvas.label        = id
  canvas.width        = image.width
  canvas.height       = image.height
  canvas.thumbnail    = "#{IMAGE_API_URL}/#{id}/full/250,/0/default.jpg"
  canvas['full']      = "#{IMAGE_API_URL}/#{id}/full/full/0/default.jpg"

  annotation          = IIIF::Presentation::Annotation.new
  annotation['@id']   = "#{PRES_API_URL}/annotation/#{id}.json"

  resource            = IIIF::Presentation::Resource.new
  resource['@id']     = "#{IMAGE_API_URL}/#{id}/full/full/0/default.jpg"
  resource['@type']   = 'dcterms:Image'
  resource.format     = mime

  service             = {}
  service['@context'] = 'http://iiif.io/api/image/2/context.json',
  service['@id']      = "#{IMAGE_API_URL}/#{id}/info.json"

  resource['service'] = service
  annotation.resource << resource
  canvas.images       << annotation
  manifest.sequences  << canvas

  manifest_file = "#{target_dir}/#{id}/manifest.json"
  FileUtils.mkdir_p File.dirname(manifest_file)
  File.open(manifest_file, 'w') { |f| f.write manifest.to_json(pretty: true) }
end