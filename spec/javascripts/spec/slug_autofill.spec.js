/* global GOVUK */

describe('A slug autofill module', function () {
  'use strict'

  let slugAutofill, container, changeEvent, titleElement, slugElement

  const moduleHtml = `
    <div>
      <input id="example-title-id" type="text" />
      <input id="example-slug-id" type="text" />
    </div>
  `
  const titleInputId = 'example-title-id'
  const slugInputId = 'example-slug-id'

  beforeEach(function () {
    container = document.createElement('div')
    container.innerHTML = moduleHtml
    container.setAttribute('data-title-input-id', titleInputId)
    container.setAttribute('data-slug-input-id', slugInputId)
    document.body.appendChild(container)

    slugAutofill = new GOVUK.Modules.SlugAutofill(container)
    slugAutofill.init(container)

    changeEvent = new Event('change')

    titleElement = document.getElementById(titleInputId)
    slugElement = document.getElementById(slugInputId)
  })

  afterEach(function () {
    container.remove()
  })

  describe('when generating the slug from the title', function () {
    it('lower-cases all letters', function () {
      titleElement.value = 'CAPITALS'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('capitals')
    })

    it('removes non-alphanumeric characters', function () {
      titleElement.value = 'é/"!@£$%^&*()[]{};:,.<>?\\|`~=+'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('')
    })

    it('removes leading and trailing spaces', function () {
      titleElement.value = ' title '
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('title')
    })

    it('preserves hyphens', function () {
      titleElement.value = 'with-hyphen'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('with-hyphen')
    })

    it('replaces underscores with hyphens', function () {
      titleElement.value = 'a_title_with_underscores'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('a-title-with-underscores')
    })

    it('replaces spaces with hyphens', function () {
      titleElement.value = 'with some spaces'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('with-some-spaces')
    })

    it('replaces consecutive spaces and underscores with a single hyphen', function () {
      titleElement.value = 'a _ b'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('a-b')
    })
  })

  describe('when the slug field explicitly accepts generated values', () => {
    beforeEach(() => {
      slugElement.dataset.acceptsGeneratedValue = 'true'
    })

    it('replaces an empty slug', function () {
      titleElement.value = 'wibble'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('wibble')
    })

    it('replaces a non-empty slug', function () {
      slugElement.value = 'original-slug'

      titleElement.value = 'second'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('second')
    })
  })

  describe('when the slug field does not accept generated values', () => {
    it('replaces an empty slug', function () {
      titleElement.value = 'wibble'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('wibble')
    })

    it('continues updating a slug if it began as empty', function () {
      titleElement.value = 'first'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('first')

      titleElement.value = 'second'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('second')
    })

    it('does not replace a non-empty slug', function () {
      slugElement.value = 'original-slug'

      titleElement.value = 'second'
      titleElement.dispatchEvent(changeEvent)

      expect(slugElement.value).toBe('original-slug')
    })
  })
})
