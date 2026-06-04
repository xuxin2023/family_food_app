var fs=require('fs'),path=require('path'),fixed=0;
function walk(d){
  fs.readdirSync(d).forEach(function(f){
    var fp=path.join(d,f);
    var skip=['node_modules','oh_modules','build','merged','.git','.hvigor','AppScope','scripts','rules','docs','cloud-functions','cloud'];
    if(skip.includes(f))return;
    try{var s=fs.statSync(fp);
      if(s.isDirectory()&&!f.startsWith('.'))walk(fp);
      else if(f.endsWith('.ets')){
        var b=fs.readFileSync(fp);
        var m=false;
        var r=[];
        for(var i=0;i<b.length;i++){
          if(i+2<b.length&&b[i]===0xef&&b[i+1]===0xbf&&b[i+2]===0xbd){
            r.push(0xC3,0x97);i+=2;m=true;
          }else{r.push(b[i])}
        }
        if(m){fs.writeFileSync(fp,Buffer.from(r));fixed++;console.log('Fixed: '+fp)}
      }
    }catch(e){}
  });
}
walk('.');
console.log('Total fixed: '+fixed);