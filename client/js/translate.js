function translate(raw) {
  // first look for the at
  var at_index = raw.search(" at ")
  if (at_index >= 0) {
    return raw.substr(0, at_index) + " /. " + "{" + raw.substr(at_index + 3, raw.length - at_index - 3) + "}";
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
  

