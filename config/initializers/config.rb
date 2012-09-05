root = File.dirname(__FILE__) + '/../..'
CONFIG = YAML.load_file(root + '/config/config.yml')

# SEE: http://grosser.it/2009/04/14/recursive-symbolize_keys/
def recursive_symbolize_keys!(hash)
  hash.symbolize_keys!
  hash.values.select{|v| v.is_a? Hash}.each{|h| recursive_symbolize_keys!(h)}
end

recursive_symbolize_keys!(CONFIG)
