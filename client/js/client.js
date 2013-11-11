// Generated by CoffeeScript 1.6.3
var Controller, Prompt;

Controller = {
  url: 'http://127.0.0.1:8000/',
  get: function(msg, callback, err_callback) {
    return $.post(Controller.url, {
      data: translate(msg)
    }, callback).error(err_callback);
  }
};

Prompt = {
  count: 1,
  active: null,
  history: [],
  results: [],
  history_pos: 0,
  toggles: [true, false, false],
  dots: null,
  make: function(prefix, content) {
    var block, c, p;
    p = $('<div class="prompt-p"/>').text(prefix);
    c = $('<input type="text" class="prompt-c"/>').val(content);
    return block = $('<div class="prompt-b"/>').append(p, c);
  },
  hist: function(prefix, content) {
    var block;
    block = Prompt.make(prefix, content);
    block.find('input').attr('readonly', 'readonly');
    return $('#container').append(block);
  },
  submit: function() {
    var cmd, out;
    if (!Prompt.active.find(".prompt-c").is(":focus")) {
      Prompt.active.find(".prompt-c").focus();
      return;
    }
    cmd = Prompt.active.find(".prompt-c").val();
    if (cmd === "") {
      return;
    }
    Prompt.active.hide();
    Prompt.ndots = 0;
    Prompt.dots.show();
    Prompt.history.push(cmd);
    Prompt.history_pos = Prompt.history.length;
    Prompt.hist(Prompt.count + ">", cmd);
    return out = Controller.get(cmd, Prompt.success, Prompt.error);
  },
  success: function(out) {
    var block, line1, line2, segments;
    segments = out.split('%%%');
    segments[0].replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    segments[1].replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    block = $('<div class="output texrender"/>').text("$" + segments[0] + "$");
    line1 = $('<div class="output texcode"/>').text(segments[0]);
    line2 = $('<div class="output mathcode"/>').text(segments[1]);
    if (!Prompt.toggles[0]) {
      block.addClass("hide");
    }
    if (!Prompt.toggles[1]) {
      line1.addClass("hide");
    }
    if (!Prompt.toggles[2]) {
      line2.addClass("hide");
    }
    Prompt.results.push(segments[1]);
    $('#container').append(block, line1, line2);
    MathJax.Hub.Queue(["Typeset", MathJax.Hub, block[0]]);
    return Prompt.next(true);
  },
  next: function(success) {
    if (success) {
      Prompt.count += 1;
    }
    Prompt.active.show();
    Prompt.dots.hide();
    Prompt.active.find(".prompt-p").text(Prompt.count + ">");
    Prompt.active.find(".prompt-c").val("").focus();
    return $('html, body').scrollTop($(document).height());
  },
  error: function(out) {
    var errline;
    errline = $('<div class="output error"/>').text("Connection error");
    $('#container').append(errline);
    return Prompt.next();
  },
  up: function() {
    if (Prompt.history_pos > 0) {
      --Prompt.history_pos;
      Prompt.active.find(".prompt-c").val(Prompt.history[Prompt.history_pos]);
    }
    return false;
  },
  down: function() {
    if (Prompt.history_pos < Prompt.history.length) {
      ++Prompt.history_pos;
      if (Prompt.history_pos === Prompt.history.length) {
        Prompt.active.find(".prompt-c").val("");
      } else {
        Prompt.active.find(".prompt-c").val(Prompt.history[Prompt.history_pos]);
      }
    }
    return false;
  },
  ndots: 0,
  tick: function() {
    Prompt.ndots = (Prompt.ndots + 1) % 5;
    return Prompt.dots.text(Array(Prompt.ndots + 2).join("."));
  }
};

$(function() {
  Prompt.active = $("#prompt").append(Prompt.make("", ""));
  Prompt.active.find(".prompt-p").text(Prompt.count + ">");
  Prompt.dots = $("#dots");
  setInterval(Prompt.tick, 100);
  $("#wa").click(function() {
    return location.reload();
  });
  $("#toggl1").click(function(e) {
    $("#toggl1").toggleClass("down");
    Prompt.toggles[0] = !Prompt.toggles[0];
    return $(".texrender").toggleClass("hide");
  });
  $("#toggl2").click(function(e) {
    $("#toggl2").toggleClass("down");
    Prompt.toggles[1] = !Prompt.toggles[1];
    return $(".texcode").toggleClass("hide");
  });
  $("#toggl3").click(function(e) {
    $("#toggl3").toggleClass("down");
    Prompt.toggles[2] = !Prompt.toggles[2];
    return $(".mathcode").toggleClass("hide");
  });
  $(window).keydown(function(e) {
    switch (e.which) {
      case 13:
        return Prompt.submit();
      case 38:
        return Prompt.up();
      case 40:
        return Prompt.down();
      case 17:
      case 91:
        return false;
    }
  }).click(function(e) {
    if (e.target.id === "parent-target") {
      return Prompt.active.find(".prompt-c").focus();
    }
  });
  return Prompt.active.find(".prompt-c").focus();
});
