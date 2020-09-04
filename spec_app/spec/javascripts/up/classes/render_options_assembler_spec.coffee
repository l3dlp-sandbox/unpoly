describe 'up.RenderOptionsAssembler', ->

  describe '#getSuccessOptions()', ->

    it 'sets global defaults', ->
      assembler = new up.RenderOptionsAssembler({})
      assembled = assembler.getSuccessOptions()
      expect(assembled.hungry).toBe(true)
      expect(assembled.keep).toBe(true)
      expect(assembled.source).toBe(true)
      expect(assembled.fail).toBe('auto')

    describe 'with { navigate: true }', ->

      it 'sets defaults appropriate for user navigation', ->
        assembler = new up.RenderOptionsAssembler({ navigate: true })
        assembled = assembler.getSuccessOptions()
        expect(assembled.solo).toBe(true)
        expect(assembled.feedback).toBe(true)
        expect(assembled.fallback).toBe(true)
        expect(assembled.peel).toBe(true)
        expect(assembled.reveal).toBe(true)
        expect(assembled.transition).toBe('navigate')

      it 'does not set { history }, since history should be governed by layer config and given options', ->
        assembler = new up.RenderOptionsAssembler({ navigate: true })
        assembled = assembler.getSuccessOptions()
        expect(assembled.history).toBeUndefined()

    describe 'with { navigate: false }', ->

      it 'sets additional defaults appropriate to programmatic fragment changes', ->
        assembler = new up.RenderOptionsAssembler({ navigate: false })
        assembled = assembler.getSuccessOptions()
        expect(assembled.title).toBe(false)
        expect(assembled.location).toBe(false)

    it 'overrides defaults with given options', ->
      givenOptions = { navigate: false, hungry: false, source: '/other-source' }
      assembler = new up.RenderOptionsAssembler(givenOptions)
      assembled = assembler.getSuccessOptions()
      expect(assembled.hungry).toBe(false)
      expect(assembled.source).toBe('/other-source')

    describe 'with { history }', ->

      it 'copies { history } to { title } and { location }', ->
        givenOptions = { history: true }
        assembler = new up.RenderOptionsAssembler(givenOptions)
        assembled = assembler.getSuccessOptions()
        expect(assembled.title).toBe(true)
        expect(assembled.location).toBe(true)

      it 'does not override a given { location } option', ->
        givenOptions = { history: true, location: '/given-location' }
        assembler = new up.RenderOptionsAssembler(givenOptions)
        assembled = assembler.getSuccessOptions()
        expect(assembled.title).toBe(true)
        expect(assembled.location).toBe('/given-location')

  describe '#getFailOptions()', ->

    it 'has global defaults', ->
      assembler = new up.RenderOptionsAssembler({})
      assembled = assembler.getFailOptions()
      expect(assembled.hungry).toBe(true)
      expect(assembled.keep).toBe(true)
      expect(assembled.source).toBe(true)
      expect(assembled.fail).toBe('auto')

    describe 'with { navigate: true }', ->

      it 'sets defaults appropriate for user navigation', ->
        assembler = new up.RenderOptionsAssembler({ navigate: true })
        assembled = assembler.getFailOptions()
        expect(assembled.solo).toBe(true)
        expect(assembled.feedback).toBe(true)
        expect(assembled.fallback).toBe(true)
        expect(assembled.peel).toBe(true)
        expect(assembled.reveal).toBe(true)
        expect(assembled.transition).toBe('navigate')

    describe 'with { navigate: false }', ->

      it 'sets additional defaults appropriate to programmatic fragment changes', ->
        assembler = new up.RenderOptionsAssembler({ navigate: false })
        assembled = assembler.getFailOptions()
        expect(assembled.title).toBe(false)
        expect(assembled.location).toBe(false)

    it 'inherits shared keys from success options', ->
      assembler = new up.RenderOptionsAssembler({ confirm: 'Really?', origin: document.body })
      assembled = assembler.getFailOptions()
      expect(assembled.confirm).toBe('Really?')
      expect(assembled.origin).toBe(document.body)

    it 'does not inherit non-shared keys from success options', ->
      assembler = new up.RenderOptionsAssembler({ mode: 'popup', reveal: '.reveal' })
      assembled = assembler.getFailOptions()
      expect(assembled.layer).toBeUndefined()
      expect(assembled.reveal).toBeUndefined()

    it 'does not inherit a { location } option', ->
      assembler = new up.RenderOptionsAssembler({ location: '/location' })
      assembled = assembler.getFailOptions()
      expect(assembled.location).not.toBe('/location')

    it 'overrides defaults with given fail-prefixed options', ->
      givenOptions = { failTarget: '.fail', failSource: '/fail-source', failMode: 'popup' }
      assembler = new up.RenderOptionsAssembler(givenOptions)
      assembled = assembler.getFailOptions()
      expect(assembled.target).toBe('.fail')
      expect(assembled.mode).toBe('popup')
      expect(assembled.source).toBe('/fail-source')

    describe 'with { history }', ->

      it 'copies { history } to { title } and { location }', ->
        givenOptions = { history: true }
        assembler = new up.RenderOptionsAssembler(givenOptions)
        assembled = assembler.getFailOptions()
        expect(assembled.title).toBe(true)
        expect(assembled.location).toBe(true)

      it 'may be overruled with { failHistory }', ->
        givenOptions = { history: true, failHistory: false }
        assembler = new up.RenderOptionsAssembler(givenOptions)
        assembled = assembler.getFailOptions()
        expect(assembled.title).toBe(false)
        expect(assembled.location).toBe(false)

      it 'does not override a given { failLocation } option', ->
        givenOptions = { history: true, failLocation: '/given-location' }
        assembler = new up.RenderOptionsAssembler(givenOptions)
        assembled = assembler.getFailOptions()
        expect(assembled.title).toBe(true)
        expect(assembled.location).toBe('/given-location')
