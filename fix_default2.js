var fs = require('fs');
['feature-community','hsp-service'].forEach(function(dir) {
  var p = dir + '/src/main/ets/repository/FamilyGroupRepository.ets';
  var s = fs.readFileSync(p, 'utf8');
  var cnt = 0;
  var re = /'([^']*)DEFAULT ([^']*)'(\s*\))/g;
  s = s.replace(re, function(m, pf, sf, cl) {
    if (sf.indexOf("''") >= 0) {
      cnt++;
      return "'" + pf + "DEFAULT " + "''" + cl;
    }
    return m;
  });
  fs.writeFileSync(p, s);
  console.log(p + ': ' + cnt);
});