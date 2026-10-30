;; extends

; Alpine.js / Livewire: x-data="{ open: false }", @click="open = !open", :class="{ ... }", wire:click="save(1)"
(attribute
  (attribute_name) @_name
  (#lua-match? @_name "^x%-")
  (quoted_attribute_value
    (attribute_value) @injection.content)
  (#set! injection.language "javascript"))

(attribute
  (attribute_name) @_name
  (#lua-match? @_name "^wire:")
  (quoted_attribute_value
    (attribute_value) @injection.content)
  (#set! injection.language "javascript"))

(attribute
  (attribute_name) @_name
  (#lua-match? @_name "^[@:]")
  (quoted_attribute_value
    (attribute_value) @injection.content)
  (#set! injection.language "javascript"))
