Array.prototype.unique = function() {
  var a = [];
  var l = this.length;
  for(var i=0; i<l; i++) {
    for(var j=i+1; j<l; j++) { 
      if (this[i] === this[j]) j = ++i; 
    }
    a.push(this[i]);
  }
  return a;
};

function translate(raw) {
  // look for line variables
  var hits = raw.match(/<([1-9]*[0-9])>/g);
  if (hits) {
    var replaced = raw.replace(/</g, "Var").replace(/>/g, "");
    for( var i = 0; i < hits.length; i++)
    { hits[i] = hits[i].match("<([1-9]*[0-9])>")[1]; }
    hits = hits.unique();
    var to_ret = replaced;
    to_ret += " /. {";
    for (var i = 0; i < hits.length; i++) {
      to_ret += hits[i];
      to_ret += "->";
      to_ret += Prompt.results[hits[i-1]];
      if (i != hits.length - 1) {
        to_ret += ", ";
      }
    }
    to_ret += "}";
    return to_ret;
  }

  // first look for the at
  var at_index = raw.search(" at ")
  if (at_index >= 0) {
    var str = raw.substr(at_index + 3, raw.length - at_index - 3)
    return translate(raw.substr(0, at_index) + " /. " + "{" + str.replace(/=/g, "->") + "}");
  }

  // then look for ``
  var in_string = false;
  var buffer = "";
  var to_ret = "";
  for (var i = 0; i < raw.length; i++) {
    if (raw.charAt(i) == '`') {
      if (in_string) {
        in_string = false;
        to_ret +=  "WolframAlpha[\"" + buffer + "\", \"MathematicaResult\"]";
        buffer = "";
      } else {
        in_string = true;
      }
    } else {
      if (in_string) {
        buffer += raw.charAt(i);
      } else {
        to_ret += raw.charAt(i);
      }
    }
  }
  return to_ret;
}
  

