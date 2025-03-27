/* globals GovUKGuideUtils */

(function (Modules) {
    function ContentBlockModal(module) {
        console.log("here in function")
        this.module = module
    }

    ContentBlockModal.prototype.start = function() {
        console.log("here in start")
        // const modalButton = document.getElementById('modal-button-open')
        // modalButton.addEventListener('click', this.openModal.bind(this))
    }

    ContentBlockModal.prototype.openModal = function(e) {
        e.preventDefault()
        this.$modal = $('content-block-modal')
        console.log(this.$modal)
        this.$modal.open()
    }


    Modules.ContentBlockModal = ContentBlockModal
})(window.GOVUKAdmin.Modules)
