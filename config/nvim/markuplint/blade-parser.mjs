// markuplint parser for Blade templates: HTML with Blade syntax masked out.
// Masking keeps every line and column in place, so reported positions match the source.
import { realpathSync } from "node:fs";
import { createRequire } from "node:module";

// @markuplint/html-parser ships inside the markuplint package (installed by Mason), not next to this file
const requireFromMarkuplint = createRequire(realpathSync(process.argv[1]));
const { HtmlParser } = await import(requireFromMarkuplint.resolve("@markuplint/html-parser"));

const blank = (text) => text.replace(/[^\n]/g, " ");

// "(...)" starting at index, skipping parentheses inside quoted strings; returns the index after ")" or -1
function balancedParensEnd(code, index) {
  let depth = 0;
  let quote = null;
  for (let i = index; i < code.length; i++) {
    const char = code[i];
    if (quote) {
      if (char === "\\") i++;
      else if (char === quote) quote = null;
    } else if (char === "'" || char === '"') quote = char;
    else if (char === "(") depth++;
    else if (char === ")" && --depth === 0) return i + 1;
  }
  return -1;
}

// <div {{ $attributes->merge([...]) }}>: an echo in place of attributes is no attribute, so it is blanked;
// echoes in attribute values and text stay and become ignoreTags blocks
function maskEchoesInAttributePosition(code) {
  const echo = /^(\{\{[\s\S]*?\}\}|\{!![\s\S]*?!!\})/;
  let result = "";
  let quote = null;
  let inTag = false;
  for (let i = 0; i < code.length; i++) {
    const match = (inTag || quote) && code[i] === "{" && code.slice(i).match(echo);
    if (match) {
      // quotes inside an echo (title="{{ __("x") }}") must not end the attribute value
      result += quote ? match[0] : blank(match[0]);
      i += match[0].length - 1;
      continue;
    }
    const char = code[i];
    if (quote) {
      if (char === quote) quote = null;
    } else if (inTag) {
      if (char === '"' || char === "'") quote = char;
      else if (char === ">") inTag = false;
    } else if (char === "<" && /[a-zA-Z]/.test(code[i + 1] ?? "")) inTag = true;
    result += char;
  }
  return result;
}

function maskBlade(code) {
  // raw PHP and verbatim blocks may contain anything, including "<"
  code = code.replace(/@(php|verbatim)\b(?!\s*\()[\s\S]*?@end\1\b/g, blank);
  // directives: @if(...), @csrf, @endforeach, @class([...]) inside a tag, ...
  // not @click="..." / @click.prevent (Alpine), not user@example.com, not @@escaped
  let masked = "";
  let last = 0;
  const directive = /(?<![\w@])@([a-zA-Z]\w*)(?![\w.:=-])/g;
  for (let match; (match = directive.exec(code)); ) {
    let end = match.index + match[0].length;
    const parenStart = code.slice(end).match(/^[ \t]*\(/);
    if (parenStart) {
      const parenEnd = balancedParensEnd(code, end + parenStart[0].length - 1);
      if (parenEnd !== -1) end = parenEnd;
    }
    masked += code.slice(last, match.index) + blank(code.slice(match.index, end));
    last = directive.lastIndex = end;
  }
  masked += code.slice(last);
  masked = maskEchoesInAttributePosition(masked);
  // <livewire:name>, <x-slot:name>, <flux:button> are not valid HTML tag names; same-length rename keeps positions
  return masked.replace(/(<\/?(?:livewire|flux|x-[\w.-]*)):/g, "$1-");
}

class BladeParser extends HtmlParser {
  constructor() {
    super({
      ignoreTags: [
        { type: "blade-comment", start: "{{--", end: "--}}" },
        { type: "blade-raw", start: "{!!", end: "!!}" },
        { type: "blade-echo", start: "{{", end: "}}" },
      ],
    });
  }

  parse(rawCode, options) {
    return super.parse(maskBlade(rawCode), options);
  }
}

export const parser = new BladeParser();
