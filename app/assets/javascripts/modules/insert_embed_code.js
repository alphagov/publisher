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
        $insertButton.textContent = 'Copy code'
        $insertButton.addEventListener('click', this.copyCode.bind(this))
        // Handle when a keyboard user highlights the link and clicks return
        $insertButton.addEventListener(
            'keydown',
            function (e) {
                if (e.keyCode === 13) {
                    this.copyCode.bind(this)
                }
            }.bind(this)
        )

        return $insertButton
    }

    InsertEmbedCode.prototype.insertCode = function (e) {
        e.preventDefault()
        // const embedCode = this.module.dataset.embedCode
    }

    InsertEmbedCode.prototype.copyCode = function (e) {
        e.preventDefault()
        const embedCode = this.module.dataset.embedCode
        
        this.writeToClipboard(embedCode).then(this.copySuccess.bind(this))
    }

    InsertEmbedCode.prototype.copySuccess = function () {
        const originalText = this.$insertButton.textContent
        this.$insertButton.textContent = 'Code copied'
        this.$insertButton.focus()

        setTimeout(this.restoreText.bind(this, originalText), 2000)
    }

    InsertEmbedCode.prototype.restoreText = function (originalText) {
        this.$insertButton.textContent = originalText
    }

    // This is a fallback for browsers that do not support the async clipboard API
    InsertEmbedCode.prototype.writeToClipboard = function (embedCode) {
        return new Promise(function (resolve) {
            // Create a textarea element with the embed code
            const textArea = document.createElement('textarea')
            textArea.value = embedCode

            document.body.appendChild(textArea)

            // Select the text in the textarea
            textArea.select()

            // Copy the selected text
            document.execCommand('copy')

            // Remove our textarea
            document.body.removeChild(textArea)

            resolve()
        })
    }

    Modules.InsertEmbedCode = InsertEmbedCode
})(window.GOVUK.Modules)
