$(document).ready ->
    $('.button').button()
    $('#preview-question').click previewQuestion
    createOptionEntries($('#question-container'), ['watched-input'])

    # update the preview every time text changes
    $('.watched-input').change previewQuestion

    previewQuestion()

    window.codePreview = CodeMirror.fromTextArea $('#latex-preview')[0], {'indentWithTabs': true, 'mode': 'text/x-stex'}

wordWrap = (str, len=80) ->
    paragraphs = str.split(/\n/)

    lines = []
    for p in paragraphs
        words = p.split(' ')
        line = []
        linelength = 0
        
        # for each word, either it fits on the end of the current line
        # or it becomes the start of the next line
        for w in words
            if linelength + w.length + 1 < len
                line.push w
                linelength += w.length + 1
            else
                lines.push line.join(' ')
                line = [w]
                linelength = w.length
        # when we encounter the end of a paragraph, add a newline
        if line.length > 0
            lines.push line.join(' ')
        #lines.push '\n'
    return lines

            

createOptionEntries = (container, classes=[]) ->
    letters = ['A', 'B', 'C', 'D', 'E']
    for i in [0..4]
        s = "<div class='question-option'>" +
        "<span class='question-option-label'>(#{letters[i]})</span>" +
        "<span class='question-option-input-container'>" +
        "<input type='text' class='#{classes.join(' ')} option-#{i} question-option-input'/>" +
        "</span>" +
        "</div>"
        surround = $(s)
        container.append surround

previewQuestion = ->
    questiontitle = $('#question-title').val()
    questionbody = $('#question-body').val()
    options = []
    for opt in $('.question-option input')
        opt = $(opt)
        text = $.trim opt.val()
        options.push text if text.length > 0

    frameArgs =
        questiontitle: questiontitle
        questionbody: questionbody
        options: options

    frame = new beamerFrame(frameArgs)
    frametext = frame.getText()

    $('#latex-preview').val(frametext)
    if window.codePreview
        window.codePreview.setValue(frametext)
    
    # Set up the preview area for the question
    $('#math-preview .title').text(questiontitle)
    $('#math-preview .body').text(questionbody)
    container = $('#math-preview .questions')
    container.empty()
    letters = ['A', 'B', 'C', 'D', 'E']
    for i in [0...options.length]
        surround = $("<span class='question-option'>(#{letters[i]}) 
        <span class='option-text option-#{i}'/>#{options[i]}</span>")
        container.append surround
        
    
    MathJax.Hub.Queue(["Typeset", MathJax.Hub, $('#math-preview')[0]])
    
class beamerFrame
    _frameIn: '\\begin{frame}'
    _frameOut: '\\end{frame}'
    constructor: (options)->
            {@questiontitle} = options
            {@questionbody} = options
            {@options} = options
    # returns the latex code for the question
    getText: ->
        enumerationLetters = ['(A)', '(B)', '(C)', '(D)', '(E)', '(F)']

        ret = [@_frameIn]
        ret.push "\t\\frametitle{#{@questiontitle}}" if @questiontitle
        # Make sure the body text has tabs inserted
        if @questionbody
            ret.push ''
            lines = wordWrap(@questionbody)
            for l in lines
                ret.push '\t'+l
            ret.push ''
            ret.push '\t\\vspace{.2em}'

        if @options and @options.length > 0
            ret.push '\t\\begin{enumerate}'
            for i in [0...@options.length]
                o = @options[i]
                ret.push "\t\t\\item[#{enumerationLetters[i]}] #{o}"

            ret.push '\t\\end{enumerate}'
        ret.push @_frameOut

        return ret.join('\n')

        
