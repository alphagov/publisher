/* globals GovUKGuideUtils */

(function (Modules) {
    function ModalDialogue (module) {

    }

    ModalDialogue.prototype.start = function (module) {
        this.$module = module
        console.log("module")
        console.log(module)
        this.$dialogBox = $('.gem-c-modal-dialogue__box')
        console.log(this.$dialogBox)
        this.$closeButton = $('.gem-c-modal-dialogue__close-button')
        this.$html = document.querySelector('html')
        this.$body = document.querySelector('body')

        if (!this.$dialogBox || !this.$closeButton) return

        this.$module.resize = this.handleResize.bind(this)
        this.$module.open = this.handleOpen.bind(this)
        this.$module.close = this.handleClose.bind(this)
        this.$module.focusDialog = this.handleFocusDialog.bind(this)
        this.$module.boundKeyDown = this.handleKeyDown.bind(this)

        this.$triggerElement = $(
            '[data-toggle="modal"][data-target="content-block-modal"]'
        )
        console.log(this.$module.id)
        console.log(this.$triggerElement)

        if (this.$triggerElement) {
            this.$triggerElement.on('click', this.$module.open)
        }

        if (this.$closeButton) {
            this.$closeButton.on('click', this.$module.close)
        }
    }

    ModalDialogue.prototype.handleResize = function (size) {
        if (size === 'narrow') {
            this.$dialogBox.classList.remove('gem-c-modal-dialogue__box--wide')
        }

        if (size === 'wide') {
            this.$dialogBox.classList.add('gem-c-modal-dialogue__box--wide')
        }
    }

    ModalDialogue.prototype.handleOpen = function (event) {
        console.log("here")
        console.log(this.$module)
        if (event) {
            event.preventDefault()
        }

        this.$html.classList.add('gem-o-template--modal')
        this.$body.classList.add('gem-o-template__body--modal')
        this.$body.classList.add('gem-o-template__body--blur')
        this.$focusedElementBeforeOpen = document.activeElement
        this.$module.css('display','block')
        this.$dialogBox.focus()

        document.addEventListener('keydown', this.$module.boundKeyDown, true)
    }

    ModalDialogue.prototype.handleClose = function (event) {
        if (event) {
            event.preventDefault()
        }

        this.$html.classList.remove('gem-o-template--modal')
        this.$body.classList.remove('gem-o-template__body--modal')
        this.$body.classList.remove('gem-o-template__body--blur')
        this.$module.css('display','none')
        this.$focusedElementBeforeOpen.focus()

        document.removeEventListener('keydown', this.$module.boundKeyDown, true)
    }

    ModalDialogue.prototype.handleFocusDialog = function () {
        this.$dialogBox.focus()
    }

    // while open, prevent tabbing to outside the dialogue
    // and listen for ESC key to close the dialogue
    ModalDialogue.prototype.handleKeyDown = function (event) {
        var KEY_TAB = 9
        var KEY_ESC = 27

        switch (event.keyCode) {
            case KEY_TAB:
                if (event.shiftKey) {
                    if (document.activeElement === this.$dialogBox) {
                        event.preventDefault()
                        this.$closeButton.focus()
                    }
                } else {
                    if (document.activeElement === this.$closeButton) {
                        event.preventDefault()
                        this.$dialogBox.focus()
                    }
                }

                break
            case KEY_ESC:
                this.$module.close()
                break
            default:
                break
        }
    }

    Modules.ModalDialogue = ModalDialogue
})(window.GOVUKAdmin.Modules)