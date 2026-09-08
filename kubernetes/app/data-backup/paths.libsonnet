local paths = import 'paths.json';

local values(object, field) =
  if std.objectHas(object, field) then object[field] else [];

std.join('\n', [
  path.path
  + '|' + std.join(',', values(path, 'excludes'))
  for path in paths
]) + '\n'
