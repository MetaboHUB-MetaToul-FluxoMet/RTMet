influx export all \
  -f bioreactor_template.yml \
  --filter=resourceKind=Variable \
  --filter=resourceKind=Dashboard