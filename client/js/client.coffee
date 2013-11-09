Controller = {
    url: 'http://172.26.11.226:8000/'
    get: (msg, callback) ->
        $.post( Controller.url, {data: translate(msg)}, callback )
}

Prompt = {
    count: 1
    active: null
    history: []
    results: []
    history_pos: 0
    toggles: [true, false, false]
    make: (prefix, content) ->
        p = $('<div class="prompt-p"/>').text(prefix)
        c = $('<input type="text" class="prompt-c"/>').val(content)
        return block = $('<div class="prompt-b"/>').append(p, c)
    hist: (prefix, content) ->
        block = Prompt.make(prefix, content)
        block.find('input').attr('readonly', 'readonly')
        $('#container').append(block)
    submit: ->
        unless Prompt.active.find(".prompt-c").is(":focus")
            Prompt.active.find(".prompt-c").focus()
            return
        cmd = Prompt.active.find(".prompt-c").val()
        if cmd == "" then return
        Prompt.active.hide()
        Prompt.history.push(cmd)
        Prompt.history_pos = Prompt.history.length
        Prompt.hist(Prompt.count + ">", cmd)
        out = Controller.get(cmd, Prompt.next)
    next: (out) ->
        segments = out.split('%%%')
        segments[0].replace(/^\s\s*/, '').replace(/\s\s*$/, '');
        segments[1].replace(/^\s\s*/, '').replace(/\s\s*$/, '');
        block = $('<div class="output texrender"/>').text("$" + segments[0] + "$")
        line1 = $('<div class="output texcode"/>').text(segments[0])
        line2 = $('<div class="output mathcode"/>').text(segments[1])

        block.addClass("hide") unless Prompt.toggles[0]
        line1.addClass("hide") unless Prompt.toggles[1]
        line2.addClass("hide") unless Prompt.toggles[2]

        Prompt.results.push(segments[1])

        $('#container').append(block, line1, line2)
        update()
        Prompt.count += 1
        Prompt.active.show()
        Prompt.active.find(".prompt-p").text(Prompt.count + ">")
        Prompt.active.find(".prompt-c").val("").focus()
        $('html, body').scrollTop($(document).height())
    up: ->
        if Prompt.history_pos > 0
            --Prompt.history_pos
            Prompt.active.find(".prompt-c").val(Prompt.history[Prompt.history_pos])
        false
    down: ->
        if Prompt.history_pos < Prompt.history.length
            ++Prompt.history_pos
            if Prompt.history_pos == Prompt.history.length
                Prompt.active.find(".prompt-c").val("")
            else
                Prompt.active.find(".prompt-c").val(Prompt.history[Prompt.history_pos])
        false
}

$ ->
    Prompt.active = $("#prompt").append( Prompt.make("", "") )
    Prompt.active.find(".prompt-p").text(Prompt.count + ">")

    $("#toggl1").click( (e) ->
        $(e.target).toggleClass("down")
        Prompt.toggles[0] = not Prompt.toggles[0]
        $(".texrender").toggleClass("hide") )
    $("#toggl2").click( (e) ->
        $(e.target).toggleClass("down")
        Prompt.toggles[1] = not Prompt.toggles[1]
        $(".texcode").toggleClass("hide") )
    $("#toggl3").click( (e) ->
        $(e.target).toggleClass("down")
        Prompt.toggles[2] = not Prompt.toggles[2]
        $(".mathcode").toggleClass("hide") )
    $(window).keydown((e) ->
        switch e.which
            when 13 then Prompt.submit()
            when 38 then Prompt.up()
            when 40 then Prompt.down()
            when 17, 91 then false
            else Prompt.active.find(".prompt-c").focus()
    ).click( (e) -> Prompt.active.find(".prompt-c").focus() if e.target == this )
    Prompt.active.find(".prompt-c").focus()