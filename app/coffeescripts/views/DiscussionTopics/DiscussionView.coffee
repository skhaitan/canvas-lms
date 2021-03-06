define [
  'i18n!discussions'
  'underscore'
  'Backbone'
  'jst/DiscussionTopics/discussion'
], (I18n, _, {View}, template) ->

  class DiscussionView extends View
    # Public: View template (discussion).
    template: template

    # Public: Wrap everything in an <li />.
    tagName: 'li'

    # Public: <li /> class name(s).
    className: 'discussion'

    # Public: I18n translations.
    messages:
      confirm: I18n.t('confirm_delete_discussion_topic', 'Are you sure you want to delete this discussion topic?')
      delete:  I18n.t('delete', 'Delete')
      lock:    I18n.t('lock', 'Lock')
      unlock:  I18n.t('unlock', 'Unlock')
      pin:     I18n.t('pin', 'Pin')
      unpin:   I18n.t('unpin', 'Unpin')

    events:
      'click .icon-lock':  'toggleLocked'
      'click .icon-pin':   'togglePinned'
      'click .icon-trash': 'onDelete'
      'click':             'onClick'

    # Public: Option defaults.
    defaults:
      pinnable: false

    # Public: Topic is able to be locked/unlocked.
    @optionProperty 'lockable'

    # Public: Topic is able to be pinned/unpinned.
    @optionProperty 'pinnable'

    initialize: (options) ->
      @attachModel()
      super

    render: ->
      super
      @$el.attr('data-id', @model.get('id'))
      this

    # Public: Lock or unlock the model and update it on the server.
    #
    # e - Event object.
    #
    # Returns nothing.
    toggleLocked: (e) =>
      e.preventDefault()
      key    = if @model.get('locked') then 'lock' else 'unlock'
      locked = !@model.get('locked')
      pinned = if locked then false else @model.get('pinned')
      @model.save(locked: locked, pinned: pinned)
      $(e.target).text(@messages[key])

    # Public: Pin or unpin the model and update it on the server.
    #
    # e - Event object.
    #
    # Returns nothing.
    togglePinned: (e) =>
      e.preventDefault()
      key = if @model.get('pinned') then 'pin' else 'unpin'
      pinned = !@model.get('pinned')
      locked = if pinned then false else @model.get('locked')
      @model.save(locked: locked, pinned: pinned)
      $(e.target).text(@messages[key])

    # Public: Confirm a request to delete and then complete it if needed.
    #
    # e - Event object.
    #
    # Returns nothing.
    onDelete: (e) =>
      e.preventDefault()
      @delete() if confirm(@messages.confirm)

    # Public: Delete the model and update the server.
    #
    # Returns nothing.
    delete: ->
      @model.destroy()
      @$el.remove()

    # Public: Pin or unpin the model and update it on the server.
    #
    # e - Event object.
    #
    # Returns nothing.
    togglePinned: (e) =>
      e.preventDefault()
      key = if @model.get('pinned') then 'pin' else 'unpin'
      @model.updateOneAttribute('pinned', !@model.get('pinned'))
      $(e.target).text(@messages[key])

    # Public: Treat the whole <li /> as a link.
    #
    # e - Event handler.
    #
    # Returns nothing.
    onClick: (e) ->
      # Workaround a behavior of FF 15+ where it fires a click
      # after dropping a sortable item.
      return if @model.get('preventClick')
      return if _.contains(['A', 'I'], e.target.nodeName)
      window.location = @model.get('html_url')

    # Public: Toggle the view model's "hidden" attribute.
    #
    # Returns nothing.
    hide: =>
      @$el.toggle(!@model.get('hidden'))

    # Public: Generate JSON to pass to the view.
    #
    # Returns an object.
    toJSON: ->
      base = _.extend(@model.toJSON(), @options)
      # handle a student locking their own discussion (they should lose permissions).
      if @model.get('locked') and !_.intersection(ENV.current_user_roles, ['teacher', 'ta', 'admin']).length
        base.permissions.delete = false
      base

    # Internal: Add event handlers to the model.
    #
    # Returns nothing.
    attachModel: ->
      @model.on('change:hidden', @hide)
