'use strict'
window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}
;(function (Modules) {
    function GovspeakEditor(module) {
        this.module = module
    }

    GovspeakEditor.prototype.init = function () {
        this.previewButton = document.querySelector(
            '.js-app-c-govspeak-editor__preview-button'
        )
        this.previewButton.classList.add(
            'app-c-govspeak-editor__preview-button--show'
        )
        this.previewButton.addEventListener('click', this.showPreview.bind(this))

        this.preview = document.querySelector('.app-c-govspeak-editor__preview')

        this.textarea = document.getElementsByName("edition[body]")[0]
    }

    GovspeakEditor.prototype.getCsrfToken = function () {
        return document.querySelector('meta[name="csrf-token"]').content
    }

    GovspeakEditor.prototype.getRenderedGovspeak = function (body, callback) {
        const data = this.generateFormData(body)

        const request = new XMLHttpRequest()
        request.open('POST', '/government/admin/preview', false)
        request.setRequestHeader('X-CSRF-Token', this.getCsrfToken())
        request.onreadystatechange = callback
        request.send(data)
    }

    GovspeakEditor.prototype.generateFormData = function (body) {
        const data = new FormData()
        data.append('body', body)
        data.append('authenticity_token', this.getCsrfToken())
        if (this.alternativeFormatProviderId()) {
            data.append(
                'alternative_format_provider_id',
                this.alternativeFormatProviderId()
            )
        }

        const imageIds = this.getImageIds()
        for (let index = 0; index < imageIds.length; index++) {
            data.append('image_ids[]', imageIds[index])
        }

        const attachmentIds = this.getAttachmentIds()
        for (let i = 0; i < attachmentIds.length; i++) {
            data.append('attachment_ids[]', attachmentIds[i])
        }

        return data
    }

    GovspeakEditor.prototype.showPreview = function (event) {
        event.preventDefault()

        this.previewButton.classList.remove(
            'app-c-govspeak-editor__preview-button--show'
        )

        this.preview.classList.add('app-c-govspeak-editor__preview--show')


        this.getRenderedGovspeak(this.textarea.value, (event) => {
            const response = event.currentTarget

            if (response.readyState !== 4) {
                return
            }

            switch (response.status) {
                case 200:
                    this.preview.innerHTML = response.responseText
                    break
                case 403:
                    this.preview.classList.remove('app-c-govspeak-editor__preview--show')
                    this.error.classList.add('app-c-govspeak-editor__error--show')
            }
        })
    }


    GovspeakEditor.prototype.getImageIds = function () {
        let imagesIds = this.module.getAttribute('data-image-ids')
        imagesIds = imagesIds ? JSON.parse(imagesIds) : []

        return imagesIds.filter(function (id) {
            return id
        })
    }

    GovspeakEditor.prototype.getAttachmentIds = function () {
        let attachmentIds = this.module.getAttribute('data-attachment-ids')
        attachmentIds = attachmentIds ? JSON.parse(attachmentIds) : []

        return attachmentIds.filter(function (id) {
            return id
        })
    }

    GovspeakEditor.prototype.alternativeFormatProviderId = function () {
        return this.module.getAttribute('data-alternative-format-provider-id')
    }

    Modules.GovspeakEditor = GovspeakEditor
})(window.GOVUK.Modules)
