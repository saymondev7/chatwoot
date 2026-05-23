json.payload do
  json.array! @classifications do |classification|
    json.id classification.id
    json.name classification.name
    json.position classification.position
    json.classification_type classification.classification_type
  end
end
