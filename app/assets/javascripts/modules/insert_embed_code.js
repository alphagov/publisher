'use strict'
window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
    function InsertEmbedCode($module) {
        this.module = $module
        console.log("here in insert code")
        console.log($module)
        this.$insertButton = this.createLink.bind(this)()
        console.log(this.$insertButton)
    }

    InsertEmbedCode.prototype.init = function () {
        const dd = document.createElement('dd')
        dd.classList.add('govuk-summary-list__actions')
        dd.append(this.$insertButton)

        this.module.append(dd)
        this.module.classList.remove('govuk-summary-list__row--no-actions')
    }

    InsertEmbedCode.prototype.createLink = function () {
        const $insertButton = document.createElement('a')
        $insertButton.classList.add('govuk-link')
        $insertButton.classList.add('govuk-link__copy-link')
        $insertButton.setAttribute('href', '#')
        $insertButton.setAttribute('role', 'button')
        $insertButton.textContent = 'Insert code'
        $insertButton.addEventListener('click', this.insertCode.bind(this))
        // Handle when a keyboard user highlights the link and clicks return
        $insertButton.addEventListener(
            'keydown',
            function (e) {
                if (e.keyCode === 13) {
                    this.insertCode.bind(this)
                }
            }.bind(this)
        )

        return $insertButton
    }
    
    InsertEmbedCode.prototype.insertCode = function (e) {
        e.preventDefault()
        const embedCode = this.module.dataset.embedCode
        const insertTarget = this.module.dataset.insertTarget
        const textArea = document.getElementsByName(insertTarget)[0]

        // Get the current cursor position
        const position = textArea.selectionStart;

        // Get the text before and after the cursor position
        const before = textArea.value.substring(0, position);
        const after = textArea.value.substring(position, textArea.value.length);

        // Insert the new text at the cursor position
        textArea.value = before + embedCode + after;

        // Set the cursor position to after the newly inserted text
        textArea.selectionStart = textArea.selectionEnd = position + embedCode.length;

        this.copySuccess()
    }

    InsertEmbedCode.prototype.copySuccess = function () {
        const originalText = this.$insertButton.textContent
        this.$insertButton.textContent = 'Code inserted'
        this.$insertButton.focus()

        setTimeout(this.restoreText.bind(this, originalText), 2000)
    }

    InsertEmbedCode.prototype.restoreText = function (originalText) {
        this.$insertButton.textContent = originalText
    }

    Modules.InsertEmbedCode = InsertEmbedCode
})(window.GOVUK.Modules)
