This script automate the ELK setup...



Elasstic config
✅ Elasticsearch security features have been automatically configured!
✅ Authentication is enabled and cluster connections are encrypted.

ℹ️  Password for the elastic user (reset with `bin/elasticsearch-reset-password -u elastic`):
  rvti=YpEE=5CPM454dGm

ℹ️  HTTP CA certificate SHA-256 fingerprint:
  64e61803f223c76e1ed1036861ab1b413968cdbda0256376a1cd119b43d8daba

ℹ️  Configure Kibana to use this cluster:
• Run Kibana and click the configuration link in the terminal when Kibana starts.
• Copy the following enrollment token and paste it into Kibana in your browser (valid for the next 30 minutes):
  eyJ2ZXIiOiI4LjE0LjAiLCJhZHIiOlsiMTAwLjExOS4yMS44Nzo5MjAwIl0sImZnciI6IjY0ZTYxODAzZjIyM2M3NmUxZWQxMDM2ODYxYWIxYjQxMzk2OGNkYmRhMDI1NjM3NmExY2QxMTliNDNkOGRhYmEiLCJrZXkiOiJSSGxRcTVVQmx2Q3hKUkd1dzdtdzpnUVlqOGo0UVFzRzJXcFVWcFJKVFFnIn0=

ℹ️  Configure other nodes to join this cluster:
• On this node:
  ⁃ Create an enrollment token with `bin/elasticsearch-create-enrollment-token -s node`.
  ⁃ Uncomment the transport.host setting at the end of config/elasticsearch.yml.
  ⁃ Restart Elasticsearch.
• On other nodes:
  ⁃ Start Elasticsearch with `bin/elasticsearch --enrollment-token <token>`, using the enrollment token that you generated.